import 'package:flutter/material.dart';

import 'package:agrochat_app/core/theme/app_colors.dart';
import 'package:agrochat_app/features/marketplace/models/marketplace_model.dart';
import 'package:agrochat_app/features/marketplace/models/rental_booking_model.dart';
import 'package:agrochat_app/features/marketplace/presentation/widgets/book_equipment_dialog.dart';
import 'package:agrochat_app/features/marketplace/presentation/widgets/checkout_dialog.dart';
import 'package:agrochat_app/features/marketplace/repositories/marketplace_repository.dart';
import 'package:agrochat_app/shared/widgets/status_feedback.dart';

/// Screen allowing Farmers to browse and buy Agricultural Products,
/// manage their Shopping Cart, place Orders, and rent Farm Machinery.
class FarmerMarketplaceScreen extends StatefulWidget {
  const FarmerMarketplaceScreen({super.key, required this.repository});

  final MarketplaceRepository repository;

  @override
  State<FarmerMarketplaceScreen> createState() =>
      _FarmerMarketplaceScreenState();
}

class _FarmerMarketplaceScreenState extends State<FarmerMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<ProductCategoryModel> _categories = [];
  List<ProductModel> _products = [];
  ShoppingCartModel? _cart;
  List<OrderModel> _orders = [];
  List<EquipmentRentalModel> _equipment = [];
  List<RentalBookingModel> _bookings = [];

  int _selectedCategoryId = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final catsFuture = widget.repository.listCategories();
      final prodsFuture = widget.repository.listProducts();
      final cartFuture = widget.repository.getCart();
      final ordersFuture = widget.repository.listMyOrders();
      final eqFuture = widget.repository.listEquipmentRentals();
      final bookingsFuture = widget.repository.listMyBookings();

      final results = await Future.wait([
        catsFuture,
        prodsFuture,
        cartFuture,
        ordersFuture,
        eqFuture,
        bookingsFuture,
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<ProductCategoryModel>;
          _products = results[1] as List<ProductModel>;
          _cart = results[2] as ShoppingCartModel;
          _orders = results[3] as List<OrderModel>;
          _equipment = results[4] as List<EquipmentRentalModel>;
          _bookings = results[5] as List<RentalBookingModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<ProductModel> get _filteredProducts {
    return _products.where((p) {
      final matchCat =
          _selectedCategoryId == 0 || p.categoryId == _selectedCategoryId;
      final matchSearch =
          _searchQuery.isEmpty ||
          p.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.brandOrManufacturer != null &&
              p.brandOrManufacturer!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  Future<void> _addToCart(ProductModel product) async {
    try {
      final updatedCart = await widget.repository.addToCart(product.id, 1);
      if (mounted) {
        setState(() => _cart = updatedCart);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.productName} added to cart!'),
            backgroundColor: AppColors.primaryGreenDark,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: AppColors.softMint,
              onPressed: () => _tabController.animateTo(2),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateCartQuantity(int productId, int quantity) async {
    try {
      final updatedCart = await widget.repository.updateCartItem(
        productId,
        quantity,
      );
      if (mounted) setState(() => _cart = updatedCart);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update cart: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removeCartItem(int productId) async {
    try {
      final updatedCart = await widget.repository.removeCartItem(productId);
      if (mounted) setState(() => _cart = updatedCart);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openCheckout() async {
    if (_cart == null || _cart!.items.isEmpty) return;

    final result = await showDialog<OrderModel>(
      context: context,
      builder: (_) =>
          CheckoutDialog(cart: _cart!, repository: widget.repository),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${result.id} placed successfully!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      _loadAllData();
    }
  }

  Future<void> _openBookEquipment(EquipmentRentalModel eq) async {
    final result = await showDialog<RentalBookingModel>(
      context: context,
      builder: (_) =>
          BookEquipmentDialog(equipment: eq, repository: widget.repository),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rental booking for ${eq.equipmentName} submitted!'),
          backgroundColor: AppColors.primaryGreenDark,
        ),
      );
      _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _cart?.totalItemsCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agricultural Marketplace'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.surfaceWhite,
                unselectedLabelColor: AppColors.surfaceWhite.withValues(alpha: 0.7),
                indicatorColor: AppColors.softMint,
                tabs: [
                  const Tab(text: 'Agri Products'),
                  const Tab(text: 'Machinery Rentals'),
                  Tab(text: 'Cart & Orders ($cartCount)'),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _isLoading
          ? const AgroLoadingView(
              message: 'Loading agricultural marketplace...',
            )
          : _errorMessage != null && _products.isEmpty
          ? AgroEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Unable to Load Marketplace',
              description: _errorMessage!,
              actionLabel: 'Retry',
              onAction: _loadAllData,
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildShopTab(),
                    _buildRentalsTab(),
                    _buildCartAndOrdersTab(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildShopTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceWhite,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search seeds, fertilizers, tools...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: _selectedCategoryId == 0,
                        label: const Text('ALL PRODUCTS'),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: _selectedCategoryId == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedCategoryId == 0
                              ? AppColors.surfaceWhite
                              : AppColors.textPrimary,
                        ),
                        backgroundColor: AppColors.background,
                        selectedColor: AppColors.primaryGreen,
                        onSelected: (_) =>
                            setState(() => _selectedCategoryId = 0),
                      ),
                    ),
                    ..._categories.map((c) {
                      final isSelected = _selectedCategoryId == c.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(c.name.toUpperCase()),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.surfaceWhite
                                : AppColors.textPrimary,
                          ),
                          backgroundColor: AppColors.background,
                          selectedColor: AppColors.primaryGreen,
                          onSelected: (_) =>
                              setState(() => _selectedCategoryId = c.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _filteredProducts.isEmpty
              ? const AgroEmptyState(
                  icon: Icons.storefront_rounded,
                  title: 'No Products Match',
                  description:
                      'Try choosing another category or clearing search terms.',
                )
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = _filteredProducts[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.softMint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_rounded,
                                  color: AppColors.primaryGreenDark,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (p.brandOrManufacturer != null)
                                      Text(
                                        p.brandOrManufacturer!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    Text(
                                      p.productName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Rs. ${p.priceInr.toStringAsFixed(2)} / ${p.unit}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.primaryGreen,
                                            foregroundColor:
                                                AppColors.surfaceWhite,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: p.stockQuantity > 0
                                              ? () => _addToCart(p)
                                              : null,
                                          icon: const Icon(
                                            Icons.add_shopping_cart_rounded,
                                            size: 16,
                                          ),
                                          label: Text(
                                            p.stockQuantity > 0
                                                ? 'Add'
                                                : 'Out of Stock',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRentalsTab() {
    return Column(
      children: [
        if (_bookings.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.softMint.withValues(alpha: 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Active Machinery Bookings (${_bookings.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAllData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_bookings.isNotEmpty) ...[
                  ..._bookings.map(_buildBookingCard),
                  const SizedBox(height: 16),
                  const Text(
                    'Available Agricultural Equipment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                ..._equipment.map((eq) {
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.softMint,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  eq.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreenDark,
                                  ),
                                ),
                              ),
                              Text(
                                '${eq.district}, ${eq.state}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            eq.equipmentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            eq.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rs. ${eq.dailyRateInr.toStringAsFixed(0)} / Day',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  Text(
                                    'Provider: ${eq.providerName}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: AppColors.surfaceWhite,
                                ),
                                onPressed: () => _openBookEquipment(eq),
                                icon: const Icon(
                                  Icons.event_available_rounded,
                                  size: 16,
                                ),
                                label: const Text('Book Now'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(RentalBookingModel booking) {
    final status = booking.bookingStatus.toLowerCase();
    Color statusColor;
    if (status == 'confirmed') {
      statusColor = AppColors.primaryGreen;
    } else if (status == 'pending') {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.textSecondary;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.equipmentName ?? 'Equipment #${booking.equipmentId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.bookingStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Rental Period: ${booking.startDate} to ${booking.endDate} (${booking.durationUnits} ${booking.rentalType})',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Total Cost: Rs. ${booking.totalCostInr.toStringAsFixed(2)} | Delivery: ${booking.deliveryLocation}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
            if (booking.providerResponse != null &&
                booking.providerResponse!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.softMint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Custom Hiring Center: ${booking.providerResponse}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCartAndOrdersTab() {
    final items = _cart?.items ?? [];

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shopping Cart Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Shopping Cart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (items.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Clear',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onPressed: () async {
                    await widget.repository.clearCart();
                    _loadAllData();
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (items.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.remove_shopping_cart_rounded,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your shopping cart is empty',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Browse products in the Agri Shop to add fertilizers, seeds, and tools.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            ...items.map((item) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.productName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs. ${item.product.priceInr.toStringAsFixed(2)} x ${item.quantity} = Rs. ${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                            ),
                            onPressed: item.quantity > 1
                                ? () => _updateCartQuantity(
                                    item.productId,
                                    item.quantity - 1,
                                  )
                                : () => _removeCartItem(item.productId),
                          ),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            onPressed: () => _updateCartQuantity(
                              item.productId,
                              item.quantity + 1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.error,
                            ),
                            onPressed: () => _removeCartItem(item.productId),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softMint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable Amount:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rs. ${_cart!.totalAmountInr.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreenDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.surfaceWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _openCheckout,
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: const Text('Proceed to Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Text(
            'Order History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          if (_orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No past orders placed yet.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            ..._orders.map((o) {
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${o.id}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              o.orderStatus.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreenDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total: Rs. ${o.totalAmountInr.toStringAsFixed(2)} | Payment: ${o.paymentMethod.replaceAll('_', ' ').toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Delivery: ${o.deliveryAddress}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (o.items.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Items: ${o.items.map((i) => '${i.productName} (x${i.quantity})').join(', ')}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
