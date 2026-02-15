"""Review schemas."""
from pydantic import BaseModel, Field
from typing import Optional
from uuid import UUID
from datetime import datetime


class ReviewCreate(BaseModel):
    product_id: UUID
    order_id: Optional[UUID] = None
    rating: float = Field(..., ge=1, le=5)
    title: Optional[str] = Field(None, max_length=200)
    comment: Optional[str] = None


class ReviewUpdate(BaseModel):
    rating: Optional[float] = Field(None, ge=1, le=5)
    title: Optional[str] = None
    comment: Optional[str] = None


class ReviewResponse(BaseModel):
    id: UUID
    user_id: UUID
    product_id: UUID
    vendor_id: UUID
    order_id: Optional[UUID] = None
    rating: float
    title: Optional[str] = None
    comment: Optional[str] = None
    is_verified_purchase: bool
    helpful_count: int
    created_at: datetime
    updated_at: datetime
    user_name: Optional[str] = None  # populated from join

    class Config:
        from_attributes = True
