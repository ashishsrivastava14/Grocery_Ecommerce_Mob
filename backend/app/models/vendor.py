"""Vendor, KYC documents, and store timings models."""
import uuid
from datetime import datetime, time
from sqlalchemy import (
    String, Boolean, DateTime, Float, Text, Enum as SAEnum,
    ForeignKey, Index, Time, Integer,
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class VendorStatus(str, enum.Enum):
    PENDING = "pending"
    UNDER_REVIEW = "under_review"
    APPROVED = "approved"
    REJECTED = "rejected"
    SUSPENDED = "suspended"


class Vendor(Base):
    __tablename__ = "vendors"
    __table_args__ = (
        Index("ix_vendors_user_id", "user_id", unique=True),
        Index("ix_vendors_status", "status"),
        Index("ix_vendors_location", "latitude", "longitude"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"),
        unique=True, nullable=False,
    )
    store_name: Mapped[str] = mapped_column(String(200), nullable=False)
    store_description: Mapped[str | None] = mapped_column(Text, nullable=True)
    store_logo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    store_banner_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Location
    address: Mapped[str] = mapped_column(Text, nullable=False)
    city: Mapped[str] = mapped_column(String(100), nullable=False)
    state: Mapped[str] = mapped_column(String(100), nullable=False)
    postal_code: Mapped[str] = mapped_column(String(20), nullable=False)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    delivery_radius_km: Mapped[float] = mapped_column(Float, default=10.0)

    # Business
    gstin: Mapped[str | None] = mapped_column(String(20), nullable=True)
    pan_number: Mapped[str | None] = mapped_column(String(15), nullable=True)
    fssai_license: Mapped[str | None] = mapped_column(String(20), nullable=True)
    bank_account_number: Mapped[str | None] = mapped_column(String(30), nullable=True)
    bank_ifsc: Mapped[str | None] = mapped_column(String(15), nullable=True)
    bank_name: Mapped[str | None] = mapped_column(String(100), nullable=True)

    # Commission & Status
    commission_rate: Mapped[float] = mapped_column(Float, default=10.0)
    status: Mapped[VendorStatus] = mapped_column(
        SAEnum(VendorStatus), default=VendorStatus.PENDING, nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=False)
    rating: Mapped[float] = mapped_column(Float, default=0.0)
    total_orders: Mapped[int] = mapped_column(Integer, default=0)

    # Metadata
    metadata_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow
    )

    # Relationships
    user: Mapped["User"] = relationship(lazy="selectin")  # noqa: F821
    documents: Mapped[list["VendorDocument"]] = relationship(
        back_populates="vendor", cascade="all, delete-orphan", lazy="selectin"
    )
    store_timings: Mapped[list["StoreTimings"]] = relationship(
        back_populates="vendor", cascade="all, delete-orphan", lazy="selectin"
    )
    products: Mapped[list["Product"]] = relationship(  # noqa: F821
        back_populates="vendor", lazy="selectin"
    )


class VendorDocument(Base):
    __tablename__ = "vendor_documents"
    __table_args__ = (
        Index("ix_vendor_documents_vendor_id", "vendor_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    vendor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id", ondelete="CASCADE"), nullable=False
    )
    document_type: Mapped[str] = mapped_column(String(50), nullable=False)
    document_url: Mapped[str] = mapped_column(String(500), nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    vendor: Mapped["Vendor"] = relationship(back_populates="documents")


class StoreTimings(Base):
    __tablename__ = "store_timings"
    __table_args__ = (
        Index("ix_store_timings_vendor_id", "vendor_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    vendor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id", ondelete="CASCADE"), nullable=False
    )
    day_of_week: Mapped[int] = mapped_column(Integer, nullable=False)  # 0=Mon,6=Sun
    open_time: Mapped[time] = mapped_column(Time, nullable=False)
    close_time: Mapped[time] = mapped_column(Time, nullable=False)
    is_closed: Mapped[bool] = mapped_column(Boolean, default=False)

    vendor: Mapped["Vendor"] = relationship(back_populates="store_timings")
