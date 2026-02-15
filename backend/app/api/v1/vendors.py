"""Vendor endpoints: registration, profile, dashboard, store timings."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, UserRole
from app.models.vendor import Vendor, StoreTimings, VendorStatus
from app.models.product import Product
from app.models.order import Order, OrderStatus
from app.schemas.vendor import (
    VendorRegisterRequest, VendorUpdate, VendorResponse,
    StoreTimingsCreate, StoreTimingsResponse, VendorDashboardStats,
)
from app.schemas.base import ResponseBase, PaginatedResponse
from app.config import get_settings

router = APIRouter(prefix="/vendors", tags=["Vendors"])
settings = get_settings()


@router.post("/register", response_model=ResponseBase[VendorResponse], status_code=201)
async def register_vendor(
    data: VendorRegisterRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Register current user as a vendor."""
    # Check if already vendor
    existing = await db.execute(
        select(Vendor).where(Vendor.user_id == current_user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Already registered as vendor")

    vendor = Vendor(
        user_id=current_user.id,
        commission_rate=settings.DEFAULT_COMMISSION_RATE,
        **data.model_dump(),
    )
    db.add(vendor)

    # Update user role
    current_user.role = UserRole.VENDOR
    await db.flush()

    return ResponseBase(data=VendorResponse.model_validate(vendor))


@router.get("/me", response_model=ResponseBase[VendorResponse])
async def get_vendor_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get vendor profile for current user."""
    result = await db.execute(
        select(Vendor).where(Vendor.user_id == current_user.id)
    )
    vendor = result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor profile not found")
    return ResponseBase(data=VendorResponse.model_validate(vendor))


@router.put("/me", response_model=ResponseBase[VendorResponse])
async def update_vendor_profile(
    data: VendorUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update vendor profile."""
    result = await db.execute(
        select(Vendor).where(Vendor.user_id == current_user.id)
    )
    vendor = result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor profile not found")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(vendor, key, value)
    await db.flush()
    return ResponseBase(data=VendorResponse.model_validate(vendor))


@router.get("/me/dashboard", response_model=ResponseBase[VendorDashboardStats])
async def get_vendor_dashboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get vendor dashboard stats."""
    result = await db.execute(
        select(Vendor).where(Vendor.user_id == current_user.id)
    )
    vendor = result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor profile not found")

    # Total orders
    total_orders_result = await db.execute(
        select(func.count(Order.id)).where(Order.vendor_id == vendor.id)
    )
    total_orders = total_orders_result.scalar() or 0

    # Pending orders
    pending_result = await db.execute(
        select(func.count(Order.id)).where(
            Order.vendor_id == vendor.id,
            Order.status.in_([OrderStatus.PENDING, OrderStatus.CONFIRMED]),
        )
    )
    pending_orders = pending_result.scalar() or 0

    # Revenue
    revenue_result = await db.execute(
        select(func.sum(Order.vendor_payout_amount)).where(
            Order.vendor_id == vendor.id,
            Order.status == OrderStatus.DELIVERED,
        )
    )
    total_revenue = revenue_result.scalar() or 0.0

    # Products count
    products_result = await db.execute(
        select(func.count(Product.id)).where(Product.vendor_id == vendor.id)
    )
    total_products = products_result.scalar() or 0

    return ResponseBase(
        data=VendorDashboardStats(
            total_orders=total_orders,
            pending_orders=pending_orders,
            total_revenue=total_revenue,
            total_products=total_products,
            avg_rating=vendor.rating,
        )
    )


# --- Store Timings ---
@router.put("/me/timings", response_model=ResponseBase[list[StoreTimingsResponse]])
async def set_store_timings(
    timings: list[StoreTimingsCreate],
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Set or update store timings (replaces all existing)."""
    result = await db.execute(
        select(Vendor).where(Vendor.user_id == current_user.id)
    )
    vendor = result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor profile not found")

    # Remove existing
    existing = await db.execute(
        select(StoreTimings).where(StoreTimings.vendor_id == vendor.id)
    )
    for t in existing.scalars().all():
        await db.delete(t)

    # Create new
    new_timings = []
    for t in timings:
        timing = StoreTimings(vendor_id=vendor.id, **t.model_dump())
        db.add(timing)
        new_timings.append(timing)

    await db.flush()
    return ResponseBase(
        data=[StoreTimingsResponse.model_validate(t) for t in new_timings]
    )


# --- Public vendor listing ---
@router.get("/", response_model=PaginatedResponse[VendorResponse])
async def list_vendors(
    city: str | None = None,
    is_active: bool = True,
    page: int = 1,
    page_size: int = 20,
    db: AsyncSession = Depends(get_db),
):
    """List all approved and active vendors."""
    query = select(Vendor).where(
        Vendor.status == VendorStatus.APPROVED,
        Vendor.is_active == is_active,
    )
    if city:
        query = query.where(Vendor.city.ilike(f"%{city}%"))

    # Count
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    # Paginate
    query = query.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    vendors = result.scalars().all()

    return PaginatedResponse(
        data=[VendorResponse.model_validate(v) for v in vendors],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )


@router.get("/{vendor_id}", response_model=ResponseBase[VendorResponse])
async def get_vendor(vendor_id: UUID, db: AsyncSession = Depends(get_db)):
    """Get vendor details by ID."""
    result = await db.execute(select(Vendor).where(Vendor.id == vendor_id))
    vendor = result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=404, detail="Vendor not found")
    return ResponseBase(data=VendorResponse.model_validate(vendor))
