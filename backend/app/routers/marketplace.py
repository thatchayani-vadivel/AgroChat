"""REST endpoints for Farmer Agricultural Marketplace, Products, Carts, and Orders."""

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_farmer, get_current_officer, get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.marketplace import (
    CartItemPayload,
    OrderCreate,
    OrderResponse,
    OrderStatusUpdate,
    ProductCategoryResponse,
    ProductResponse,
    ShoppingCartResponse,
)
from app.services.marketplace_service import (
    add_or_update_cart_item,
    build_cart_response,
    clear_farmer_cart,
    get_or_create_farmer_cart,
    get_order_details,
    get_product_details,
    list_farmer_orders,
    list_product_categories,
    list_products,
    place_order_from_cart,
    remove_cart_item,
    update_order_status_by_officer,
)

router = APIRouter(prefix="/api/marketplace", tags=["Agricultural Marketplace"])


# ==================== PRODUCT CATALOG ====================

@router.get(
    "/categories",
    response_model=list[ProductCategoryResponse],
    status_code=status.HTTP_200_OK,
    summary="List Product Categories",
    description="Browse categories (Seeds, Fertilizers, Organic Manure, Tools, Feed).",
)
def read_categories(
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ProductCategoryResponse]:
    categories = list_product_categories(db)
    return [ProductCategoryResponse.model_validate(c) for c in categories]


@router.get(
    "/products",
    response_model=list[ProductResponse],
    status_code=status.HTTP_200_OK,
    summary="Browse Agricultural Products",
    description="Filter supplies by category, search keywords, or availability.",
)
def read_products(
    category_id: int | None = Query(default=None),
    search: str | None = Query(default=None),
    available_only: bool = Query(default=True),
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[ProductResponse]:
    products = list_products(
        db=db,
        category_id=category_id,
        search=search,
        available_only=available_only,
    )
    return [ProductResponse.model_validate(p) for p in products]


@router.get(
    "/products/{product_id}",
    response_model=ProductResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Product Details",
    description="View description, price, unit, and availability of an agricultural product.",
)
def read_product_detail(
    product_id: int,
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ProductResponse:
    product = get_product_details(db, product_id)
    return ProductResponse.model_validate(product)


# ==================== SHOPPING CART ====================

@router.get(
    "/cart",
    response_model=ShoppingCartResponse,
    status_code=status.HTTP_200_OK,
    summary="View Shopping Cart (Farmer)",
    description="Return the current items and total amount in the Farmer's cart.",
)
def read_my_cart(
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> ShoppingCartResponse:
    cart = get_or_create_farmer_cart(db, current_farmer)
    return build_cart_response(cart)


@router.post(
    "/cart/items",
    response_model=ShoppingCartResponse,
    status_code=status.HTTP_200_OK,
    summary="Add / Update Cart Item (Farmer)",
    description="Add an agricultural supply item to cart or update its quantity.",
)
def modify_cart_item(
    payload: CartItemPayload,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> ShoppingCartResponse:
    return add_or_update_cart_item(db, current_farmer, payload)


@router.delete(
    "/cart/items/{product_id}",
    response_model=ShoppingCartResponse,
    status_code=status.HTTP_200_OK,
    summary="Remove Item From Cart (Farmer)",
    description="Remove a product from the Farmer's shopping cart.",
)
def delete_cart_item(
    product_id: int,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> ShoppingCartResponse:
    return remove_cart_item(db, current_farmer, product_id)


@router.delete(
    "/cart",
    response_model=ShoppingCartResponse,
    status_code=status.HTTP_200_OK,
    summary="Clear Cart (Farmer)",
    description="Remove all items from the Farmer's shopping cart.",
)
def empty_my_cart(
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> ShoppingCartResponse:
    return clear_farmer_cart(db, current_farmer)


# ==================== ORDERS ====================

@router.post(
    "/orders",
    response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Place Order (Farmer)",
    description="Place an order from items in the Farmer's shopping cart.",
)
def checkout_cart(
    payload: OrderCreate,
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> OrderResponse:
    order = place_order_from_cart(db, current_farmer, payload)
    return OrderResponse.model_validate(order)


@router.get(
    "/orders/my",
    response_model=list[OrderResponse],
    status_code=status.HTTP_200_OK,
    summary="Track My Orders (Farmer)",
    description="List all orders placed by the authenticated Farmer.",
)
def read_my_orders(
    current_farmer: User = Depends(get_current_farmer),
    db: Session = Depends(get_db),
) -> list[OrderResponse]:
    orders = list_farmer_orders(db, current_farmer)
    return [OrderResponse.model_validate(o) for o in orders]


@router.get(
    "/orders/{order_id}",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Order Details",
    description="View items, delivery address, and status of an order.",
)
def read_order_detail(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> OrderResponse:
    order = get_order_details(db, order_id, current_user)
    return OrderResponse.model_validate(order)


@router.patch(
    "/orders/{order_id}/status",
    response_model=OrderResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Order Status (Officer)",
    description="Update delivery or payment status of an agricultural supplies order.",
)
def update_order_status(
    order_id: int,
    payload: OrderStatusUpdate,
    current_officer: User = Depends(get_current_officer),
    db: Session = Depends(get_db),
) -> OrderResponse:
    order = update_order_status_by_officer(db, order_id, current_officer, payload)
    return OrderResponse.model_validate(order)
