"""Comprehensive Admin panel endpoints."""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_, desc, asc
from sqlalchemy.orm import selectinload, joinedload
from uuid import UUID
from datetime import datetime, timedelta
from typing import Optional

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, UserRole
from app.models.vendor import Vendor, VendorStatus
from app.models.product import Product, ProductCategory, ProductStatus, ProductImage
from app.models.order import Order, OrderStatus, OrderStatusHistory, PaymentStatus
from app.models.payment import Payment, VendorPayout, PayoutStatus
from app.models.promotion import Coupon, DiscountType
from app.models.review import Review
from app.schemas.vendor import VendorResponse, VendorAdminUpdate
from app.schemas.base import ResponseBase, PaginatedResponse

router = APIRouter(prefix="/admin", tags=["Admin"])


def _require_admin(user: User):
    if user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")


# ═══════════════════════════════════════════════════════════════
# DASHBOARD & ANALYTICS
# ═══════════════════════════════════════════════════════════════

@router.get("/dashboard")
async def admin_dashboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    users_count = (await db.execute(select(func.count(User.id)))).scalar() or 0
    customers_count = (await db.execute(
        select(func.count(User.id)).where(User.role == UserRole.CUSTOMER))).scalar() or 0
    vendors_count = (await db.execute(select(func.count(Vendor.id)))).scalar() or 0
    pending_vendors = (await db.execute(
        select(func.count(Vendor.id)).where(Vendor.status == VendorStatus.PENDING))).scalar() or 0
    active_vendors = (await db.execute(
        select(func.count(Vendor.id)).where(Vendor.is_active == True))).scalar() or 0
    total_orders = (await db.execute(select(func.count(Order.id)))).scalar() or 0
    pending_orders = (await db.execute(
        select(func.count(Order.id)).where(Order.status == OrderStatus.PENDING))).scalar() or 0
    total_revenue = (await db.execute(
        select(func.sum(Order.total_amount)).where(Order.status == OrderStatus.DELIVERED))).scalar() or 0
    total_commission = (await db.execute(
        select(func.sum(Order.commission_amount)).where(Order.status == OrderStatus.DELIVERED))).scalar() or 0
    total_products = (await db.execute(select(func.count(Product.id)))).scalar() or 0
    low_stock_count = (await db.execute(
        select(func.count(Product.id)).where(
            Product.stock_quantity <= Product.low_stock_threshold,
            Product.status == ProductStatus.ACTIVE))).scalar() or 0
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    monthly_revenue = (await db.execute(
        select(func.sum(Order.total_amount)).where(
            Order.status == OrderStatus.DELIVERED, Order.created_at >= thirty_days_ago))).scalar() or 0
    monthly_orders = (await db.execute(
        select(func.count(Order.id)).where(Order.created_at >= thirty_days_ago))).scalar() or 0
    new_customers = (await db.execute(
        select(func.count(User.id)).where(
            User.role == UserRole.CUSTOMER, User.created_at >= thirty_days_ago))).scalar() or 0
    seven_days_ago = datetime.utcnow() - timedelta(days=7)
    weekly_revenue = (await db.execute(
        select(func.sum(Order.total_amount)).where(
            Order.status == OrderStatus.DELIVERED, Order.created_at >= seven_days_ago))).scalar() or 0
    weekly_orders = (await db.execute(
        select(func.count(Order.id)).where(Order.created_at >= seven_days_ago))).scalar() or 0
    return {"success": True, "data": {
        "total_users": users_count, "total_customers": customers_count,
        "total_vendors": vendors_count, "active_vendors": active_vendors,
        "pending_vendors": pending_vendors, "total_orders": total_orders,
        "pending_orders": pending_orders, "total_revenue": float(total_revenue),
        "total_commission": float(total_commission), "monthly_revenue": float(monthly_revenue),
        "monthly_orders": monthly_orders, "weekly_revenue": float(weekly_revenue),
        "weekly_orders": weekly_orders, "new_customers_30d": new_customers,
        "total_products": total_products, "low_stock_count": low_stock_count,
    }}


@router.get("/dashboard/revenue-chart")
async def revenue_chart(
    period: str = Query("daily", pattern="^(daily|weekly|monthly)$"),
    days: int = Query(30, ge=7, le=365),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    start_date = datetime.utcnow() - timedelta(days=days)
    trunc = {"daily": "day", "weekly": "week", "monthly": "month"}[period]
    date_trunc = func.date_trunc(trunc, Order.created_at)
    result = await db.execute(
        select(date_trunc.label("period"), func.sum(Order.total_amount).label("revenue"),
               func.sum(Order.commission_amount).label("commission"), func.count(Order.id).label("orders"))
        .where(Order.created_at >= start_date, Order.status == OrderStatus.DELIVERED)
        .group_by(date_trunc).order_by(date_trunc))
    return {"success": True, "data": [
        {"period": r.period.isoformat() if r.period else "", "revenue": float(r.revenue or 0),
         "commission": float(r.commission or 0), "orders": r.orders or 0} for r in result.all()]}


@router.get("/dashboard/recent-orders")
async def recent_orders(
    limit: int = Query(10, ge=1, le=50),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    result = await db.execute(
        select(Order)
        .options(joinedload(Order.customer), joinedload(Order.vendor), selectinload(Order.items))
        .order_by(Order.created_at.desc())
        .limit(limit)
    )
    orders = result.scalars().all()
    return {"success": True, "data": [
        {"id": str(o.id), "order_number": o.order_number, "customer_id": str(o.customer_id),
         "customer_name": o.customer.full_name if o.customer else "N/A",
         "vendor_id": str(o.vendor_id), "vendor_name": o.vendor.store_name if o.vendor else "N/A",
         "total_amount": o.total_amount, "status": o.status.value,
         "payment_status": o.payment_status.value, "payment_method": o.payment_method,
         "items_count": len(o.items), "created_at": o.created_at.isoformat()} for o in orders]}


@router.get("/dashboard/top-vendors")
async def top_vendors(
    limit: int = Query(5, ge=1, le=20),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    result = await db.execute(
        select(Vendor.id, Vendor.store_name, Vendor.rating, Vendor.total_orders,
               func.sum(Order.total_amount).label("total_revenue"))
        .join(Order, Order.vendor_id == Vendor.id).where(Order.status == OrderStatus.DELIVERED)
        .group_by(Vendor.id, Vendor.store_name, Vendor.rating, Vendor.total_orders)
        .order_by(desc("total_revenue")).limit(limit))
    return {"success": True, "data": [
        {"id": str(r.id), "store_name": r.store_name, "rating": r.rating,
         "total_orders": r.total_orders, "total_revenue": float(r.total_revenue or 0)} for r in result.all()]}


@router.get("/dashboard/top-products")
async def top_products(
    limit: int = Query(5, ge=1, le=20),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    result = await db.execute(
        select(Product.id, Product.name, Product.price, Product.total_sold,
               Product.avg_rating, Product.stock_quantity)
        .order_by(Product.total_sold.desc()).limit(limit))
    return {"success": True, "data": [
        {"id": str(r.id), "name": r.name, "price": r.price, "total_sold": r.total_sold,
         "avg_rating": r.avg_rating, "stock_quantity": r.stock_quantity} for r in result.all()]}


# ═══════════════════════════════════════════════════════════════
# VENDOR MANAGEMENT
# ═══════════════════════════════════════════════════════════════

@router.get("/vendors", response_model=PaginatedResponse[VendorResponse])
async def list_all_vendors(
    status: Optional[VendorStatus] = None, search: Optional[str] = None,
    page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    query = select(Vendor)
    if status: query = query.where(Vendor.status == status)
    if search: query = query.where(or_(Vendor.store_name.ilike(f"%{search}%"), Vendor.city.ilike(f"%{search}%")))
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0
    query = query.order_by(Vendor.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    vendors = result.scalars().all()
    return PaginatedResponse(data=[VendorResponse.model_validate(v) for v in vendors],
        total=total, page=page, page_size=page_size, total_pages=(total + page_size - 1) // page_size)


@router.get("/vendors/{vendor_id}")
async def get_vendor_detail(vendor_id: UUID, current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    result = await db.execute(
        select(Vendor)
        .options(joinedload(Vendor.user), selectinload(Vendor.documents))
        .where(Vendor.id == vendor_id)
    )
    vendor = result.scalar_one_or_none()
    if not vendor: raise HTTPException(status_code=404, detail="Vendor not found")
    vendor_revenue = (await db.execute(select(func.sum(Order.total_amount)).where(
        Order.vendor_id == vendor_id, Order.status == OrderStatus.DELIVERED))).scalar() or 0
    products_count = (await db.execute(select(func.count(Product.id)).where(
        Product.vendor_id == vendor_id))).scalar() or 0
    vendor_orders = (await db.execute(select(func.count(Order.id)).where(
        Order.vendor_id == vendor_id))).scalar() or 0
    return {"success": True, "data": {
        **VendorResponse.model_validate(vendor).model_dump(),
        "id": str(vendor.id), "user_id": str(vendor.user_id),
        "user_email": vendor.user.email if vendor.user else None,
        "user_phone": vendor.user.phone if vendor.user else None,
        "total_revenue": float(vendor_revenue),
        "products_count": products_count, "total_orders_count": vendor_orders,
        "documents": [{"id": str(d.id), "document_type": d.document_type,
            "document_url": d.document_url, "is_verified": d.is_verified} for d in vendor.documents],
    }}


@router.put("/vendors/{vendor_id}", response_model=ResponseBase[VendorResponse])
async def update_vendor_admin(vendor_id: UUID, data: VendorAdminUpdate,
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    result = await db.execute(select(Vendor).where(Vendor.id == vendor_id))
    vendor = result.scalar_one_or_none()
    if not vendor: raise HTTPException(status_code=404, detail="Vendor not found")
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items(): setattr(vendor, key, value)
    if data.status == VendorStatus.APPROVED: vendor.is_active = True
    elif data.status in (VendorStatus.REJECTED, VendorStatus.SUSPENDED): vendor.is_active = False
    await db.flush()
    return ResponseBase(data=VendorResponse.model_validate(vendor))


# ═══════════════════════════════════════════════════════════════
# ORDER MANAGEMENT
# ═══════════════════════════════════════════════════════════════

@router.get("/orders")
async def admin_list_orders(
    status: Optional[OrderStatus] = None, payment_status: Optional[PaymentStatus] = None,
    vendor_id: Optional[UUID] = None, search: Optional[str] = None,
    date_from: Optional[str] = None, date_to: Optional[str] = None,
    sort_by: str = Query("created_at", pattern="^(created_at|total_amount|order_number)$"),
    sort_order: str = Query("desc", pattern="^(asc|desc)$"),
    page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    query = select(Order).options(
        joinedload(Order.customer),
        joinedload(Order.vendor),
        selectinload(Order.items)
    )
    if status: query = query.where(Order.status == status)
    if payment_status: query = query.where(Order.payment_status == payment_status)
    if vendor_id: query = query.where(Order.vendor_id == vendor_id)
    if search: query = query.where(Order.order_number.ilike(f"%{search}%"))
    if date_from:
        try: query = query.where(Order.created_at >= datetime.fromisoformat(date_from))
        except ValueError: pass
    if date_to:
        try: query = query.where(Order.created_at <= datetime.fromisoformat(date_to))
        except ValueError: pass
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0
    sort_col = getattr(Order, sort_by)
    query = query.order_by(desc(sort_col) if sort_order == "desc" else asc(sort_col))
    query = query.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    orders = result.scalars().all()
    return {"success": True, "data": [
        {"id": str(o.id), "order_number": o.order_number,
         "customer_id": str(o.customer_id), "customer_name": o.customer.full_name if o.customer else "N/A",
         "vendor_id": str(o.vendor_id), "vendor_name": o.vendor.store_name if o.vendor else "N/A",
         "subtotal": o.subtotal, "delivery_fee": o.delivery_fee, "discount_amount": o.discount_amount,
         "total_amount": o.total_amount, "commission_amount": o.commission_amount,
         "status": o.status.value, "payment_status": o.payment_status.value,
         "payment_method": o.payment_method, "items_count": len(o.items),
         "items": [{"product_name": i.product_name, "unit_price": i.unit_price,
            "quantity": i.quantity, "total_price": i.total_price} for i in o.items],
         "created_at": o.created_at.isoformat()} for o in orders],
     "total": total, "page": page, "page_size": page_size,
     "total_pages": (total + page_size - 1) // page_size}


@router.get("/orders/{order_id}")
async def admin_get_order(order_id: UUID, current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    result = await db.execute(
        select(Order)
        .options(
            joinedload(Order.customer),
            joinedload(Order.vendor),
            selectinload(Order.items),
            selectinload(Order.status_history)
        )
        .where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order: raise HTTPException(status_code=404, detail="Order not found")
    return {"success": True, "data": {
        "id": str(order.id), "order_number": order.order_number,
        "customer_id": str(order.customer_id),
        "customer_name": order.customer.full_name if order.customer else "N/A",
        "customer_email": order.customer.email if order.customer else "N/A",
        "vendor_id": str(order.vendor_id),
        "vendor_name": order.vendor.store_name if order.vendor else "N/A",
        "delivery_address": order.delivery_address,
        "subtotal": order.subtotal, "delivery_fee": order.delivery_fee,
        "discount_amount": order.discount_amount, "tax_amount": order.tax_amount,
        "total_amount": order.total_amount, "commission_rate": order.commission_rate,
        "commission_amount": order.commission_amount,
        "vendor_payout_amount": order.vendor_payout_amount,
        "status": order.status.value, "payment_status": order.payment_status.value,
        "payment_method": order.payment_method, "coupon_code": order.coupon_code,
        "customer_note": order.customer_note, "cancellation_reason": order.cancellation_reason,
        "items": [{"id": str(i.id), "product_id": str(i.product_id), "product_name": i.product_name,
            "product_image_url": i.product_image_url, "unit_price": i.unit_price,
            "quantity": i.quantity, "total_price": i.total_price} for i in order.items],
        "status_history": [{"status": h.status.value, "note": h.note,
            "created_at": h.created_at.isoformat()} for h in sorted(order.status_history, key=lambda x: x.created_at)],
        "created_at": order.created_at.isoformat()}}


@router.put("/orders/{order_id}/status")
async def admin_update_order_status(order_id: UUID, status: OrderStatus, note: Optional[str] = None,
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order: raise HTTPException(status_code=404, detail="Order not found")
    order.status = status
    db.add(OrderStatusHistory(order_id=order_id, status=status,
        note=note or f"Status updated by admin", changed_by=current_user.id))
    await db.flush()
    return {"success": True, "message": f"Order status updated to {status.value}"}


# ═══════════════════════════════════════════════════════════════
# CUSTOMER MANAGEMENT
# ═══════════════════════════════════════════════════════════════

@router.get("/customers")
async def admin_list_customers(
    search: Optional[str] = None, is_active: Optional[bool] = None,
    sort_by: str = Query("created_at", pattern="^(created_at|full_name|email)$"),
    sort_order: str = Query("desc", pattern="^(asc|desc)$"),
    page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    query = select(User).where(User.role == UserRole.CUSTOMER)
    if search:
        query = query.where(or_(User.full_name.ilike(f"%{search}%"), User.email.ilike(f"%{search}%")))
    if is_active is not None: query = query.where(User.is_active == is_active)
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0
    sort_col = getattr(User, sort_by)
    query = query.order_by(desc(sort_col) if sort_order == "desc" else asc(sort_col))
    query = query.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    users = result.scalars().all()
    data = []
    for u in users:
        oc = (await db.execute(select(func.count(Order.id)).where(Order.customer_id == u.id))).scalar() or 0
        ts = (await db.execute(select(func.sum(Order.total_amount)).where(
            Order.customer_id == u.id, Order.status == OrderStatus.DELIVERED))).scalar() or 0
        data.append({"id": str(u.id), "email": u.email, "full_name": u.full_name, "phone": u.phone,
            "is_active": u.is_active, "is_verified": u.is_verified, "order_count": oc,
            "total_spent": float(ts), "created_at": u.created_at.isoformat()})
    return {"success": True, "data": data, "total": total, "page": page,
        "page_size": page_size, "total_pages": (total + page_size - 1) // page_size}


@router.put("/customers/{user_id}/toggle-active")
async def admin_toggle_customer(user_id: UUID, current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user: raise HTTPException(status_code=404, detail="User not found")
    user.is_active = not user.is_active
    await db.flush()
    return {"success": True, "data": {"id": str(user.id), "is_active": user.is_active}}


# ═══════════════════════════════════════════════════════════════
# PRODUCT MANAGEMENT
# ═══════════════════════════════════════════════════════════════

@router.get("/products")
async def admin_list_products(
    status: Optional[ProductStatus] = None, category_id: Optional[UUID] = None,
    vendor_id: Optional[UUID] = None, search: Optional[str] = None, low_stock: bool = False,
    sort_by: str = Query("created_at", pattern="^(created_at|price|total_sold|stock_quantity|name)$"),
    sort_order: str = Query("desc", pattern="^(asc|desc)$"),
    page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    query = select(Product).options(
        joinedload(Product.vendor),
        joinedload(Product.category),
        selectinload(Product.images)
    )
    if status: query = query.where(Product.status == status)
    if category_id: query = query.where(Product.category_id == category_id)
    if vendor_id: query = query.where(Product.vendor_id == vendor_id)
    if search: query = query.where(Product.name.ilike(f"%{search}%"))
    if low_stock: query = query.where(Product.stock_quantity <= Product.low_stock_threshold,
        Product.status == ProductStatus.ACTIVE)
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0
    sort_col = getattr(Product, sort_by)
    query = query.order_by(desc(sort_col) if sort_order == "desc" else asc(sort_col))
    query = query.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    products = result.scalars().all()
    return {"success": True, "data": [
        {"id": str(p.id), "name": p.name, "price": p.price, "compare_at_price": p.compare_at_price,
         "stock_quantity": p.stock_quantity, "low_stock_threshold": p.low_stock_threshold,
         "status": p.status.value, "total_sold": p.total_sold, "avg_rating": p.avg_rating,
         "vendor_name": p.vendor.store_name if p.vendor else "N/A", "vendor_id": str(p.vendor_id),
         "category_name": p.category.name if p.category else "N/A", "category_id": str(p.category_id),
         "image_url": p.images[0].image_url if p.images else None, "is_featured": p.is_featured,
         "created_at": p.created_at.isoformat()} for p in products],
     "total": total, "page": page, "page_size": page_size,
     "total_pages": (total + page_size - 1) // page_size}


@router.get("/categories")
async def admin_list_categories(current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    result = await db.execute(
        select(ProductCategory)
        .options(selectinload(ProductCategory.children))
        .where(ProductCategory.parent_id == None)
        .order_by(ProductCategory.sort_order)
    )
    categories = result.scalars().all()
    def to_dict(c):
        return {"id": str(c.id), "name": c.name, "slug": c.slug, "icon_url": c.icon_url,
            "image_url": c.image_url, "is_active": c.is_active, "sort_order": c.sort_order,
            "children": [to_dict(ch) for ch in c.children]}
    return {"success": True, "data": [to_dict(c) for c in categories]}


# ═══════════════════════════════════════════════════════════════
# PAYMENT & FINANCE
# ═══════════════════════════════════════════════════════════════

@router.get("/transactions")
async def admin_list_transactions(
    payment_method: Optional[str] = None, status: Optional[str] = None,
    page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    query = select(Payment).options(joinedload(Payment.order))
    if payment_method: query = query.where(Payment.payment_method == payment_method)
    if status: query = query.where(Payment.status == status)
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0
    query = query.order_by(Payment.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    payments = result.scalars().all()
    return {"success": True, "data": [
        {"id": str(p.id), "order_id": str(p.order_id),
         "order_number": p.order.order_number if p.order else "N/A",
         "amount": p.amount, "currency": p.currency,
         "payment_method": p.payment_method.value if hasattr(p.payment_method, 'value') else str(p.payment_method),
         "transaction_id": p.transaction_id, "status": p.status,
         "paid_at": p.paid_at.isoformat() if p.paid_at else None,
         "created_at": p.created_at.isoformat()} for p in payments],
     "total": total, "page": page, "page_size": page_size,
     "total_pages": (total + page_size - 1) // page_size}


@router.get("/payouts")
async def list_payouts(
    status: Optional[PayoutStatus] = None, vendor_id: Optional[UUID] = None,
    page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    query = select(VendorPayout).options(joinedload(VendorPayout.vendor))
    if status: query = query.where(VendorPayout.status == status)
    if vendor_id: query = query.where(VendorPayout.vendor_id == vendor_id)
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0
    query = query.order_by(VendorPayout.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    payouts = result.scalars().all()
    return {"success": True, "data": [
        {"id": str(p.id), "vendor_id": str(p.vendor_id),
         "vendor_name": p.vendor.store_name if p.vendor else "N/A",
         "amount": p.amount, "commission_deducted": p.commission_deducted,
         "net_amount": p.net_amount, "status": p.status.value,
         "payout_reference": p.payout_reference,
         "period_start": p.period_start.isoformat(), "period_end": p.period_end.isoformat(),
         "processed_at": p.processed_at.isoformat() if p.processed_at else None,
         "created_at": p.created_at.isoformat()} for p in payouts],
     "total": total, "page": page, "page_size": page_size,
     "total_pages": (total + page_size - 1) // page_size}


# ═══════════════════════════════════════════════════════════════
# COUPONS
# ═══════════════════════════════════════════════════════════════

@router.get("/coupons")
async def list_coupons(
    is_active: Optional[bool] = None, page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    query = select(Coupon)
    if is_active is not None: query = query.where(Coupon.is_active == is_active)
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0
    query = query.order_by(Coupon.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    coupons = result.scalars().all()
    return {"success": True, "data": [
        {"id": str(c.id), "code": c.code, "description": c.description,
         "discount_type": c.discount_type.value, "discount_value": c.discount_value,
         "min_order_amount": c.min_order_amount, "max_discount_amount": c.max_discount_amount,
         "max_uses": c.max_uses, "used_count": c.used_count, "is_active": c.is_active,
         "start_date": c.start_date.isoformat(), "end_date": c.end_date.isoformat(),
         "created_at": c.created_at.isoformat()} for c in coupons],
     "total": total, "page": page, "page_size": page_size,
     "total_pages": (total + page_size - 1) // page_size}


@router.post("/coupons")
async def create_coupon(code: str, discount_type: str, discount_value: float,
    min_order_amount: float = 0, max_discount_amount: float = None, max_uses: int = 0,
    start_date: datetime = None, end_date: datetime = None,
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    existing = await db.execute(select(Coupon).where(Coupon.code == code.upper()))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Coupon code already exists")
    coupon = Coupon(code=code.upper(), discount_type=DiscountType(discount_type),
        discount_value=discount_value, min_order_amount=min_order_amount,
        max_discount_amount=max_discount_amount, max_uses=max_uses,
        start_date=start_date or datetime.utcnow(),
        end_date=end_date or (datetime.utcnow() + timedelta(days=30)))
    db.add(coupon)
    await db.flush()
    return {"success": True, "data": {"id": str(coupon.id), "code": coupon.code}}


@router.put("/coupons/{coupon_id}/toggle")
async def toggle_coupon(coupon_id: UUID, current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if not coupon: raise HTTPException(status_code=404, detail="Coupon not found")
    coupon.is_active = not coupon.is_active
    await db.flush()
    return {"success": True, "data": {"id": str(coupon.id), "is_active": coupon.is_active}}


@router.delete("/coupons/{coupon_id}")
async def delete_coupon(coupon_id: UUID, current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    result = await db.execute(select(Coupon).where(Coupon.id == coupon_id))
    coupon = result.scalar_one_or_none()
    if not coupon: raise HTTPException(status_code=404, detail="Coupon not found")
    await db.delete(coupon)
    await db.flush()
    return {"success": True, "message": "Coupon deleted"}


# ═══════════════════════════════════════════════════════════════
# REVIEWS
# ═══════════════════════════════════════════════════════════════

@router.get("/reviews")
async def admin_list_reviews(
    is_approved: Optional[bool] = None, page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    _require_admin(current_user)
    query = select(Review).options(joinedload(Review.user), joinedload(Review.product))
    if is_approved is not None: query = query.where(Review.is_approved == is_approved)
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0
    query = query.order_by(Review.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    reviews = result.scalars().all()
    return {"success": True, "data": [
        {"id": str(r.id), "user_name": r.user.full_name if r.user else "N/A",
         "product_name": r.product.name if r.product else "N/A", "rating": r.rating,
         "title": r.title, "comment": r.comment, "is_verified_purchase": r.is_verified_purchase,
         "is_approved": r.is_approved, "helpful_count": r.helpful_count,
         "created_at": r.created_at.isoformat()} for r in reviews],
     "total": total, "page": page, "page_size": page_size,
     "total_pages": (total + page_size - 1) // page_size}


@router.put("/reviews/{review_id}/toggle-approve")
async def toggle_review_approval(review_id: UUID, current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)):
    _require_admin(current_user)
    result = await db.execute(select(Review).where(Review.id == review_id))
    review = result.scalar_one_or_none()
    if not review: raise HTTPException(status_code=404, detail="Review not found")
    review.is_approved = not review.is_approved
    await db.flush()
    return {"success": True, "data": {"id": str(review.id), "is_approved": review.is_approved}}


# ═══════════════════════════════════════════════════════════════
# EXTENDED CRUD OPERATIONS
# ═══════════════════════════════════════════════════════════════

# ─── Vendor CRUD ──────────────────────────────────────────────

@router.post("/vendors")
async def create_vendor(
    vendor_data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new vendor with user account."""
    _require_admin(current_user)
    from app.core.security import get_password_hash
    
    # Create user account
    user = User(
        email=vendor_data["email"],
        password_hash=get_password_hash(vendor_data["password"]),
        full_name=vendor_data["owner_name"],
        phone=vendor_data.get("phone"),
        role=UserRole.VENDOR,
        is_active=vendor_data.get("is_active", True),
        is_verified=True,
    )
    db.add(user)
    await db.flush()
    
    # Create vendor
    vendor = Vendor(
        user_id=user.id,
        store_name=vendor_data["store_name"],
        store_description=vendor_data.get("store_description"),
        store_logo_url=vendor_data.get("store_logo_url"),
        store_banner_url=vendor_data.get("store_banner_url"),
        address=vendor_data["address"],
        city=vendor_data["city"],
        state=vendor_data["state"],
        postal_code=vendor_data["postal_code"],
        latitude=vendor_data.get("latitude"),
        longitude=vendor_data.get("longitude"),
        delivery_radius_km=vendor_data.get("delivery_radius_km", 10.0),
        min_order_amount=vendor_data.get("min_order_amount", 0),
        delivery_charge=vendor_data.get("delivery_charge", 0),
        gstin=vendor_data.get("gstin"),
        pan_number=vendor_data.get("pan_number"),
        fssai_license=vendor_data.get("fssai_license"),
        bank_account_number=vendor_data.get("bank_account_number"),
        bank_ifsc=vendor_data.get("bank_ifsc"),
        bank_name=vendor_data.get("bank_name"),
        commission_percentage=vendor_data.get("commission_percentage", 10.0),
        status=VendorStatus.APPROVED if vendor_data.get("auto_approve") else VendorStatus.PENDING,
        is_active=vendor_data.get("is_active", True),
    )
    db.add(vendor)
    await db.flush()
    
    return {"success": True, "data": {"id": str(vendor.id), "user_id": str(user.id), 
            "store_name": vendor.store_name, "status": vendor.status.value}}


@router.delete("/vendors/{vendor_id}")
async def delete_vendor(
    vendor_id: UUID,
    hard_delete: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete or soft-delete a vendor."""
    _require_admin(current_user)
    result = await db.execute(select(Vendor).where(Vendor.id == vendor_id))
    vendor = result.scalar_one_or_none()
    if not vendor: raise HTTPException(status_code=404, detail="Vendor not found")
    
    if hard_delete:
        await db.delete(vendor)
    else:
        vendor.is_active = False
        vendor.status = VendorStatus.REJECTED
    
    await db.flush()
    return {"success": True, "message": "Vendor deleted" if hard_delete else "Vendor deactivated"}


# ─── Category CRUD ────────────────────────────────────────────

@router.post("/categories")
async def create_category(
    category_data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new product category."""
    _require_admin(current_user)
    
    # Check if slug exists
    existing = await db.execute(
        select(ProductCategory).where(ProductCategory.slug == category_data["slug"])
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Category slug already exists")
    
    category = ProductCategory(
        name=category_data["name"],
        slug=category_data["slug"],
        description=category_data.get("description"),
        icon_url=category_data.get("icon_url"),
        image_url=category_data.get("image_url"),
        parent_id=category_data.get("parent_id"),
        sort_order=category_data.get("sort_order", 0),
        is_active=category_data.get("is_active", True),
    )
    db.add(category)
    await db.flush()
    
    return {"success": True, "data": {
        "id": str(category.id), "name": category.name, "slug": category.slug,
        "parent_id": str(category.parent_id) if category.parent_id else None,
        "is_active": category.is_active,
    }}


@router.put("/categories/{category_id}")
async def update_category(
    category_id: UUID,
    category_data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update a product category."""
    _require_admin(current_user)
    result = await db.execute(select(ProductCategory).where(ProductCategory.id == category_id))
    category = result.scalar_one_or_none()
    if not category: raise HTTPException(status_code=404, detail="Category not found")
    
    for key, value in category_data.items():
        if value is not None and hasattr(category, key):
            setattr(category, key, value)
    
    await db.flush()
    return {"success": True, "data": {
        "id": str(category.id), "name": category.name, "slug": category.slug,
        "is_active": category.is_active,
    }}


@router.delete("/categories/{category_id}")
async def delete_category(
    category_id: UUID,
    move_products_to: Optional[UUID] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a category, optionally moving products to another category."""
    _require_admin(current_user)
    result = await db.execute(select(ProductCategory).where(ProductCategory.id == category_id))
    category = result.scalar_one_or_none()
    if not category: raise HTTPException(status_code=404, detail="Category not found")
    
    # Check if category has products
    products_count = (await db.execute(
        select(func.count(Product.id)).where(Product.category_id == category_id)
    )).scalar() or 0
    
    if products_count > 0:
        if move_products_to:
            # Move products to new category
            await db.execute(
                Product.__table__.update()
                .where(Product.category_id == category_id)
                .values(category_id=move_products_to)
            )
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Category has {products_count} products. Provide move_products_to parameter."
            )
    
    await db.delete(category)
    await db.flush()
    return {"success": True, "message": "Category deleted"}


# ─── Product CRUD ─────────────────────────────────────────────

@router.post("/products")
async def create_product(
    product_data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new product."""
    _require_admin(current_user)
    
    product = Product(
        vendor_id=product_data["vendor_id"],
        category_id=product_data["category_id"],
        name=product_data["name"],
        description=product_data.get("description"),
        short_description=product_data.get("short_description"),
        sku=product_data.get("sku"),
        barcode=product_data.get("barcode"),
        brand=product_data.get("brand"),
        price=product_data["price"],
        compare_at_price=product_data.get("compare_at_price"),
        cost_price=product_data.get("cost_price"),
        stock_quantity=product_data.get("stock_quantity", 0),
        low_stock_threshold=product_data.get("low_stock_threshold", 10),
        unit_type=product_data.get("unit_type", "piece"),
        unit_value=product_data.get("unit_value", 1),
        weight_grams=product_data.get("weight_grams"),
        is_featured=product_data.get("is_featured", False),
        is_perishable=product_data.get("is_perishable", False),
        status=ProductStatus.ACTIVE if product_data.get("status") == "active" else ProductStatus.DRAFT,
    )
    db.add(product)
    await db.flush()
    
    return {"success": True, "data": {
        "id": str(product.id), "name": product.name, "sku": product.sku,
        "price": float(product.price), "status": product.status.value,
    }}


@router.put("/products/{product_id}")
async def update_product(
    product_id: UUID,
    product_data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update a product."""
    _require_admin(current_user)
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product: raise HTTPException(status_code=404, detail="Product not found")
    
    for key, value in product_data.items():
        if value is not None and hasattr(product, key):
            if key == "status" and isinstance(value, str):
                setattr(product, key, ProductStatus(value))
            else:
                setattr(product, key, value)
    
    await db.flush()
    return {"success": True, "data": {
        "id": str(product.id), "name": product.name, "price": float(product.price),
        "status": product.status.value,
    }}


@router.delete("/products/{product_id}")
async def delete_product(
    product_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a product."""
    _require_admin(current_user)
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product: raise HTTPException(status_code=404, detail="Product not found")
    
    await db.delete(product)
    await db.flush()
    return {"success": True, "message": "Product deleted"}


# ─── Customer CRUD ────────────────────────────────────────────

@router.post("/customers")
async def create_customer(
    customer_data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new customer account."""
    _require_admin(current_user)
    from app.core.security import get_password_hash
    
    # Check if email exists
    existing = await db.execute(select(User).where(User.email == customer_data["email"]))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user = User(
        email=customer_data["email"],
        password_hash=get_password_hash(customer_data.get("password", "Password123!")),
        full_name=customer_data["full_name"],
        phone=customer_data.get("phone"),
        role=UserRole.CUSTOMER,
        is_active=customer_data.get("is_active", True),
        is_verified=True,
    )
    db.add(user)
    await db.flush()
    
    return {"success": True, "data": {
        "id": str(user.id), "email": user.email, "full_name": user.full_name,
        "is_active": user.is_active,
    }}


@router.put("/customers/{user_id}")
async def update_customer(
    user_id: UUID,
    customer_data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update a customer account."""
    _require_admin(current_user)
    result = await db.execute(select(User).where(User.id == user_id, User.role == UserRole.CUSTOMER))
    user = result.scalar_one_or_none()
    if not user: raise HTTPException(status_code=404, detail="Customer not found")
    
    for key, value in customer_data.items():
        if value is not None and hasattr(user, key) and key not in ["id", "password_hash", "created_at"]:
            setattr(user, key, value)
    
    if "password" in customer_data and customer_data["password"]:
        from app.core.security import get_password_hash
        user.password_hash = get_password_hash(customer_data["password"])
    
    await db.flush()
    return {"success": True, "data": {
        "id": str(user.id), "email": user.email, "full_name": user.full_name,
        "is_active": user.is_active,
    }}


@router.delete("/customers/{user_id}")
async def delete_customer(
    user_id: UUID,
    anonymize: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete or anonymize a customer account."""
    _require_admin(current_user)
    result = await db.execute(select(User).where(User.id == user_id, User.role == UserRole.CUSTOMER))
    user = result.scalar_one_or_none()
    if not user: raise HTTPException(status_code=404, detail="Customer not found")
    
    if anonymize:
        # GDPR-compliant anonymization
        user.email = f"deleted_{user.id}@deleted.com"
        user.full_name = "Deleted User"
        user.phone = None
        user.is_active = False
        await db.flush()
        return {"success": True, "message": "Customer data anonymized"}
    else:
        await db.delete(user)
        await db.flush()
        return {"success": True, "message": "Customer deleted"}
