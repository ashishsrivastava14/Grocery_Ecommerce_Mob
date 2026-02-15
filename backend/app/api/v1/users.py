"""User profile and address endpoints."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from uuid import UUID

from app.database import get_db
from app.api.deps import get_current_user
from app.models.user import User, Address
from app.core.security import hash_password, verify_password
from app.schemas.user import (
    UserResponse, UserUpdate, ChangePasswordRequest,
    AddressCreate, AddressUpdate, AddressResponse,
)
from app.schemas.base import ResponseBase

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=ResponseBase[UserResponse])
async def get_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile."""
    return ResponseBase(data=UserResponse.model_validate(current_user))


@router.put("/me", response_model=ResponseBase[UserResponse])
async def update_profile(
    data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update current user profile."""
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(current_user, key, value)
    await db.flush()
    return ResponseBase(data=UserResponse.model_validate(current_user))


@router.post("/me/change-password", response_model=ResponseBase)
async def change_password(
    data: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Change user password."""
    if not verify_password(data.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect",
        )
    current_user.hashed_password = hash_password(data.new_password)
    await db.flush()
    return ResponseBase(message="Password changed successfully")


# --- Addresses ---
@router.get("/me/addresses", response_model=ResponseBase[list[AddressResponse]])
async def get_addresses(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all addresses for current user."""
    result = await db.execute(
        select(Address).where(Address.user_id == current_user.id)
    )
    addresses = result.scalars().all()
    return ResponseBase(
        data=[AddressResponse.model_validate(a) for a in addresses]
    )


@router.post("/me/addresses", response_model=ResponseBase[AddressResponse], status_code=201)
async def create_address(
    data: AddressCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Add a new delivery address."""
    if data.is_default:
        # Reset other defaults
        result = await db.execute(
            select(Address).where(
                Address.user_id == current_user.id, Address.is_default == True
            )
        )
        for addr in result.scalars().all():
            addr.is_default = False

    address = Address(user_id=current_user.id, **data.model_dump())
    db.add(address)
    await db.flush()
    return ResponseBase(data=AddressResponse.model_validate(address))


@router.put("/me/addresses/{address_id}", response_model=ResponseBase[AddressResponse])
async def update_address(
    address_id: UUID,
    data: AddressUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update existing address."""
    result = await db.execute(
        select(Address).where(
            Address.id == address_id, Address.user_id == current_user.id
        )
    )
    address = result.scalar_one_or_none()
    if not address:
        raise HTTPException(status_code=404, detail="Address not found")

    update_data = data.model_dump(exclude_unset=True)
    if update_data.get("is_default"):
        # Reset other defaults
        res = await db.execute(
            select(Address).where(
                Address.user_id == current_user.id, Address.is_default == True
            )
        )
        for addr in res.scalars().all():
            addr.is_default = False

    for key, value in update_data.items():
        setattr(address, key, value)
    await db.flush()
    return ResponseBase(data=AddressResponse.model_validate(address))


@router.delete("/me/addresses/{address_id}", response_model=ResponseBase)
async def delete_address(
    address_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete an address."""
    result = await db.execute(
        select(Address).where(
            Address.id == address_id, Address.user_id == current_user.id
        )
    )
    address = result.scalar_one_or_none()
    if not address:
        raise HTTPException(status_code=404, detail="Address not found")

    await db.delete(address)
    await db.flush()
    return ResponseBase(message="Address deleted")
