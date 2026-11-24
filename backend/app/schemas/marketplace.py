"""Pydantic schemas for Farmer Agricultural Marketplace, Products, Carts, and Orders."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.validators import clean_optional_text, clean_required_text


class ProductCategoryResponse(BaseModel):
    """Response schema for a product category."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: str | None
    icon_name: str | None
    created_at: datetime


class ProductResponse(BaseModel):
    """Response schema for an agricultural product."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    category_id: int
    product_name: str
    brand_or_manufacturer: str | None
    description: str
    price_inr: Decimal
    unit: str
    stock_quantity: int
    is_available: bool
    image_url: str | None
    created_at: datetime
    updated_at: datetime


class CartItemPayload(BaseModel):
    """Payload to add or update an item in the farmer's shopping cart."""

    product_id: int = Field(..., ge=1)
    quantity: int = Field(default=1, ge=1, le=1000)


class CartItemResponse(BaseModel):
    """Response schema for a single cart item."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    cart_id: int
    product_id: int
    quantity: int
    created_at: datetime
    product: ProductResponse


class ShoppingCartResponse(BaseModel):
    """Response schema for a farmer's shopping cart including line items and total."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    farmer_id: int
    total_amount_inr: Decimal = Decimal("0.00")
    total_items_count: int = 0
    items: list[CartItemResponse] = []


class OrderCreate(BaseModel):
    """Payload for placing an order from the farmer's current cart."""

    delivery_address: str = Field(..., min_length=5, max_length=1000)
    contact_phone: str = Field(..., min_length=10, max_length=20)
    payment_method: str = Field(default="cash_on_delivery", max_length=50)
    notes: str | None = Field(default=None, max_length=1000)

    @field_validator("delivery_address", "contact_phone")
    @classmethod
    def validate_required(cls, value: str) -> str:
        return clean_required_text(value, min_length=5)

    @field_validator("notes")
    @classmethod
    def normalize_optional(cls, value: str | None) -> str | None:
        return clean_optional_text(value)


class OrderItemResponse(BaseModel):
    """Response schema for an item inside a placed order."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    order_id: int
    product_id: int
    product_name: str
    unit_price_inr: Decimal
    quantity: int
    total_price_inr: Decimal
    created_at: datetime


class OrderResponse(BaseModel):
    """Response schema for an order."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    order_number: str
    farmer_id: int
    total_amount_inr: Decimal
    delivery_address: str
    contact_phone: str
    order_status: str
    payment_method: str
    payment_status: str
    notes: str | None
    created_at: datetime
    updated_at: datetime
    items: list[OrderItemResponse] = []


class OrderStatusUpdate(BaseModel):
    """Payload to update order delivery/payment status."""

    order_status: str | None = Field(default=None, max_length=50)
    payment_status: str | None = Field(default=None, max_length=50)
