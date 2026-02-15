"""Review endpoints."""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.product import Product
from app.models.review import Review
from app.models.order import Order, OrderStatus
from app.schemas.review import ReviewCreate, ReviewUpdate, ReviewResponse
from app.schemas.base import ResponseBase, PaginatedResponse

router = APIRouter(prefix="/reviews", tags=["Reviews"])


@router.post("/", response_model=ResponseBase[ReviewResponse], status_code=201)
async def create_review(
    data: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a product review."""
    # Verify product exists
    product_result = await db.execute(
        select(Product).where(Product.id == data.product_id)
    )
    product = product_result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    # Check if already reviewed
    existing = await db.execute(
        select(Review).where(
            Review.user_id == current_user.id,
            Review.product_id == data.product_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Already reviewed this product")

    # Check verified purchase
    is_verified = False
    if data.order_id:
        order_result = await db.execute(
            select(Order).where(
                Order.id == data.order_id,
                Order.customer_id == current_user.id,
                Order.status == OrderStatus.DELIVERED,
            )
        )
        if order_result.scalar_one_or_none():
            is_verified = True

    review = Review(
        user_id=current_user.id,
        product_id=data.product_id,
        vendor_id=product.vendor_id,
        order_id=data.order_id,
        rating=data.rating,
        title=data.title,
        comment=data.comment,
        is_verified_purchase=is_verified,
    )
    db.add(review)
    await db.flush()

    # Update product rating
    avg_result = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(
            Review.product_id == data.product_id
        )
    )
    avg_row = avg_result.one()
    product.avg_rating = round(float(avg_row[0] or 0), 1)
    product.total_reviews = int(avg_row[1] or 0)
    await db.flush()

    return ResponseBase(data=ReviewResponse.model_validate(review))


@router.get("/product/{product_id}", response_model=PaginatedResponse[ReviewResponse])
async def get_product_reviews(
    product_id: UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """Get reviews for a product."""
    query = select(Review).where(
        Review.product_id == product_id, Review.is_approved == True
    )

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = query.order_by(Review.created_at.desc()).offset(
        (page - 1) * page_size
    ).limit(page_size)

    result = await db.execute(query)
    reviews = result.scalars().all()

    return PaginatedResponse(
        data=[ReviewResponse.model_validate(r) for r in reviews],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )
