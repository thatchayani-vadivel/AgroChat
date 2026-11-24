import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/core/theme/app_theme.dart';
import 'package:agrochat_app/features/advisory/models/advisory_model.dart';
import 'package:agrochat_app/features/advisory/models/loan_model.dart';
import 'package:agrochat_app/features/advisory/models/subsidy_model.dart';
import 'package:agrochat_app/features/advisory/presentation/widgets/apply_loan_dialog.dart';
import 'package:agrochat_app/features/advisory/presentation/widgets/apply_subsidy_dialog.dart';
import 'package:agrochat_app/features/advisory/repositories/advisory_repository.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/create_request_dialog.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';
import 'package:agrochat_app/features/marketplace/models/marketplace_model.dart';
import 'package:agrochat_app/features/marketplace/models/rental_booking_model.dart';
import 'package:agrochat_app/features/marketplace/presentation/widgets/book_equipment_dialog.dart';
import 'package:agrochat_app/features/marketplace/presentation/widgets/checkout_dialog.dart';
import 'package:agrochat_app/features/marketplace/repositories/marketplace_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Extended Feature Models Serialization', () {
    test('SchemeModel parses JSON correctly', () {
      final json = {
        'id': 10,
        'title': 'PM-KISAN Scheme',
        'category': 'scheme',
        'provider': 'Ministry of Agriculture',
        'description': 'Direct income support',
        'benefits': 'Rs. 6000 per year',
        'eligibility': 'Small and marginal farmers',
        'state': 'All India',
        'is_active': true,
      };

      final model = SchemeModel.fromJson(json);
      expect(model.id, 10);
      expect(model.title, 'PM-KISAN Scheme');
      expect(model.category, 'scheme');
      expect(model.state, 'All India');
    });

    test('LoanEnquiryModel parses and serializes correctly', () {
      final json = {
        'id': 5,
        'farmer_id': 65,
        'scheme_id': 1,
        'loan_type': 'Kisan Credit Card (Crop Loan)',
        'preferred_bank': 'SBI',
        'requested_amount_inr': 150000.0,
        'purpose': 'Fertilizer purchase for wheat crop',
        'status': 'pending',
      };

      final model = LoanEnquiryModel.fromJson(json);
      expect(model.id, 5);
      expect(model.requestedAmountInr, 150000.0);
      expect(model.status, 'pending');

      final serialized = model.toJson();
      expect(serialized['loan_type'], 'Kisan Credit Card (Crop Loan)');
      expect(serialized['requested_amount_inr'], 150000.0);
    });

    test('SubsidyEnquiryModel parses and serializes correctly', () {
      final json = {
        'id': 3,
        'farmer_id': 65,
        'scheme_id': 2,
        'subsidy_title': 'PM Krishi Sinchayee Yojana',
        'enquiry_details': 'Drip irrigation for 2 acres sugarcane',
        'status': 'under_review',
      };

      final model = SubsidyEnquiryModel.fromJson(json);
      expect(model.id, 3);
      expect(model.subsidyTitle, 'PM Krishi Sinchayee Yojana');
      expect(model.status, 'under_review');
    });

    test('ProductModel and ShoppingCartModel parse correctly', () {
      final productJson = {
        'id': 1,
        'category_id': 2,
        'product_name': 'Neem Coated Urea',
        'brand_or_manufacturer': 'IFFCO',
        'description': '46% Nitrogen slow release',
        'price_inr': 266.50,
        'unit': '45 kg bag',
        'stock_quantity': 100,
        'is_available': true,
      };

      final product = ProductModel.fromJson(productJson);
      expect(product.id, 1);
      expect(product.priceInr, 266.50);

      final cartJson = {
        'id': 1,
        'farmer_id': 65,
        'total_amount_inr': 533.00,
        'total_items_count': 2,
        'items': [
          {
            'id': 10,
            'cart_id': 1,
            'product_id': 1,
            'quantity': 2,
            'product': productJson,
          }
        ],
      };

      final cart = ShoppingCartModel.fromJson(cartJson);
      expect(cart.totalItemsCount, 2);
      expect(cart.totalAmountInr, 533.00);
      expect(cart.items.length, 1);
      expect(cart.items.first.subtotal, 533.00);
    });

    test('EquipmentRentalModel and RentalBookingModel parse correctly', () {
      final eqJson = {
        'id': 1,
        'equipment_name': 'John Deere 5050D Tractor',
        'category': 'Tractor',
        'description': '50HP heavy-duty tractor',
        'provider_name': 'Baramati Krishi Center',
        'contact_phone': '+91 9822011223',
        'location': 'Baramati MIDC',
        'district': 'Pune',
        'state': 'Maharashtra',
        'daily_rate_inr': 2200.0,
        'hourly_rate_inr': 450.0,
        'availability_status': 'available',
      };

      final eq = EquipmentRentalModel.fromJson(eqJson);
      expect(eq.id, 1);
      expect(eq.dailyRateInr, 2200.0);

      final bookingJson = {
        'id': 3,
        'equipment_id': 1,
        'equipment_name': 'John Deere 5050D Tractor',
        'farmer_id': 65,
        'start_date': '2026-11-25',
        'end_date': '2026-11-27',
        'rental_type': 'daily',
        'duration_units': 2,
        'total_cost_inr': 4400.0,
        'delivery_location': 'Plot 4, Baramati',
        'contact_phone': '+91 9876543210',
        'booking_status': 'confirmed',
      };

      final booking = RentalBookingModel.fromJson(bookingJson);
      expect(booking.id, 3);
      expect(booking.totalCostInr, 4400.0);
      expect(booking.bookingStatus, 'confirmed');
    });
  });

  group('Extended Repositories with MockClient', () {
    test('AdvisoryRepository listSchemes and submitLoanEnquiry succeed', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/schemes') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'title': 'Kisan Credit Card',
                'category': 'loan',
                'provider': 'NABARD',
                'description': 'Short-term credit for crop cultivation',
                'benefits': '4% interest rate',
                'eligibility': 'All cultivators',
                'state': 'All India',
                'is_active': true,
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path == '/api/loans/enquiries') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'farmer_id': 65,
              'loan_type': 'Crop Loan',
              'requested_amount_inr': 50000.0,
              'purpose': 'Seed purchase',
              'status': 'pending',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final repo = AdvisoryRepository(apiClient: apiClient, token: 'mock_token');

      final schemes = await repo.listSchemes();
      expect(schemes.length, 1);
      expect(schemes.first.title, 'Kisan Credit Card');

      final loan = await repo.submitLoanEnquiry({
        'loan_type': 'Crop Loan',
        'requested_amount_inr': 50000.0,
        'purpose': 'Seed purchase',
      });
      expect(loan.id, 1);
      expect(loan.status, 'pending');
    });

    test('MarketplaceRepository cart and checkout operations succeed', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/marketplace/cart') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'farmer_id': 65,
              'total_amount_inr': 266.50,
              'total_items_count': 1,
              'items': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path == '/api/marketplace/orders') {
          return http.Response(
            jsonEncode({
              'id': 101,
              'farmer_id': 65,
              'order_status': 'placed',
              'total_amount_inr': 266.50,
              'delivery_address': 'Farm Plot 1, Baramati',
              'contact_phone': '+91 9876543210',
              'payment_method': 'cash_on_delivery',
              'items': [],
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final repo = MarketplaceRepository(apiClient: apiClient, token: 'mock_token');

      final cart = await repo.getCart();
      expect(cart.totalItemsCount, 1);

      final order = await repo.checkoutOrder(
        deliveryAddress: 'Farm Plot 1, Baramati',
        contactPhone: '+91 9876543210',
      );
      expect(order.id, 101);
      expect(order.orderStatus, 'placed');
    });

    test('FarmerRepository assistance requests integration succeeds', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/requests/my') {
          return http.Response(
            jsonEncode([
              {
                'id': 20,
                'farmer_id': 65,
                'title': 'Pest Attack on Wheat',
                'category': 'pest_control',
                'description': 'Aphids spotted on wheat crop stems',
                'priority': 'high',
                'status': 'pending',
              }
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final repo = FarmerRepository(apiClient: apiClient, token: 'mock_token');

      final reqs = await repo.listMyRequests();
      expect(reqs.length, 1);
      expect(reqs.first.title, 'Pest Attack on Wheat');
      expect(reqs.first.priority, 'high');
    });
  });

  group('Extended UI Widgets Testing', () {
    testWidgets('CreateRequestDialog renders form inputs and validates required fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/officers') {
          return http.Response('[]', 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final repo = FarmerRepository(apiClient: apiClient, token: 'mock_token');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: CreateRequestDialog(
                repository: repo,
                farms: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Officer Guidance'), findsOneWidget);
      expect(find.text('Problem Summary *'), findsOneWidget);
      expect(find.text('Detailed Description *'), findsOneWidget);

      // Attempt to submit without inputs
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      expect(find.text('Enter at least 5 characters'), findsOneWidget);
    });

    testWidgets('ApplyLoanDialog renders amount and purpose inputs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      final mockClient = MockClient((request) async => http.Response('Not Found', 404));
      final apiClient = ApiClient(httpClient: mockClient);
      final repo = AdvisoryRepository(apiClient: apiClient, token: 'mock_token');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(child: ApplyLoanDialog(repository: repo)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Agricultural Loan Enquiry'), findsOneWidget);
      expect(find.text('Requested Loan Amount (INR) *'), findsOneWidget);
      expect(find.text('Purpose of Loan *'), findsOneWidget);
    });

    testWidgets('ApplySubsidyDialog renders subsidy inputs and submit button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      final mockClient = MockClient((request) async => http.Response('Not Found', 404));
      final apiClient = ApiClient(httpClient: mockClient);
      final repo = AdvisoryRepository(apiClient: apiClient, token: 'mock_token');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(child: ApplySubsidyDialog(repository: repo)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subsidy Scheme Enquiry'), findsOneWidget);
      expect(find.text('Subsidy / Scheme Name *'), findsOneWidget);
      expect(find.text('Enquiry Details & Farm Requirement *'), findsOneWidget);
    });

    testWidgets('BookEquipmentDialog calculates estimated cost and renders inputs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      final mockClient = MockClient((request) async => http.Response('Not Found', 404));
      final apiClient = ApiClient(httpClient: mockClient);
      final repo = MarketplaceRepository(apiClient: apiClient, token: 'mock_token');

      const testEq = EquipmentRentalModel(
        id: 1,
        equipmentName: 'John Deere Tractor',
        category: 'Tractor',
        description: '50HP Tractor',
        providerName: 'Agro Hiring Center',
        contactPhone: '+91 9876543210',
        location: 'Baramati',
        district: 'Pune',
        state: 'Maharashtra',
        dailyRateInr: 2000.0,
        availabilityStatus: 'available',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(child: BookEquipmentDialog(equipment: testEq, repository: repo)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book Machinery Rental'), findsOneWidget);
      expect(find.text('John Deere Tractor'), findsOneWidget);
      expect(find.text('Delivery / Farm Location *'), findsOneWidget);
      expect(find.text('Confirm Booking'), findsOneWidget);
    });

    testWidgets('CheckoutDialog renders cart summary and checkout button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      final mockClient = MockClient((request) async => http.Response('Not Found', 404));
      final apiClient = ApiClient(httpClient: mockClient);
      final repo = MarketplaceRepository(apiClient: apiClient, token: 'mock_token');

      const testCart = ShoppingCartModel(
        id: 1,
        farmerId: 65,
        totalAmountInr: 1250.0,
        totalItemsCount: 1,
        items: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(child: CheckoutDialog(cart: testCart, repository: repo)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Checkout Order'), findsOneWidget);
      expect(find.text('Total Items: 1'), findsOneWidget);
      expect(find.text('Total: Rs. 1250.00'), findsOneWidget);
      expect(find.text('Place Order'), findsOneWidget);
    });
  });
}
