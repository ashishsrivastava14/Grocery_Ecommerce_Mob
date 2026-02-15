"""Payment, Wallet, WalletTransaction, VendorPayout models."""
import uuid
from datetime import datetime
from sqlalchemy import (
    String, DateTime, Float, Text, Enum as SAEnum, ForeignKey, Index,
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
import enum


class PaymentMethod(str, enum.Enum):
    STRIPE = "stripe"
    RAZORPAY = "razorpay"
    WALLET = "wallet"
    COD = "cod"


class TransactionType(str, enum.Enum):
    CREDIT = "credit"
    DEBIT = "debit"
    REFUND = "refund"
    CASHBACK = "cashback"


class PayoutStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class Payment(Base):
    __tablename__ = "payments"
    __table_args__ = (
        Index("ix_payments_order_id", "order_id"),
        Index("ix_payments_transaction_id", "transaction_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    order_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("orders.id", ondelete="CASCADE"), nullable=False
    )
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    currency: Mapped[str] = mapped_column(String(10), default="INR")
    payment_method: Mapped[PaymentMethod] = mapped_column(
        SAEnum(PaymentMethod), nullable=False
    )
    transaction_id: Mapped[str | None] = mapped_column(String(200), nullable=True)
    gateway_response: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    status: Mapped[str] = mapped_column(String(30), default="pending")
    paid_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    order: Mapped["Order"] = relationship(back_populates="payment")  # noqa: F821


class Wallet(Base):
    __tablename__ = "wallets"
    __table_args__ = (
        Index("ix_wallets_user_id", "user_id", unique=True),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"),
        unique=True, nullable=False,
    )
    balance: Mapped[float] = mapped_column(Float, default=0.0)
    currency: Mapped[str] = mapped_column(String(10), default="INR")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    user: Mapped["User"] = relationship(back_populates="wallet")  # noqa: F821
    transactions: Mapped[list["WalletTransaction"]] = relationship(
        back_populates="wallet", cascade="all, delete-orphan", lazy="selectin"
    )


class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"
    __table_args__ = (
        Index("ix_wallet_transactions_wallet_id", "wallet_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    wallet_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wallets.id", ondelete="CASCADE"), nullable=False
    )
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    transaction_type: Mapped[TransactionType] = mapped_column(
        SAEnum(TransactionType), nullable=False
    )
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    reference_id: Mapped[str | None] = mapped_column(String(200), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    wallet: Mapped["Wallet"] = relationship(back_populates="transactions")


class VendorPayout(Base):
    __tablename__ = "vendor_payouts"
    __table_args__ = (
        Index("ix_vendor_payouts_vendor_id", "vendor_id"),
        Index("ix_vendor_payouts_status", "status"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    vendor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vendors.id"), nullable=False
    )
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    commission_deducted: Mapped[float] = mapped_column(Float, default=0.0)
    net_amount: Mapped[float] = mapped_column(Float, nullable=False)
    status: Mapped[PayoutStatus] = mapped_column(
        SAEnum(PayoutStatus), default=PayoutStatus.PENDING, nullable=False
    )
    payout_reference: Mapped[str | None] = mapped_column(String(200), nullable=True)
    period_start: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    period_end: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    processed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=datetime.utcnow
    )

    vendor: Mapped["Vendor"] = relationship(lazy="selectin")  # noqa: F821
