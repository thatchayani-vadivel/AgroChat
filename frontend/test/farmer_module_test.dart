import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agrochat_app/core/constants/user_role.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/core/theme/app_theme.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/farmer/models/farm_model.dart';
import 'package:agrochat_app/features/farmer/models/farmer_profile_model.dart';
import 'package:agrochat_app/features/farmer/presentation/farmer_home_screen.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/add_edit_crop_dialog.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/add_edit_farm_dialog.dart';
import 'package:agrochat_app/features/farmer/presentation/widgets/add_livestock_dialog.dart';
import 'package:agrochat_app/features/farmer/repositories/farmer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = AuthUser(
    id: 1,
    fullName: 'Ramesh Patel',
    email: 'ramesh.farmer@agrochat.test',
    phoneNumber: '+91 9876543210',
    role: UserRole.farmer,
    preferredLanguage: 'Hindi',
    isActive: true,
    createdAt: DateTime.parse('2026-11-13T10:00:00Z'),
  );

  final testSession = AuthSession(
    accessToken: 'mock_jwt_farmer_token_12345',
    tokenType: 'bearer',
    expiresIn: 86400,
    user: testUser,
  );

  group('Farmer Models Serialization', () {
    test('FarmerProfileModel parses and serializes correctly', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'village': 'Chandur',
        'taluk_or_block': 'Baramati',
        'district': 'Pune',
        'state': 'Maharashtra',
        'pincode': '413102',
        'total_landholding_acres': 7.5,
        'identity_proof_type': 'Aadhaar Card',
        'identity_proof_number': '1234-5678-9012',
        'preferred_communication_mode': 'In-App Message',
      };

      final profile = FarmerProfileModel.fromJson(json);
      expect(profile.id, 1);
      expect(profile.village, 'Chandur');
      expect(profile.district, 'Pune');
      expect(profile.totalLandholdingAcres, 7.5);

      final serialized = profile.toJson();
      expect(serialized['village'], 'Chandur');
      expect(serialized['district'], 'Pune');
      expect(serialized['total_landholding_acres'], 7.5);

      final copy = profile.copyWith(district: 'Satara');
      expect(copy.district, 'Satara');
      expect(copy.village, 'Chandur');
    });

    test(
      'FarmModel with nested CropModel and LivestockModel parses correctly',
      () {
        final json = {
          'id': 10,
          'farmer_profile_id': 1,
          'farm_name': 'Green Valley Farm',
          'total_area_acres': 5.0,
          'soil_type': 'Black Cotton Soil',
          'irrigation_type': 'Drip Irrigation',
          'water_source': 'Canal + Borewell',
          'location': 'Near River',
          'district': 'Pune',
          'state': 'Maharashtra',
          'ownership_type': 'Owned',
          'crops': [
            {
              'id': 101,
              'farm_id': 10,
              'crop_name': 'Wheat',
              'variety': 'Sharbati',
              'season': 'Rabi',
              'area_acres': 3.0,
              'growth_stage': 'Vegetative',
              'estimated_yield_kg': 4500.0,
            },
          ],
          'livestock': [
            {
              'id': 201,
              'farm_id': 10,
              'category': 'Cattle',
              'breed_or_type': 'Gir Cow',
              'count': 4,
              'purpose': 'Dairy',
              'health_status': 'Healthy',
            },
          ],
        };

        final farm = FarmModel.fromJson(json);
        expect(farm.id, 10);
        expect(farm.farmName, 'Green Valley Farm');
        expect(farm.crops.length, 1);
        expect(farm.crops.first.cropName, 'Wheat');
        expect(farm.crops.first.variety, 'Sharbati');
        expect(farm.livestock.length, 1);
        expect(farm.livestock.first.category, 'Cattle');
        expect(farm.livestock.first.count, 4);

        final serialized = farm.toJson();
        expect(serialized['farm_name'], 'Green Valley Farm');
        expect(serialized['soil_type'], 'Black Cotton Soil');
      },
    );
  });

  group('FarmerRepository API calls with MockClient', () {
    late FarmerRepository repo;

    setUp(() {
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/farmers/profile' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'user_id': 1,
              'village': 'Chandur',
              'district': 'Pune',
              'state': 'Maharashtra',
              'total_landholding_acres': 5.0,
              'preferred_communication_mode': 'In-App Message',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/farmers/profile' && request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          body['id'] = 1;
          body['user_id'] = 1;
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/farmers/preferred-language' &&
            request.method == 'PATCH') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 1,
              'full_name': 'Ramesh Patel',
              'email': 'ramesh.farmer@agrochat.test',
              'phone_number': '+91 9876543210',
              'role': 'farmer',
              'preferred_language': body['preferred_language'],
              'is_active': true,
              'created_at': '2026-11-13T10:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/farms' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'farmer_profile_id': 1,
                'farm_name': 'Plot A',
                'total_area_acres': 3.5,
                'soil_type': 'Alluvial Soil',
                'irrigation_type': 'Drip Irrigation',
                'location': 'North Sector',
                'district': 'Pune',
                'state': 'Maharashtra',
                'crops': [],
                'livestock': [],
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/farms' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          body['id'] = 2;
          body['farmer_profile_id'] = 1;
          body['crops'] = [];
          body['livestock'] = [];
          return http.Response(
            jsonEncode(body),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/farms/1' && request.method == 'DELETE') {
          return http.Response(
            jsonEncode({'message': 'Farm deleted successfully'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/farms/1/crops' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          body['id'] = 50;
          body['farm_id'] = 1;
          return http.Response(
            jsonEncode(body),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/requests/my' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {'id': 1, 'title': 'Crop pest enquiry'},
              {'id': 2, 'title': 'Fertilizer dosage question'},
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"error": "Not Found"}', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      repo = FarmerRepository(
        apiClient: apiClient,
        token: testSession.accessToken,
      );
    });

    test('getFarmerProfile and updateFarmerProfile succeed', () async {
      final profile = await repo.getFarmerProfile();
      expect(profile.district, 'Pune');
      expect(profile.village, 'Chandur');

      final updated = await repo.updateFarmerProfile(
        profile.copyWith(village: 'Baramati Village'),
      );
      expect(updated.village, 'Baramati Village');
    });

    test('updatePreferredLanguage persists new language selection', () async {
      final user = await repo.updatePreferredLanguage('Marathi');
      expect(user.preferredLanguage, 'Marathi');
    });

    test('listFarms, createFarm, and deleteFarm operate accurately', () async {
      final farms = await repo.listFarms();
      expect(farms.length, 1);
      expect(farms.first.farmName, 'Plot A');

      final newFarm = FarmModel(
        id: 0,
        farmerProfileId: 1,
        farmName: 'Plot B',
        totalAreaAcres: 4.0,
        soilType: 'Red Soil',
        irrigationType: 'Sprinkler Irrigation',
        location: 'South Boundary',
        district: 'Pune',
        state: 'Maharashtra',
      );

      final created = await repo.createFarm(newFarm);
      expect(created.id, 2);
      expect(created.farmName, 'Plot B');

      await expectLater(repo.deleteFarm(1), completes);
    });

    test('addCrop creates crop record on farm', () async {
      final crop = CropModel(
        id: 0,
        farmId: 1,
        cropName: 'Sugarcane',
        variety: 'Co 86032',
        season: 'Annual',
        areaAcres: 2.0,
        growthStage: 'Tillering',
      );

      final added = await repo.addCrop(1, crop);
      expect(added.id, 50);
      expect(added.cropName, 'Sugarcane');
    });

    test('getActiveRequestsCount returns correct active count', () async {
      final count = await repo.getActiveRequestsCount();
      expect(count, 2);
    });
  });

  group('Farmer UI Widget Tests', () {
    late FarmerRepository mockRepo;

    setUp(() {
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/farmers/profile') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'user_id': 1,
              'village': 'Baramati',
              'district': 'Pune',
              'state': 'Maharashtra',
              'total_landholding_acres': 5.0,
              'preferred_communication_mode': 'In-App Message',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/farms') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'farmer_profile_id': 1,
                'farm_name': 'Kisan Kendra Plot',
                'total_area_acres': 5.0,
                'soil_type': 'Black Cotton Soil',
                'irrigation_type': 'Drip Irrigation',
                'location': 'Near Canal',
                'district': 'Pune',
                'state': 'Maharashtra',
                'crops': [
                  {
                    'id': 10,
                    'farm_id': 1,
                    'crop_name': 'Soybean',
                    'variety': 'JS-335',
                    'season': 'Kharif',
                    'area_acres': 3.0,
                    'growth_stage': 'Pod Formation',
                  },
                ],
                'livestock': [],
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/requests/my' || path == '/api/notifications') {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"error": "Not Found"}', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      mockRepo = FarmerRepository(
        apiClient: apiClient,
        token: testSession.accessToken,
      );
    });

    testWidgets('FarmerHomeScreen renders navigation tabs and switches tabs', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: FarmerHomeScreen(
            session: testSession,
            farmerRepository: mockRepo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AppBar and bottom destinations
      expect(find.text('Farmer Dashboard'), findsOneWidget);
      expect(find.text('Namaste, Ramesh Patel!'), findsOneWidget);
      expect(find.text('Hindi'), findsWidgets);
      expect(find.byIcon(Icons.dashboard_rounded), findsOneWidget);
      expect(find.byIcon(Icons.landscape_outlined), findsOneWidget);
      expect(find.byIcon(Icons.grass_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      // Tap Farms destination
      await tester.tap(find.byIcon(Icons.landscape_outlined));
      await tester.pumpAndSettle();
      expect(find.text('My Farms'), findsOneWidget);

      // Tap Crops destination
      await tester.tap(find.byIcon(Icons.grass_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Crop Management'), findsOneWidget);

      // Tap Profile destination
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Farmer Profile'), findsOneWidget);
      expect(find.text('Regional Language Preferences'), findsOneWidget);
    });

    testWidgets(
      'AddEditFarmDialog renders form inputs and validates required fields',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1000));

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: AddEditFarmDialog()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Register New Farm'), findsOneWidget);
        expect(find.text('Register Farm'), findsOneWidget);

        // Tap submit with empty fields
        await tester.tap(find.text('Register Farm'));
        await tester.pumpAndSettle();

        // Validation errors should appear
        expect(
          find.text('Please enter a farm name (at least 2 characters)'),
          findsOneWidget,
        );
        expect(find.text('Enter district'), findsOneWidget);
      },
    );

    testWidgets('AddEditCropDialog renders crop registration fields', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: AddEditCropDialog(farmId: 1)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Crop to Farm'), findsOneWidget);
      expect(find.text('Crop Name *'), findsOneWidget);
      expect(find.text('Season *'), findsOneWidget);
      expect(find.text('Current Growth Stage'), findsOneWidget);
      expect(find.text('Save Crop'), findsOneWidget);
    });

    testWidgets('AddLivestockDialog renders livestock categories and counts', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: AddLivestockDialog(farmId: 1)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Livestock / Allied Activity'), findsOneWidget);
      expect(find.text('Category *'), findsOneWidget);
      expect(find.text('Count / Animal Quantity *'), findsOneWidget);
      expect(find.text('Health Status'), findsOneWidget);
      expect(find.text('Save Activity'), findsOneWidget);
    });
  });
}
