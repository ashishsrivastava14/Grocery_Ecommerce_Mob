"""Admin panel endpoints."""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
from datetime import datetime, timedelta
from typing import Optional

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, UserRole
from app.models.vendor import Vendor, VendorStatus
from app.models.product import Product
from app.models.order import Order, OrderStatus
from app.models.payment import VendorPayout, PayoutStatus
from app.models.promotion import Coupon, Promotion
from app.schemas.vendor import VendorResponse, VendorAdminUpdate
from app.schemas.base import ResponseBase, PaginatedResponse

router = APIRouter(prefix="/admin", tags=["Admin"])


def _require_admin(user: User):
    if user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")


# --- Dashboard ---
@router.get("/dashboard")
async def admin_dashboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get admin dashboard statistics."""
    _require_admin(current_user)

    # Users count
    users_count = (await db.execute(select(func.count(User.id)))).scalar() or 0

    # Vendors count
    vendors_count = (await db.execute(select(func.count(Vendor.id)))).scalar() or 0
    pending_vendors = (await db.execute(
        select(func.count(Vendor.id)).where(Vendor.status == VendorStatus.PENDING)
    )).scalar() or 0

    # Orders
    total_orders = (await db.execute(select(func.count(Order.id)))).scalar() or 0
    total_revenue = (await db.execute(
        select(func.sum(Order.total_amount)).where(Order.status == OrderStatus.DELIVERED)
    )).scalar() or 0

    # Products
    total_products = (await db.execute(select(func.count(Product.id)))).scalar() or 0

    # Recent 30 days revenue
    thirty_days_ago = datetime.utcnow() - timedelta(days=30)
    monthly_revenue = (await db.execute(
        select(func.sum(Order.total_amount)).where(
            Order.status == OrderStatus.DELIVERED,
            Order.created_at >= thirty_days_ago,
        )
    )).scalar() or 0

    return {
        "success": True,
        "data": {
            "total_users": users_count,
            "total_vendors": vendors_count,
            "pending_vendors": pending_vendors,
            "total_orders": total_orders,
            "total_revenue": float(total_revenue),
            "monthly_revenue": float(monthly_revenue),
            "total_products": total_products,
        },
    }


# --- Vendor Management ---
@router.get("/vendors", response_model=PaginatedResponse[VendorResponse])
async def list_all_vendors(
    status: Optional[VendorStatus] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all vendors (with optional status filter)."""
    _require_admin(current_user)

    query = select(Vendor)
    if status:
        query = query.where(Vendor.status == status)

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = query.order_by(Vendor.created_at.desc()).offset(
        (page - 1) * page_size
    ).limit(page_size)

    result = await db.execute(query)
    vendors = result.scalars().all()

    return PaginatedResponse(
        data=[VendorResponse.model_validate(v) for v in vendors],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )


@router.put("/vendors/{vendor_id}", response_model=ResponseBase[VendorResponse])
async def update_vendor_admin(
    vendor_id: UUID,
    data: VendorAdminUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Approve, reject, or configure a vendor."""
    _require_admin(current_user)

    result = await db.execute(select(Vendor).where(Vendor.id == vendor_id))
    vendor = result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor not found")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(vendor, key, value)

    if data.status == VendorStatus.APPROVED:
        vendor.is_active = True

    await db.flush()
    return ResponseBase(data=VendorResponse.model_validate(vendor))


# --- Coupon Management ---
@router.post("/coupons")
async def create_coupon(
    code: str,
    discount_type: str,
    discount_value: float,
    min_order_amount: float = 0,
    max_discount_amount: float = None,
    max_uses: int = 0,
    start_date: datetime = None,
    end_date: datetime = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a coupon code."""
    _require_admin(current_user)
    from app.models.promotion import DiscountType

    coupon = Coupon(
        code=code.upper(),
        discount_type=DiscountType(discount_type),
        discount_value=discount_value,
        min_order_amount=min_order_amount,
        max_discount_amount=max_discount_amount,
        max_uses=max_uses,
        start_date=start_date or datetime.utcnow(),
        end_date=end_date or (datetime.utcnow() + timedelta(days=30)),
    )
    db.add(coupon)
    await db.flush()
    return {"success": True, "data": {"id": str(coupon.id), "code": coupon.code}}


# --- Payout Management ---
@router.get("/payouts")
async def list_payouts(
    status: Optional[PayoutStatus] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all vendor payouts."""
    _require_admin(current_user)

    query = select(VendorPayout)
    if status:
        query = query.where(VendorPayout.status == status)

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = query.order_by(VendorPayout.created_at.desc()).offset(
        (page - 1) * page_size
    ).limit(page_size)

    result = await db.execute(query)
    payouts = result.scalars().all()

    return {
        "success": True,
        "data": [
            {
                "id": str(p.id),
                "vendor_id": str(p.vendor_id),
                "amount": p.amount,
                "commission_deducted": p.commission_deducted,
                "net_amount": p.net_amount,
                "status": p.status.value,
                "created_at": p.created_at.isoformat(),
            }
            for p in payouts
        ],
        "total": total,
        "page": page,
    }
