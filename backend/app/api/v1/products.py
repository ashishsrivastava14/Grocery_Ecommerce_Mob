"""Product endpoints: CRUD, search, filter, image upload."""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_, text
from uuid import UUID
from typing import Optional

from app.database import get_db
from app.api.deps import get_current_user, get_optional_user
from app.models.user import User
from app.models.vendor import Vendor
from app.models.product import Product, ProductCategory, ProductVariant, ProductImage, ProductStatus
from app.schemas.product import (
    ProductCreate, ProductUpdate, ProductResponse,
    CategoryCreate, CategoryUpdate, CategoryResponse,
    ProductVariantCreate, ProductVariantResponse,
    ProductImageResponse, ProductFilter,
)
from app.schemas.base import ResponseBase, PaginatedResponse

router = APIRouter(prefix="/products", tags=["Products"])


# --- Categories ---
@router.get("/categories", response_model=ResponseBase[list[CategoryResponse]])
async def list_categories(
    parent_id: Optional[UUID] = None,
    db: AsyncSession = Depends(get_db),
):
    """List product categories."""
    query = select(ProductCategory).where(ProductCategory.is_active == True)
    if parent_id:
        query = query.where(ProductCategory.parent_id == parent_id)
    else:
        query = query.where(ProductCategory.parent_id.is_(None))
    query = query.order_by(ProductCategory.sort_order)

    result = await db.execute(query)
    categories = result.scalars().all()
    return ResponseBase(
        data=[CategoryResponse.model_validate(c) for c in categories]
    )


@router.post("/categories", response_model=ResponseBase[CategoryResponse], status_code=201)
async def create_category(
    data: CategoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a product category (admin only)."""
    from app.models.user import UserRole
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")

    category = ProductCategory(**data.model_dump())
    db.add(category)
    await db.flush()
    return ResponseBase(data=CategoryResponse.model_validate(category))


# --- Products ---
@router.get("/", response_model=PaginatedResponse[ProductResponse])
async def list_products(
    category_id: Optional[UUID] = None,
    vendor_id: Optional[UUID] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    is_featured: Optional[bool] = None,
    is_organic: Optional[bool] = None,
    search: Optional[str] = None,
    sort_by: str = "created_at",
    sort_order: str = "desc",
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """List products with filtering, sorting, and pagination."""
    query = select(Product).where(Product.status == ProductStatus.ACTIVE)

    if category_id:
        query = query.where(Product.category_id == category_id)
    if vendor_id:
        query = query.where(Product.vendor_id == vendor_id)
    if min_price is not None:
        query = query.where(Product.price >= min_price)
    if max_price is not None:
        query = query.where(Product.price <= max_price)
    if is_featured is not None:
        query = query.where(Product.is_featured == is_featured)
    if is_organic is not None:
        query = query.where(Product.is_organic == is_organic)
    if search:
        search_filter = or_(
            Product.name.ilike(f"%{search}%"),
            Product.description.ilike(f"%{search}%"),
        )
        query = query.where(search_filter)

    # Count
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    # Sort
    sort_column = getattr(Product, sort_by, Product.created_at)
    if sort_order == "asc":
        query = query.order_by(sort_column.asc())
    else:
        query = query.order_by(sort_column.desc())

    # Paginate
    query = query.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    products = result.scalars().all()

    return PaginatedResponse(
        data=[ProductResponse.model_validate(p) for p in products],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )


@router.get("/search", response_model=PaginatedResponse[ProductResponse])
async def search_products(
    q: str = Query(..., min_length=1),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """Full-text search products with autocomplete."""
    query = select(Product).where(
        Product.status == ProductStatus.ACTIVE,
        or_(
            Product.name.ilike(f"%{q}%"),
            Product.description.ilike(f"%{q}%"),
            Product.short_description.ilike(f"%{q}%"),
        ),
    )

    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar() or 0

    query = query.order_by(Product.total_sold.desc()).offset(
        (page - 1) * page_size
    ).limit(page_size)

    result = await db.execute(query)
    products = result.scalars().all()

    return PaginatedResponse(
        data=[ProductResponse.model_validate(p) for p in products],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )


@router.get("/autocomplete")
async def autocomplete_products(
    q: str = Query(..., min_length=1),
    limit: int = Query(10, ge=1, le=20),
    db: AsyncSession = Depends(get_db),
):
    """Return product name suggestions for autocomplete."""
    result = await db.execute(
        select(Product.id, Product.name, Product.price, Product.unit_type)
        .where(
            Product.status == ProductStatus.ACTIVE,
            Product.name.ilike(f"%{q}%"),
        )
        .order_by(Product.total_sold.desc())
        .limit(limit)
    )
    suggestions = [
        {"id": str(r.id), "name": r.name, "price": r.price, "unit_type": r.unit_type.value}
        for r in result.all()
    ]
    return {"success": True, "data": suggestions}


@router.get("/{product_id}", response_model=ResponseBase[ProductResponse])
async def get_product(product_id: UUID, db: AsyncSession = Depends(get_db)):
    """Get product details."""
    result = await db.execute(select(Product).where(Product.id == product_id))
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return ResponseBase(data=ProductResponse.model_validate(product))


@router.post("/", response_model=ResponseBase[ProductResponse], status_code=201)
async def create_product(
    data: ProductCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new product (vendor only)."""
    vendor_result = await db.execute(
        select(Vendor).where(Vendor.user_id == current_user.id)
    )
    vendor = vendor_result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=403, detail="Only vendors can create products")

    product = Product(vendor_id=vendor.id, **data.model_dump())
    db.add(product)
    await db.flush()
    return ResponseBase(data=ProductResponse.model_validate(product))


@router.put("/{product_id}", response_model=ResponseBase[ProductResponse])
async def update_product(
    product_id: UUID,
    data: ProductUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update a product (vendor owner only)."""
    vendor_result = await db.execute(
        select(Vendor).where(Vendor.user_id == current_user.id)
    )
    vendor = vendor_result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=403, detail="Vendor access required")

    result = await db.execute(
        select(Product).where(
            Product.id == product_id, Product.vendor_id == vendor.id
        )
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(product, key, value)
    await db.flush()
    return ResponseBase(data=ProductResponse.model_validate(product))


@router.delete("/{product_id}", response_model=ResponseBase)
async def delete_product(
    product_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a product (vendor owner only)."""
    vendor_result = await db.execute(
        select(Vendor).where(Vendor.user_id == current_user.id)
    )
    vendor = vendor_result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=403, detail="Vendor access required")

    result = await db.execute(
        select(Product).where(
            Product.id == product_id, Product.vendor_id == vendor.id
        )
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    await db.delete(product)
    await db.flush()
    return ResponseBase(message="Product deleted")


# --- Variants ---
@router.post("/{product_id}/variants", response_model=ResponseBase[ProductVariantResponse], status_code=201)
async def add_variant(
    product_id: UUID,
    data: ProductVariantCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Add a variant to a product."""
    vendor_result = await db.execute(
        select(Vendor).where(Vendor.user_id == current_user.id)
    )
    vendor = vendor_result.scalar_one_or_none()
    if not vendor:
        raise HTTPException(status_code=403, detail="Vendor access required")

    result = await db.execute(
        select(Product).where(
            Product.id == product_id, Product.vendor_id == vendor.id
        )
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    variant = ProductVariant(product_id=product_id, **data.model_dump())
    db.add(variant)
    await db.flush()
    return ResponseBase(data=ProductVariantResponse.model_validate(variant))
