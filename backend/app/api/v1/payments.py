"""Payment endpoints: create payment, wallet, payouts."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, UserRole
from app.models.order import Order, PaymentStatus
from app.models.payment import (
    Payment, Wallet, WalletTransaction, VendorPayout,
    PaymentMethod, TransactionType,
)
from app.models.vendor import Vendor
from app.schemas.payment import (
    CreatePaymentRequest, PaymentResponse,
    WalletResponse, WalletTransactionResponse, AddMoneyRequest,
    VendorPayoutResponse,
)
from app.schemas.base import ResponseBase

router = APIRouter(prefix="/payments", tags=["Payments"])


@router.post("/initiate", response_model=ResponseBase[PaymentResponse])
async def initiate_payment(
    data: CreatePaymentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Initiate a payment for an order."""
    result = await db.execute(
        select(Order).where(
            Order.id == data.order_id, Order.customer_id == current_user.id
        )
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    if order.payment_status == PaymentStatus.PAID:
        raise HTTPException(status_code=400, detail="Order already paid")

    payment = Payment(
        order_id=order.id,
        amount=data.amount,
        payment_method=data.payment_method,
        status="initiated",
    )
    db.add(payment)

    # If wallet payment
    if data.payment_method == PaymentMethod.WALLET:
        wallet_result = await db.execute(
            select(Wallet).where(Wallet.user_id == current_user.id)
        )
        wallet = wallet_result.scalar_one_or_none()
        if not wallet or wallet.balance < data.amount:
            raise HTTPException(status_code=400, detail="Insufficient wallet balance")

        wallet.balance -= data.amount
        payment.status = "completed"
        order.payment_status = PaymentStatus.PAID

        txn = WalletTransaction(
            wallet_id=wallet.id,
            amount=data.amount,
            transaction_type=TransactionType.DEBIT,
            description=f"Payment for order {order.order_number}",
            reference_id=str(order.id),
        )
        db.add(txn)

    await db.flush()
    return ResponseBase(data=PaymentResponse.model_validate(payment))


@router.post("/webhook/stripe")
async def stripe_webhook(db: AsyncSession = Depends(get_db)):
    """Handle Stripe payment webhooks (placeholder)."""
    # In production, verify stripe signature and process event
    return {"status": "received"}


@router.post("/webhook/razorpay")
async def razorpay_webhook(db: AsyncSession = Depends(get_db)):
    """Handle Razorpay payment webhooks (placeholder)."""
    return {"status": "received"}


# --- Wallet ---
@router.get("/wallet", response_model=ResponseBase[WalletResponse])
async def get_wallet(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get wallet balance."""
    result = await db.execute(
        select(Wallet).where(Wallet.user_id == current_user.id)
    )
    wallet = result.scalar_one_or_none()
    if not wallet:
        wallet = Wallet(user_id=current_user.id, balance=0.0)
        db.add(wallet)
        await db.flush()

    return ResponseBase(data=WalletResponse.model_validate(wallet))


@router.get("/wallet/transactions", response_model=ResponseBase[list[WalletTransactionResponse]])
async def get_wallet_transactions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get wallet transaction history."""
    wallet_result = await db.execute(
        select(Wallet).where(Wallet.user_id == current_user.id)
    )
    wallet = wallet_result.scalar_one_or_none()
    if not wallet:
        return ResponseBase(data=[])

    result = await db.execute(
        select(WalletTransaction)
        .where(WalletTransaction.wallet_id == wallet.id)
        .order_by(WalletTransaction.created_at.desc())
        .limit(50)
    )
    transactions = result.scalars().all()
    return ResponseBase(
        data=[WalletTransactionResponse.model_validate(t) for t in transactions]
    )


@router.post("/wallet/add-money", response_model=ResponseBase[WalletResponse])
async def add_money_to_wallet(
    data: AddMoneyRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Add money to wallet (mock - in production would integrate with payment gateway)."""
    wallet_result = await db.execute(
        select(Wallet).where(Wallet.user_id == current_user.id)
    )
    wallet = wallet_result.scalar_one_or_none()
    if not wallet:
        wallet = Wallet(user_id=current_user.id, balance=0.0)
        db.add(wallet)
        await db.flush()

    wallet.balance += data.amount

    txn = WalletTransaction(
        wallet_id=wallet.id,
        amount=data.amount,
        transaction_type=TransactionType.CREDIT,
        description="Added money to wallet",
    )
    db.add(txn)
    await db.flush()

    return ResponseBase(data=WalletResponse.model_validate(wallet))
