"""Order schemas."""
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime
from app.models.order import OrderStatus, PaymentStatus


class CartItem(BaseModel):
    product_id: UUID
    variant_id: Optional[UUID] = None
    quantity: int = Field(..., ge=1)


class CreateOrderRequest(BaseModel):
    vendor_id: UUID
    items: list[CartItem]
    delivery_address_id: UUID
    payment_method: str = "cod"
    coupon_code: Optional[str] = None
    customer_note: Optional[str] = None


class OrderItemResponse(BaseModel):
    id: UUID
    product_id: UUID
    variant_id: Optional[UUID] = None
    product_name: str
    product_image_url: Optional[str] = None
    unit_price: float
    quantity: int
    total_price: float
    unit_type: str
    unit_value: float

    class Config:
        from_attributes = True


class OrderStatusHistoryResponse(BaseModel):
    id: UUID
    status: OrderStatus
    note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class OrderResponse(BaseModel):
    id: UUID
    order_number: str
    customer_id: UUID
    vendor_id: UUID
    delivery_partner_id: Optional[UUID] = None
    delivery_address: dict
    subtotal: float
    delivery_fee: float
    discount_amount: float
    tax_amount: float
    total_amount: float
    commission_rate: float
    commission_amount: float
    status: OrderStatus
    payment_status: PaymentStatus
    payment_method: str
    coupon_code: Optional[str] = None
    customer_note: Optional[str] = None
    estimated_delivery_time: Optional[datetime] = None
    actual_delivery_time: Optional[datetime] = None
    items: list[OrderItemResponse] = []
    status_history: list[OrderStatusHistoryResponse] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class UpdateOrderStatusRequest(BaseModel):
    status: OrderStatus
    note: Optional[str] = None


class OrderFilter(BaseModel):
    status: Optional[OrderStatus] = None
    payment_status: Optional[PaymentStatus] = None
    vendor_id: Optional[UUID] = None
    customer_id: Optional[UUID] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
    page: int = 1
    page_size: int = 20
