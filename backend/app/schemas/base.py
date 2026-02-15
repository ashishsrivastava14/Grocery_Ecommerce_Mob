"""Shared base schemas."""
from pydantic import BaseModel
from typing import Optional, Generic, TypeVar
from uuid import UUID
from datetime import datetime

T = TypeVar("T")


class ResponseBase(BaseModel, Generic[T]):
    success: bool = True
    message: str = "Success"
    data: Optional[T] = None


class PaginatedResponse(BaseModel, Generic[T]):
    success: bool = True
    data: list[T] = []
    total: int = 0
    page: int = 1
    page_size: int = 20
    total_pages: int = 0


class TimestampMixin(BaseModel):
    created_at: datetime | None = None
    updated_at: datetime | None = None

    class Config:
        from_attributes = True
