"""Vendor schemas."""
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime, time
from app.models.vendor import VendorStatus


class VendorRegisterRequest(BaseModel):
    store_name: str = Field(..., min_length=2, max_length=200)
    store_description: Optional[str] = None
    address: str
    city: str
    state: str
    postal_code: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    delivery_radius_km: float = 10.0
    gstin: Optional[str] = None
    pan_number: Optional[str] = None
    fssai_license: Optional[str] = None
    bank_account_number: Optional[str] = None
    bank_ifsc: Optional[str] = None
    bank_name: Optional[str] = None


class VendorUpdate(BaseModel):
    store_name: Optional[str] = Field(None, min_length=2, max_length=200)
    store_description: Optional[str] = None
    store_logo_url: Optional[str] = None
    store_banner_url: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    postal_code: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    delivery_radius_km: Optional[float] = None


class VendorResponse(BaseModel):
    id: UUID
    user_id: UUID
    store_name: str
    store_description: Optional[str] = None
    store_logo_url: Optional[str] = None
    store_banner_url: Optional[str] = None
    address: str
    city: str
    state: str
    postal_code: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    delivery_radius_km: float
    commission_rate: float
    status: VendorStatus
    is_active: bool
    rating: float
    total_orders: int
    created_at: datetime

    class Config:
        from_attributes = True


class VendorAdminUpdate(BaseModel):
    status: Optional[VendorStatus] = None
    commission_rate: Optional[float] = None
    is_active: Optional[bool] = None


class StoreTimingsCreate(BaseModel):
    day_of_week: int = Field(..., ge=0, le=6)
    open_time: time
    close_time: time
    is_closed: bool = False


class StoreTimingsResponse(BaseModel):
    id: UUID
    day_of_week: int
    open_time: time
    close_time: time
    is_closed: bool

    class Config:
        from_attributes = True


class VendorDashboardStats(BaseModel):
    total_orders: int = 0
    pending_orders: int = 0
    total_revenue: float = 0.0
    total_products: int = 0
    avg_rating: float = 0.0
    daily_orders: list = []
    top_products: list = []
