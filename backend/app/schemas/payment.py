"""Payment & wallet schemas."""
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime
from app.models.payment import PaymentMethod, TransactionType, PayoutStatus


class CreatePaymentRequest(BaseModel):
    order_id: UUID
    payment_method: PaymentMethod
    amount: float = Field(..., gt=0)


class PaymentResponse(BaseModel):
    id: UUID
    order_id: UUID
    amount: float
    currency: str
    payment_method: PaymentMethod
    transaction_id: Optional[str] = None
    status: str
    paid_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


class WalletResponse(BaseModel):
    id: UUID
    user_id: UUID
    balance: float
    currency: str
    updated_at: datetime

    class Config:
        from_attributes = True


class WalletTransactionResponse(BaseModel):
    id: UUID
    amount: float
    transaction_type: TransactionType
    description: Optional[str] = None
    reference_id: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class AddMoneyRequest(BaseModel):
    amount: float = Field(..., gt=0, le=50000)
    payment_method: PaymentMethod = PaymentMethod.STRIPE


class VendorPayoutResponse(BaseModel):
    id: UUID
    vendor_id: UUID
    amount: float
    commission_deducted: float
    net_amount: float
    status: PayoutStatus
    payout_reference: Optional[str] = None
    period_start: datetime
    period_end: datetime
    processed_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True
