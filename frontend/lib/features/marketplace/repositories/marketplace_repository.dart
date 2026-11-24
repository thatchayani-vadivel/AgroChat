import 'package:agrochat_app/core/constants/api_endpoints.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/features/marketplace/models/marketplace_model.dart';
import 'package:agrochat_app/features/marketplace/models/rental_booking_model.dart';

/// Repository for Marketplace Products, Shopping Cart, Orders, and Equipment Rentals.
class MarketplaceRepository {
  MarketplaceRepository({ApiClient? apiClient, required this.token})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final String token;

  // ==================== CATEGORIES & PRODUCTS ====================

  Future<List<ProductCategoryModel>> listCategories() async {
    final response = await _apiClient.get(
      ApiEndpoints.marketplaceCategories,
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map(
            (item) =>
                ProductCategoryModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<List<ProductModel>> listProducts({
    int? categoryId,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (categoryId != null && categoryId > 0) {
      queryParams['category_id'] = categoryId.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final query = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await _apiClient.get(
      '${ApiEndpoints.marketplaceProducts}$query',
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ProductModel> getProductDetails(int id) async {
    final response = await _apiClient.get(
      ApiEndpoints.marketplaceProductDetails(id),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return ProductModel.fromJson(response);
    }
    throw const FormatException('Unexpected response from product details');
  }

  // ==================== SHOPPING CART ====================

  Future<ShoppingCartModel> getCart() async {
    final response = await _apiClient.get(
      ApiEndpoints.marketplaceCart,
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return ShoppingCartModel.fromJson(response);
    }
    throw const FormatException('Unexpected response from cart API');
  }

  Future<ShoppingCartModel> addToCart(int productId, int quantity) async {
    final response = await _apiClient.post(
      ApiEndpoints.marketplaceCartItems,
      body: {'product_id': productId, 'quantity': quantity},
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return ShoppingCartModel.fromJson(response);
    }
    throw const FormatException('Unexpected response adding item to cart');
  }

  Future<ShoppingCartModel> updateCartItem(int productId, int quantity) async {
    final response = await _apiClient.put(
      ApiEndpoints.marketplaceCartItemDetail(productId),
      body: {'product_id': productId, 'quantity': quantity},
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return ShoppingCartModel.fromJson(response);
    }
    throw const FormatException('Unexpected response updating cart item');
  }

  Future<ShoppingCartModel> removeCartItem(int productId) async {
    final response = await _apiClient.delete(
      ApiEndpoints.marketplaceCartItemDetail(productId),
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return ShoppingCartModel.fromJson(response);
    }
    throw const FormatException('Unexpected response removing cart item');
  }

  Future<ShoppingCartModel> clearCart() async {
    final response = await _apiClient.delete(
      ApiEndpoints.marketplaceCart,
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return ShoppingCartModel.fromJson(response);
    }
    throw const FormatException('Unexpected response clearing cart');
  }

  // ==================== ORDERS ====================

  Future<OrderModel> checkoutOrder({
    required String deliveryAddress,
    required String contactPhone,
    String paymentMethod = 'cash_on_delivery',
    String? notes,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.marketplaceOrders,
      body: {
        'delivery_address': deliveryAddress,
        'contact_phone': contactPhone,
        'payment_method': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return OrderModel.fromJson(response);
    }
    throw const FormatException('Unexpected response during checkout');
  }

  Future<List<OrderModel>> listMyOrders() async {
    final response = await _apiClient.get(
      ApiEndpoints.myMarketplaceOrders,
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ==================== EQUIPMENT RENTALS ====================

  Future<List<EquipmentRentalModel>> listEquipmentRentals({
    String? category,
    String? district,
  }) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (district != null && district.isNotEmpty) {
      queryParams['district'] = district;
    }

    final query = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    final response = await _apiClient.get(
      '${ApiEndpoints.equipmentRentals}$query',
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map(
            (item) =>
                EquipmentRentalModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  Future<RentalBookingModel> bookEquipment(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.equipmentBookings,
      body: payload,
      token: token,
    );
    if (response is Map<String, dynamic>) {
      return RentalBookingModel.fromJson(response);
    }
    throw const FormatException('Unexpected response booking equipment');
  }

  Future<List<RentalBookingModel>> listMyBookings() async {
    final response = await _apiClient.get(
      ApiEndpoints.myEquipmentBookings,
      token: token,
    );
    if (response is List<dynamic>) {
      return response
          .map(
            (item) => RentalBookingModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }
}
