"""Promotion and Coupon models."""
import uuid
from datetime import datetime
from sqlalchemy import (
    String, Boolean, DateTime, Float, Text, Integer,
    ForeignKey, Index, Enum as SAEnum,
)
from sqlalchemy.dialects.postgresql import UUID, JSONB, ARRAY
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base
import enum


class DiscountType(str, enum.Enum):
    PERCENTAGE = "percentage"
    FLAT = "flat"
    FREE_DELIVERY = "free_delivery"
    BUY_X_GET_Y = "buy_x_get_y"


class Promotion(Base):
    __tablename__ = "promotions"
    __table_args__ = (
        Index("ix_promotions_is_active", "is_active"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    banner_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    discount_type: Mapped[DiscountType] = mapped_column(
        SAEnum(DiscountType), nullable=False
    )
    discount_value: Mapped[float] = mapped_column(Float, nullable=False)
    min_order_amount: Mapped[float] = mapped_column(Float, default=0.0)
    max_discount_amount: Mapped[float | None] = mapped_column(Float, nullable=True)
    applicable_categories: Mapped[list | None] = mapped_column(
        ARRAY(String), nullable=True
    )
    applicable_vendors: Mapped[list | None] = mapped_column(
        ARRAY(String), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    start_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    end_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )


class Coupon(Base):
    __tablename__ = "coupons"
    __table_args__ = (
        Index("ix_coupons_code", "code", unique=True),
        Index("ix_coupons_is_active", "is_active"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    discount_type: Mapped[DiscountType] = mapped_column(
        SAEnum(DiscountType), nullable=False
    )
    discount_value: Mapped[float] = mapped_column(Float, nullable=False)
    min_order_amount: Mapped[float] = mapped_column(Float, default=0.0)
    max_discount_amount: Mapped[float | None] = mapped_column(Float, nullable=True)
    max_uses: Mapped[int] = mapped_column(Integer, default=0)  # 0 = unlimited
    used_count: Mapped[int] = mapped_column(Integer, default=0)
    max_uses_per_user: Mapped[int] = mapped_column(Integer, default=1)
    vendor_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id"), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    start_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    end_date: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )
