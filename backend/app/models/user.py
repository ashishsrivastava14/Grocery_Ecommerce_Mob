"""User and Address models."""
import uuid
from datetime import datetime
from sqlalchemy import (
    String, Boolean, DateTime, Float, Text, Enum as SAEnum, ForeignKey, Index,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class UserRole(str, enum.Enum):
    CUSTOMER = "customer"
    VENDOR = "vendor"
    DELIVERY = "delivery"
    ADMIN = "admin"


class User(Base):
    __tablename__ = "users"
    __table_args__ = (
        Index("ix_users_email", "email", unique=True),
        Index("ix_users_phone", "phone", unique=True),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20), unique=True, nullable=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        SAEnum(UserRole), default=UserRole.CUSTOMER, nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    firebase_token: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # Relationships
    addresses: Mapped[list["Address"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", lazy="selectin"
    )
    orders: Mapped[list["Order"]] = relationship(  # noqa: F821
        back_populates="customer", foreign_keys="[Order.customer_id]", lazy="selectin"
    )
    reviews: Mapped[list["Review"]] = relationship(  # noqa: F821
        back_populates="user", lazy="selectin"
    )
    wallet: Mapped["Wallet | None"] = relationship(  # noqa: F821
        back_populates="user", uselist=False, lazy="selectin"
    )


class Address(Base):
    __tablename__ = "addresses"
    __table_args__ = (
        Index("ix_addresses_user_id", "user_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    label: Mapped[str] = mapped_column(String(50), default="Home")  # Home, Work, Other
    full_address: Mapped[str] = mapped_column(Text, nullable=False)
    city: Mapped[str] = mapped_column(String(100), nullable=False)
    state: Mapped[str] = mapped_column(String(100), nullable=False)
    postal_code: Mapped[str] = mapped_column(String(20), nullable=False)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    is_default: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="addresses")
