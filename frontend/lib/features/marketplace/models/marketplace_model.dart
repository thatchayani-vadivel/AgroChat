/// Models representing Agricultural Marketplace Categories, Products, Carts, and Orders.
class ProductCategoryModel {
  const ProductCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
  });

  final int id;
  final String name;
  final String? description;
  final String? iconName;

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
    );
  }
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.productName,
    this.brandOrManufacturer,
    required this.description,
    required this.priceInr,
    required this.unit,
    required this.stockQuantity,
    required this.isAvailable,
    this.imageUrl,
  });

  final int id;
  final int categoryId;
  final String productName;
  final String? brandOrManufacturer;
  final String description;
  final double priceInr;
  final String unit;
  final int stockQuantity;
  final bool isAvailable;
  final String? imageUrl;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      productName: json['product_name'] as String? ?? '',
      brandOrManufacturer: json['brand_or_manufacturer'] as String?,
      description: json['description'] as String? ?? '',
      priceInr: (json['price_inr'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'Unit',
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  final int id;
  final int cartId;
  final int productId;
  final int quantity;
  final ProductModel product;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int,
      cartId: json['cart_id'] as int,
      productId: json['product_id'] as int,
      quantity: json['quantity'] as int? ?? 1,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
    );
  }

  double get subtotal => product.priceInr * quantity;
}

class ShoppingCartModel {
  const ShoppingCartModel({
    required this.id,
    required this.farmerId,
    required this.totalAmountInr,
    required this.totalItemsCount,
    required this.items,
  });

  final int id;
  final int farmerId;
  final double totalAmountInr;
  final int totalItemsCount;
  final List<CartItemModel> items;

  factory ShoppingCartModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ShoppingCartModel(
      id: json['id'] as int? ?? 0,
      farmerId: json['farmer_id'] as int? ?? 0,
      totalAmountInr: (json['total_amount_inr'] as num?)?.toDouble() ?? 0.0,
      totalItemsCount: json['total_items_count'] as int? ?? 0,
      items: itemsList,
    );
  }
}

class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceInr,
    required this.subtotalInr,
  });

  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPriceInr;
  final double subtotalInr;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPriceInr: (json['unit_price_inr'] as num?)?.toDouble() ?? 0.0,
      subtotalInr: (json['subtotal_inr'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.farmerId,
    required this.orderStatus,
    required this.totalAmountInr,
    required this.deliveryAddress,
    required this.contactPhone,
    required this.paymentMethod,
    this.notes,
    this.createdAt,
    this.items = const [],
  });

  final int id;
  final int farmerId;
  final String orderStatus;
  final double totalAmountInr;
  final String deliveryAddress;
  final String contactPhone;
  final String paymentMethod;
  final String? notes;
  final DateTime? createdAt;
  final List<OrderItemModel> items;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return OrderModel(
      id: json['id'] as int,
      farmerId: json['farmer_id'] as int,
      orderStatus: json['order_status'] as String? ?? 'placed',
      totalAmountInr: (json['total_amount_inr'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: json['delivery_address'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'cash_on_delivery',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      items: itemsList,
    );
  }
}
