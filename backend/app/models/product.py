"""Product, Category, Variant, Image models."""
import uuid
from datetime import datetime
from sqlalchemy import (
    String, Boolean, DateTime, Float, Text, Integer,
    ForeignKey, Index, Enum as SAEnum,
)
from sqlalchemy.dialects.postgresql import UUID, JSONB, TSVECTOR
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class ProductStatus(str, enum.Enum):
    DRAFT = "draft"
    ACTIVE = "active"
    OUT_OF_STOCK = "out_of_stock"
    DISCONTINUED = "discontinued"


class UnitType(str, enum.Enum):
    KG = "kg"
    GRAM = "gram"
    LITRE = "litre"
    ML = "ml"
    PIECE = "piece"
    DOZEN = "dozen"
    PACK = "pack"


class ProductCategory(Base):
    __tablename__ = "product_categories"
    __table_args__ = (
        Index("ix_product_categories_parent_id", "parent_id"),
        Index("ix_product_categories_slug", "slug", unique=True),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    slug: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    icon_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    parent_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("product_categories.id"), nullable=True
    )
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    # Self-referential relationship
    children: Mapped[list["ProductCategory"]] = relationship(
        back_populates="parent", lazy="selectin"
    )
    parent: Mapped["ProductCategory | None"] = relationship(
        back_populates="children", remote_side="ProductCategory.id", lazy="selectin"
    )
    products: Mapped[list["Product"]] = relationship(
        back_populates="category", lazy="selectin"
    )


class Product(Base):
    __tablename__ = "products"
    __table_args__ = (
        Index("ix_products_vendor_id", "vendor_id"),
        Index("ix_products_category_id", "category_id"),
        Index("ix_products_status", "status"),
        Index("ix_products_slug", "slug"),
        Index("ix_products_price", "price"),
        Index("ix_products_search", "search_vector", postgresql_using="gin"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    vendor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id", ondelete="CASCADE"), nullable=False
    )
    category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("product_categories.id"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    slug: Mapped[str] = mapped_column(String(250), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    short_description: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Pricing
    price: Mapped[float] = mapped_column(Float, nullable=False)
    compare_at_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    cost_price: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Inventory
    sku: Mapped[str | None] = mapped_column(String(50), nullable=True)
    barcode: Mapped[str | None] = mapped_column(String(50), nullable=True)
    stock_quantity: Mapped[int] = mapped_column(Integer, default=0)
    low_stock_threshold: Mapped[int] = mapped_column(Integer, default=5)
    track_inventory: Mapped[bool] = mapped_column(Boolean, default=True)

    # Unit
    unit_type: Mapped[UnitType] = mapped_column(
        SAEnum(UnitType), default=UnitType.KG, nullable=False
    )
    unit_value: Mapped[float] = mapped_column(Float, default=1.0)

    # Status & Flags
    status: Mapped[ProductStatus] = mapped_column(
        SAEnum(ProductStatus), default=ProductStatus.ACTIVE, nullable=False
    )
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)
    is_organic: Mapped[bool] = mapped_column(Boolean, default=False)

    # Ratings
    avg_rating: Mapped[float] = mapped_column(Float, default=0.0)
    total_reviews: Mapped[int] = mapped_column(Integer, default=0)
    total_sold: Mapped[int] = mapped_column(Integer, default=0)

    # Search
    search_vector: Mapped[str | None] = mapped_column(TSVECTOR, nullable=True)
    tags: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    nutritional_info: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # Relationships
    vendor: Mapped["Vendor"] = relationship(back_populates="products")  # noqa: F821
    category: Mapped["ProductCategory"] = relationship(back_populates="products")
    variants: Mapped[list["ProductVariant"]] = relationship(
        back_populates="product", cascade="all, delete-orphan", lazy="selectin"
    )
    images: Mapped[list["ProductImage"]] = relationship(
        back_populates="product", cascade="all, delete-orphan", lazy="selectin"
    )
    reviews: Mapped[list["Review"]] = relationship(  # noqa: F821
        back_populates="product", lazy="selectin"
    )


class ProductVariant(Base):
    __tablename__ = "product_variants"
    __table_args__ = (
        Index("ix_product_variants_product_id", "product_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    sku: Mapped[str | None] = mapped_column(String(50), nullable=True)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    compare_at_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    stock_quantity: Mapped[int] = mapped_column(Integer, default=0)
    unit_type: Mapped[UnitType] = mapped_column(
        SAEnum(UnitType), default=UnitType.KG, nullable=False
    )
    unit_value: Mapped[float] = mapped_column(Float, default=1.0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    attributes: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    product: Mapped["Product"] = relationship(back_populates="variants")


class ProductImage(Base):
    __tablename__ = "product_images"
    __table_args__ = (
        Index("ix_product_images_product_id", "product_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=False
    )
    image_url: Mapped[str] = mapped_column(String(500), nullable=False)
    alt_text: Mapped[str | None] = mapped_column(String(200), nullable=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    product: Mapped["Product"] = relationship(back_populates="images")
