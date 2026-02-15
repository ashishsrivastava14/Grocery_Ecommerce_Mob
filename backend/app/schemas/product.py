"""Product schemas."""
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime
from app.models.product import ProductStatus, UnitType


# Category
class CategoryCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    slug: str = Field(..., min_length=2, max_length=120)
    description: Optional[str] = None
    icon_url: Optional[str] = None
    image_url: Optional[str] = None
    parent_id: Optional[UUID] = None
    sort_order: int = 0


class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    slug: Optional[str] = None
    description: Optional[str] = None
    icon_url: Optional[str] = None
    image_url: Optional[str] = None
    parent_id: Optional[UUID] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class CategoryResponse(BaseModel):
    id: UUID
    name: str
    slug: str
    description: Optional[str] = None
    icon_url: Optional[str] = None
    image_url: Optional[str] = None
    parent_id: Optional[UUID] = None
    sort_order: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# Product
class ProductCreate(BaseModel):
    category_id: UUID
    name: str = Field(..., min_length=2, max_length=200)
    slug: str = Field(..., min_length=2, max_length=250)
    description: Optional[str] = None
    short_description: Optional[str] = None
    price: float = Field(..., gt=0)
    compare_at_price: Optional[float] = None
    cost_price: Optional[float] = None
    sku: Optional[str] = None
    barcode: Optional[str] = None
    stock_quantity: int = Field(0, ge=0)
    low_stock_threshold: int = 5
    track_inventory: bool = True
    unit_type: UnitType = UnitType.KG
    unit_value: float = 1.0
    is_featured: bool = False
    is_organic: bool = False
    tags: Optional[dict] = None
    nutritional_info: Optional[dict] = None


class ProductUpdate(BaseModel):
    category_id: Optional[UUID] = None
    name: Optional[str] = None
    slug: Optional[str] = None
    description: Optional[str] = None
    short_description: Optional[str] = None
    price: Optional[float] = Field(None, gt=0)
    compare_at_price: Optional[float] = None
    cost_price: Optional[float] = None
    sku: Optional[str] = None
    stock_quantity: Optional[int] = Field(None, ge=0)
    low_stock_threshold: Optional[int] = None
    unit_type: Optional[UnitType] = None
    unit_value: Optional[float] = None
    status: Optional[ProductStatus] = None
    is_featured: Optional[bool] = None
    is_organic: Optional[bool] = None
    tags: Optional[dict] = None
    nutritional_info: Optional[dict] = None


class ProductImageResponse(BaseModel):
    id: UUID
    image_url: str
    alt_text: Optional[str] = None
    sort_order: int
    is_primary: bool

    class Config:
        from_attributes = True


class ProductVariantResponse(BaseModel):
    id: UUID
    name: str
    sku: Optional[str] = None
    price: float
    compare_at_price: Optional[float] = None
    stock_quantity: int
    unit_type: UnitType
    unit_value: float
    is_active: bool
    attributes: Optional[dict] = None

    class Config:
        from_attributes = True


class ProductResponse(BaseModel):
    id: UUID
    vendor_id: UUID
    category_id: UUID
    name: str
    slug: str
    description: Optional[str] = None
    short_description: Optional[str] = None
    price: float
    compare_at_price: Optional[float] = None
    sku: Optional[str] = None
    stock_quantity: int
    unit_type: UnitType
    unit_value: float
    status: ProductStatus
    is_featured: bool
    is_organic: bool
    avg_rating: float
    total_reviews: int
    total_sold: int
    tags: Optional[dict] = None
    nutritional_info: Optional[dict] = None
    images: list[ProductImageResponse] = []
    variants: list[ProductVariantResponse] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ProductVariantCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    sku: Optional[str] = None
    price: float = Field(..., gt=0)
    compare_at_price: Optional[float] = None
    stock_quantity: int = Field(0, ge=0)
    unit_type: UnitType = UnitType.KG
    unit_value: float = 1.0
    attributes: Optional[dict] = None


class ProductFilter(BaseModel):
    category_id: Optional[UUID] = None
    vendor_id: Optional[UUID] = None
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    status: Optional[ProductStatus] = None
    is_featured: Optional[bool] = None
    is_organic: Optional[bool] = None
    search: Optional[str] = None
    sort_by: str = "created_at"
    sort_order: str = "desc"
    page: int = 1
    page_size: int = 20
