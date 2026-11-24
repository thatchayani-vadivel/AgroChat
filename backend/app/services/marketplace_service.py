"""Business logic for Agricultural Marketplace: Categories, Products, Carts, and Orders."""

import uuid
from decimal import Decimal
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.exceptions import AuthorizationError, NotFoundError
from app.models.marketplace import (
    CartItem,
    Order,
    OrderItem,
    Product,
    ProductCategory,
    ShoppingCart,
)
from app.models.user import User
from app.schemas.marketplace import (
    CartItemPayload,
    OrderCreate,
    OrderStatusUpdate,
    ShoppingCartResponse,
)


# ==================== CATEGORIES & PRODUCTS ====================

def list_product_categories(db: Session) -> list[ProductCategory]:
    """List all agricultural product categories."""
    stmt = select(ProductCategory).order_by(ProductCategory.id.asc())
    return list(db.scalars(stmt).all())


def list_products(
    db: Session,
    category_id: int | None = None,
    search: str | None = None,
    available_only: bool = True,
) -> list[Product]:
    """List agricultural products with category and search filters."""
    stmt = select(Product)
    if category_id:
        stmt = stmt.where(Product.category_id == category_id)
    if available_only:
        stmt = stmt.where(Product.is_available.is_(True))
    if search:
        pattern = f"%{search.strip()}%"
        stmt = stmt.where(Product.product_name.ilike(pattern) | Product.description.ilike(pattern))
    stmt = stmt.order_by(Product.id.asc())
    return list(db.scalars(stmt).all())


def get_product_details(db: Session, product_id: int) -> Product:
    """Get details of a single product."""
    product = db.get(Product, product_id)
    if not product:
        raise NotFoundError("Product not found.")
    return product


# ==================== SHOPPING CART ====================

def get_or_create_farmer_cart(db: Session, current_farmer: User) -> ShoppingCart:
    """Retrieve the farmer's shopping cart or create one if it does not exist."""
    stmt = select(ShoppingCart).where(ShoppingCart.farmer_id == current_farmer.id)
    cart = db.scalar(stmt)
    if not cart:
        cart = ShoppingCart(farmer_id=current_farmer.id)
        db.add(cart)
        db.commit()
        db.refresh(cart)
    return cart


def build_cart_response(cart: ShoppingCart) -> ShoppingCartResponse:
    """Compute total amount and item count for the shopping cart response."""
    total_amount = Decimal("0.00")
    total_count = 0
    for item in cart.items:
        if item.product:
            item_total = item.product.price_inr * item.quantity
            total_amount += item_total
            total_count += item.quantity

    return ShoppingCartResponse(
        id=cart.id,
        farmer_id=cart.farmer_id,
        total_amount_inr=total_amount,
        total_items_count=total_count,
        items=list(cart.items),
    )


def add_or_update_cart_item(
    db: Session,
    current_farmer: User,
    payload: CartItemPayload,
) -> ShoppingCartResponse:
    """Add a product to the farmer's cart or update its quantity."""
    cart = get_or_create_farmer_cart(db, current_farmer)
    product = db.get(Product, payload.product_id)
    if not product or not product.is_available:
        raise NotFoundError("Product not found or currently unavailable.")

    stmt = select(CartItem).where(
        CartItem.cart_id == cart.id,
        CartItem.product_id == payload.product_id,
    )
    cart_item = db.scalar(stmt)
    if cart_item:
        cart_item.quantity = payload.quantity
    else:
        cart_item = CartItem(
            cart_id=cart.id,
            product_id=payload.product_id,
            quantity=payload.quantity,
        )
        db.add(cart_item)

    db.commit()
    db.refresh(cart)
    return build_cart_response(cart)


def remove_cart_item(db: Session, current_farmer: User, product_id: int) -> ShoppingCartResponse:
    """Remove a product from the farmer's shopping cart."""
    cart = get_or_create_farmer_cart(db, current_farmer)
    stmt = select(CartItem).where(
        CartItem.cart_id == cart.id,
        CartItem.product_id == product_id,
    )
    cart_item = db.scalar(stmt)
    if cart_item:
        db.delete(cart_item)
        db.commit()
        db.refresh(cart)
    return build_cart_response(cart)


def clear_farmer_cart(db: Session, current_farmer: User) -> ShoppingCartResponse:
    """Clear all items from the farmer's shopping cart."""
    cart = get_or_create_farmer_cart(db, current_farmer)
    for item in list(cart.items):
        db.delete(item)
    db.commit()
    db.refresh(cart)
    return build_cart_response(cart)


# ==================== ORDERS ====================

def place_order_from_cart(
    db: Session,
    current_farmer: User,
    payload: OrderCreate,
) -> Order:
    """Place an order using all items currently in the farmer's shopping cart."""
    cart = get_or_create_farmer_cart(db, current_farmer)
    if not cart.items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot place order: your shopping cart is empty.",
        )

    # Compute total and create order items
    total_amount = Decimal("0.00")
    order_items_to_add: list[OrderItem] = []

    order_num = f"ORD-{uuid.uuid4().hex[:8].upper()}"
    new_order = Order(
        order_number=order_num,
        farmer_id=current_farmer.id,
        total_amount_inr=Decimal("0.00"),
        delivery_address=payload.delivery_address,
        contact_phone=payload.contact_phone,
        order_status="confirmed",
        payment_method=payload.payment_method,
        payment_status="pending",
        notes=payload.notes,
    )
    db.add(new_order)
    db.flush()  # obtain new_order.id

    for item in cart.items:
        prod = item.product
        if not prod:
            continue
        line_total = prod.price_inr * item.quantity
        total_amount += line_total
        ord_item = OrderItem(
            order_id=new_order.id,
            product_id=prod.id,
            product_name=prod.product_name,
            unit_price_inr=prod.price_inr,
            quantity=item.quantity,
            total_price_inr=line_total,
        )
        order_items_to_add.append(ord_item)

    new_order.total_amount_inr = total_amount
    db.add_all(order_items_to_add)

    # Clear farmer's cart after order placement
    for item in list(cart.items):
        db.delete(item)

    db.commit()
    db.refresh(new_order)
    return new_order


def list_farmer_orders(db: Session, current_farmer: User) -> list[Order]:
    """List orders placed by the authenticated Farmer."""
    stmt = select(Order).where(Order.farmer_id == current_farmer.id).order_by(Order.id.desc())
    return list(db.scalars(stmt).all())


def get_order_details(db: Session, order_id: int, current_user: User) -> Order:
    """Get details of an order."""
    order = db.get(Order, order_id)
    if not order:
        raise NotFoundError("Order not found.")

    if current_user.role.value == "farmer" and order.farmer_id != current_user.id:
        raise AuthorizationError("You do not have permission to view this order.")

    return order


def update_order_status_by_officer(
    db: Session,
    order_id: int,
    _current_officer: User,
    payload: OrderStatusUpdate,
) -> Order:
    """Allow Agricultural Officer to update order delivery or payment status."""
    order = db.get(Order, order_id)
    if not order:
        raise NotFoundError("Order not found.")

    if payload.order_status:
        order.order_status = payload.order_status
    if payload.payment_status:
        order.payment_status = payload.payment_status

    db.commit()
    db.refresh(order)
    return order
