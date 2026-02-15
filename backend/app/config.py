"""Application configuration using Pydantic settings."""
from typing import Optional
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # App
    APP_NAME: str = "GroceryeCommerce"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"
    API_V1_PREFIX: str = "/api/v1"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@db:5432/grocery_ecommerce"
    DATABASE_ECHO: bool = False

    # Redis
    REDIS_URL: str = "redis://redis:6379/0"

    # Auth / JWT
    SECRET_KEY: str = "change-this-to-a-super-secret-key-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # CORS
    CORS_ORIGINS: list[str] = ["*"]

    # File Upload
    MAX_FILE_SIZE: int = 5_242_880  # 5MB
    UPLOAD_DIR: str = "uploads"

    # Payment
    STRIPE_SECRET_KEY: Optional[str] = None
    STRIPE_WEBHOOK_SECRET: Optional[str] = None
    RAZORPAY_KEY_ID: Optional[str] = None
    RAZORPAY_KEY_SECRET: Optional[str] = None

    # Email / Notifications
    SMTP_HOST: Optional[str] = None
    SMTP_PORT: int = 587
    SMTP_USER: Optional[str] = None
    SMTP_PASSWORD: Optional[str] = None
    FROM_EMAIL: str = "noreply@groceryecommerce.com"

    # Firebase (push notifications)
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None

    # Commission
    DEFAULT_COMMISSION_RATE: float = 10.0  # percentage

    # Delivery
    DEFAULT_DELIVERY_RADIUS_KM: float = 10.0
    FREE_DELIVERY_THRESHOLD: float = 500.0
    DELIVERY_FEE: float = 40.0

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()
