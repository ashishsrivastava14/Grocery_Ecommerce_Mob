"""Utility helper functions."""
import re
import uuid
from datetime import datetime
from typing import Optional


def slugify(text: str) -> str:
    """Convert text to URL-friendly slug."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    text = re.sub(r"^-+|-+$", "", text)
    return text


def generate_sku(vendor_prefix: str, category_prefix: str) -> str:
    """Generate a unique SKU."""
    rand = uuid.uuid4().hex[:6].upper()
    return f"{vendor_prefix}-{category_prefix}-{rand}"


def format_currency(amount: float, currency: str = "INR") -> str:
    """Format amount as currency string."""
    symbols = {"INR": "₹", "USD": "$", "EUR": "€", "GBP": "£"}
    symbol = symbols.get(currency, currency)
    return f"{symbol}{amount:,.2f}"


def calculate_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two coordinates using Haversine formula."""
    import math
    R = 6371  # Earth's radius in km

    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def mask_email(email: str) -> str:
    """Mask email for privacy: john@example.com → j***@example.com."""
    local, domain = email.split("@")
    if len(local) <= 1:
        return f"{local}***@{domain}"
    return f"{local[0]}{'*' * (len(local) - 1)}@{domain}"


def mask_phone(phone: str) -> str:
    """Mask phone for privacy: +919876543210 → +91****3210."""
    if len(phone) <= 4:
        return phone
    return phone[:3] + "*" * (len(phone) - 7) + phone[-4:]
