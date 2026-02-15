"""Order endpoints: create, list, update status, track."""
import uuid as uuid_mod
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
from typing import Optional

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, UserRole, Address
from app.models.vendor import Vendor
from app.models.product import Product, ProductVariant
from app.models.order import Order, OrderItem, OrderStatusHistory, OrderStatus, PaymentStatus
from app.models.promotion import Coupon
from app.schemas.order import (
    CreateOrderRequest, OrderResponse, UpdateOrderStatusRequest,
    OrderFilter, OrderItemResponse,
)
from app.schemas.base import ResponseBase, PaginatedResponse
from app.config import get_settings

router = APIRouter(prefix="/orders", tags=["Orders"])
settings = get_settings()


def _generate_order_number() -> str:
    """Generate a unique order number."""
    import time
    ts = int(time.time() * 1000) % 10_000_000
    rand = uuid_mod.uuid4().hex[:4].upper()
    return f"ORD-{ts}-{rand}"


@router.post("/", response_model=ResponseBase[OrderResponse], status_code=201)
async def create_order(
    data: CreateOrderRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new order (multi-vendor splitting handled by client sending per-vendor orders)."""
    # Validate vendor
    vendor_result = await db.execute(select(Vendor).where(Vendor.id == data.vendor_id))
    vendor = vendor_result.scalar_one_or_none()
    if not vendor or not vendor.is_active:
        raise HTTPException(status_code=400, detail="Vendor not available")

    # Validate delivery address
    addr_result = await db.execute(
        select(Address).where(
            Address.id == data.delivery_address_id,
            Address.user_id == current_user.id,
        )
    )
    address = addr_result.scalar_one_or_none()
    if not address:
        raise HTTPException(status_code=400, detail="Invalid delivery address")

    delivery_address_snapshot = {
        "label": address.label,
        "full_address": address.full_address,
        "city": address.city,
        "state": address.state,
        "postal_code": address.postal_code,
        "latitude": address.latitude,
        "longitude": address.longitude,
    }

    # Process items
    subtotal = 0.0
    order_items = []

    for cart_item in data.items:
        product_result = await db.execute(
            select(Product).where(
                Product.id == cart_item.product_id,
                Product.vendor_id == data.vendor_id,
            )
        )
        product = product_result.scalar_one_or_none()
        if not product:
            raise HTTPException(
                status_code=400, detail=f"Product {cart_item.product_id} not found"
            )

        if product.track_inventory and product.stock_quantity < cart_item.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient stock for {product.name}",
            )

        unit_price = product.price
        variant = None
        if cart_item.variant_id:
            variant_result = await db.execute(
                select(ProductVariant).where(ProductVariant.id == cart_item.variant_id)
            )
            variant = variant_result.scalar_one_or_none()
            if variant:
                unit_price = variant.price

        item_total = unit_price * cart_item.quantity
        subtotal += item_total

        # Get primary image
        primary_image = None
        if product.images:
            primary_image = next(
                (img.image_url for img in product.images if img.is_primary),
                product.images[0].image_url if product.images else None,
            )

        order_items.append(OrderItem(
            product_id=product.id,
            variant_id=cart_item.variant_id,
            product_name=product.name,
            product_image_url=primary_image,
            unit_price=unit_price,
            quantity=cart_item.quantity,
            total_price=item_total,
            unit_type=product.unit_type.value,
            unit_value=product.unit_value,
        ))

        # Reduce stock
        if product.track_inventory:
            product.stock_quantity -= cart_item.quantity
            if variant:
                variant.stock_quantity -= cart_item.quantity

    # Calculate delivery fee
    delivery_fee = 0.0
    if subtotal < settings.FREE_DELIVERY_THRESHOLD:
        delivery_fee = settings.DELIVERY_FEE

    # Apply coupon
    discount_amount = 0.0
    if data.coupon_code:
        coupon_result = await db.execute(
            select(Coupon).where(
                Coupon.code == data.coupon_code,
                Coupon.is_active == True,
            )
        )
        coupon = coupon_result.scalar_one_or_none()
        if coupon and coupon.start_date <= datetime.utcnow() <= coupon.end_date:
            if subtotal >= coupon.min_order_amount:
                if coupon.discount_type.value == "percentage":
                    discount_amount = subtotal * (coupon.discount_value / 100)
                    if coupon.max_discount_amount:
                        discount_amount = min(discount_amount, coupon.max_discount_amount)
                elif coupon.discount_type.value == "flat":
                    discount_amount = coupon.discount_value
                elif coupon.discount_type.value == "free_delivery":
                    delivery_fee = 0.0

                coupon.used_count += 1

    tax_amount = 0.0  # Can be calculated based on region
    total_amount = subtotal + delivery_fee + tax_amount - discount_amount

    # Commission
    commission_amount = total_amount * (vendor.commission_rate / 100)
    vendor_payout = total_amount - commission_amount

    # Create order
    payment_status = PaymentStatus.COD if data.payment_method == "cod" else PaymentStatus.PENDING

    order = Order(
        order_number=_generate_order_number(),
        customer_id=current_user.id,
        vendor_id=vendor.id,
        delivery_address=delivery_address_snapshot,
        subtotal=subtotal,
        delivery_fee=delivery_fee,
        discount_amount=discount_amount,
        tax_amount=tax_amount,
        total_amount=total_amount,
        commission_rate=vendor.commission_rate,
        commission_amount=commission_amount,
        vendor_payout_amount=vendor_payout,
        payment_method=data.payment_method,
        payment_status=payment_status,
        coupon_code=data.coupon_code,
        customer_note=data.customer_note,
    )
    db.add(order)
    await db.flush()

    # Add items
    for item in order_items:
        item.order_id = order.id
        db.add(item)

    # Status history
    history = OrderStatusHistory(
        order_id=order.id,
        status=OrderStatus.PENDING,
        note="Order placed",
        changed_by=current_user.id,
    )
    db.add(history)

    # Update vendor total orders
    vendor.total_orders += 1
    await db.flush()

    # Re-query to load relationships
    result = await db.execute(select(Order).where(Order.id == order.id))
    order = result.scalar_one()

    return ResponseBase(
        data=OrderResponse.model_validate(order),
        message="Order placed successfully",
    )


@router.get("/", response_model=PaginatedResponse[OrderResponse])
async def list_orders(
    status: Optional[OrderStatus] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List orders for current user (customer or vendor)."""
    query = select(Order)

    if current_user.role == UserRole.VENDOR:
        vendor_result = await db.execute(
            select(Vendor).where(Vendor.user_id == current_user.id)
        )
        vendor = vendor_result.scalar_one_or_none()
        if vendor:
            query = query.where(Order.vendor_id == vendor.id)
    elif current_user.role == UserRole.CUSTOMER:
        query = query.where(Order.customer_id == current_user.id)
    elif current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Access denied")

    if status:
        query = query.where(Order.status == status)

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = query.order_by(Order.created_at.desc()).offset(
        (page - 1) * page_size
    ).limit(page_size)

    result = await db.execute(query)
    orders = result.scalars().all()

    return PaginatedResponse(
        data=[OrderResponse.model_validate(o) for o in orders],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )


@router.get("/{order_id}", response_model=ResponseBase[OrderResponse])
async def get_order(
    order_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get order details."""
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # Permission check
    if current_user.role == UserRole.CUSTOMER and order.customer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")

    return ResponseBase(data=OrderResponse.model_validate(order))


@router.put("/{order_id}/status", response_model=ResponseBase[OrderResponse])
async def update_order_status(
    order_id: UUID,
    data: UpdateOrderStatusRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update order status (vendor/admin/delivery partner)."""
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    # Permission: vendor can update their own orders, admin can update any
    if current_user.role == UserRole.VENDOR:
        vendor_result = await db.execute(
            select(Vendor).where(Vendor.user_id == current_user.id)
        )
        vendor = vendor_result.scalar_one_or_none()
        if not vendor or order.vendor_id != vendor.id:
            raise HTTPException(status_code=403, detail="Access denied")

    order.status = data.status
    if data.status == OrderStatus.DELIVERED:
        order.actual_delivery_time = datetime.utcnow()
        order.payment_status = PaymentStatus.PAID

    # Status history
    history = OrderStatusHistory(
        order_id=order.id,
        status=data.status,
        note=data.note,
        changed_by=current_user.id,
    )
    db.add(history)
    await db.flush()

    return ResponseBase(data=OrderResponse.model_validate(order))


@router.post("/{order_id}/cancel", response_model=ResponseBase[OrderResponse])
async def cancel_order(
    order_id: UUID,
    reason: str = "",
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel an order (customer can cancel before shipped)."""
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    if order.customer_id != current_user.id and current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Access denied")

    cancellable = [OrderStatus.PENDING, OrderStatus.CONFIRMED]
    if order.status not in cancellable:
        raise HTTPException(
            status_code=400, detail="Order cannot be cancelled at this stage"
        )

    order.status = OrderStatus.CANCELLED
    order.cancellation_reason = reason

    # Restore stock
    for item in order.items:
        product_result = await db.execute(
            select(Product).where(Product.id == item.product_id)
        )
        product = product_result.scalar_one_or_none()
        if product and product.track_inventory:
            product.stock_quantity += item.quantity

    history = OrderStatusHistory(
        order_id=order.id,
        status=OrderStatus.CANCELLED,
        note=f"Cancelled: {reason}",
        changed_by=current_user.id,
    )
    db.add(history)
    await db.flush()

    return ResponseBase(data=OrderResponse.model_validate(order))


@router.post("/{order_id}/reorder", response_model=ResponseBase)
async def reorder(
    order_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get cart items to reorder from a previous order."""
    result = await db.execute(
        select(Order).where(
            Order.id == order_id, Order.customer_id == current_user.id
        )
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    reorder_items = []
    for item in order.items:
        reorder_items.append({
            "product_id": str(item.product_id),
            "variant_id": str(item.variant_id) if item.variant_id else None,
            "quantity": item.quantity,
            "product_name": item.product_name,
            "unit_price": item.unit_price,
        })

    return ResponseBase(
        data={"vendor_id": str(order.vendor_id), "items": reorder_items},
        message="Reorder items retrieved",
    )
