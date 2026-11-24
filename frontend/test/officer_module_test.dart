import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agrochat_app/core/constants/user_role.dart';
import 'package:agrochat_app/core/network/api_client.dart';
import 'package:agrochat_app/core/theme/app_theme.dart';
import 'package:agrochat_app/features/auth/models/auth_user.dart';
import 'package:agrochat_app/features/officer/models/assistance_request_model.dart';
import 'package:agrochat_app/features/officer/models/chat_message_model.dart';
import 'package:agrochat_app/features/officer/models/farmer_details_model.dart';
import 'package:agrochat_app/features/officer/models/notification_model.dart';
import 'package:agrochat_app/features/officer/models/officer_profile_model.dart';
import 'package:agrochat_app/features/officer/presentation/officer_home_screen.dart';
import 'package:agrochat_app/features/officer/presentation/widgets/edit_officer_profile_dialog.dart';
import 'package:agrochat_app/features/officer/presentation/widgets/reject_request_dialog.dart';
import 'package:agrochat_app/features/officer/presentation/widgets/update_status_dialog.dart';
import 'package:agrochat_app/features/officer/repositories/officer_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testOfficerUser = AuthUser(
    id: 5,
    fullName: 'Dr. Sunita Rao',
    email: 'sunita.rao@officer.agrochat.test',
    phoneNumber: '+91 9123456789',
    role: UserRole.agriculturalOfficer,
    preferredLanguage: 'English',
    isActive: true,
    createdAt: DateTime.parse('2026-11-13T10:00:00Z'),
  );

  final testOfficerSession = AuthSession(
    accessToken: 'mock_jwt_officer_token_99999',
    tokenType: 'bearer',
    expiresIn: 86400,
    user: testOfficerUser,
  );

  group('Officer Models Serialization', () {
    test('OfficerProfileModel parses JSON and serializes accurately', () {
      final json = {
        'id': 1,
        'user_id': 5,
        'designation': 'Senior Agricultural Officer',
        'department': 'Department of Agriculture',
        'specialization': 'Plant Pathology & Pest Management',
        'qualifications': 'Ph.D. in Agronomy',
        'experience_years': 12,
        'languages_spoken': 'English, Hindi, Marathi',
        'office_location': 'Krishi Bhavan, Room 204',
        'district': 'Pune',
        'state': 'Maharashtra',
        'is_available': true,
        'availability_hours': '09:00 AM - 05:00 PM',
        'bio': 'Specialized in organic disease control.',
      };

      final model = OfficerProfileModel.fromJson(json);
      expect(model.id, 1);
      expect(model.designation, 'Senior Agricultural Officer');
      expect(model.specialization, 'Plant Pathology & Pest Management');
      expect(model.experienceYears, 12);
      expect(model.isAvailable, true);

      final serialized = model.toJson();
      expect(serialized['designation'], 'Senior Agricultural Officer');
      expect(serialized['experience_years'], 12);
      expect(serialized['district'], 'Pune');

      final copy = model.copyWith(isAvailable: false);
      expect(copy.isAvailable, false);
      expect(copy.designation, 'Senior Agricultural Officer');
    });

    test(
      'AssistanceRequestModel and RequestAttachmentModel parse correctly',
      () {
        final json = {
          'id': 101,
          'farmer_id': 20,
          'officer_id': 5,
          'farm_id': 1,
          'crop_id': 2,
          'title': 'Yellow Rust on Wheat crop',
          'category': 'Crop Disease',
          'description': 'Yellow powder pustules spreading on leaves.',
          'priority': 'urgent',
          'status': 'pending',
          'farmer_name': 'Ramesh Patil',
          'farmer_phone': '+91 9876543210',
          'officer_name': 'Dr. Sunita Rao',
          'farm_name': 'Plot North',
          'crop_name': 'Wheat (HD 2967)',
          'consultation_id': 301,
          'attachments': [
            {
              'id': 1,
              'request_id': 101,
              'file_name': 'leaf_infection.jpg',
              'file_type': 'image',
              'file_size_bytes': 204800,
              'file_url': '/uploads/leaf_infection.jpg',
              'description': 'Close-up of infected leaf.',
            },
          ],
        };

        final req = AssistanceRequestModel.fromJson(json);
        expect(req.id, 101);
        expect(req.title, 'Yellow Rust on Wheat crop');
        expect(req.isPending, true);
        expect(req.isAccepted, false);
        expect(req.farmerName, 'Ramesh Patil');
        expect(req.attachments.length, 1);
        expect(req.attachments.first.fileName, 'leaf_infection.jpg');
        expect(req.attachments.first.fileType, 'image');
      },
    );

    test('ChatMessageModel parses text and voice message payloads', () {
      final textJson = {
        'id': 1,
        'request_id': 101,
        'sender_id': 5,
        'receiver_id': 20,
        'sender_name': 'Dr. Sunita Rao',
        'sender_role': 'agricultural_officer',
        'message_type': 'text',
        'content': 'Apply Propiconazole 25% EC @ 1ml/litre immediately.',
        'is_read': true,
      };

      final msg = ChatMessageModel.fromJson(textJson);
      expect(msg.id, 1);
      expect(msg.isFromOfficer, true);
      expect(msg.isFromFarmer, false);
      expect(msg.isVoice, false);
      expect(msg.content, contains('Propiconazole'));

      final voiceJson = {
        'id': 2,
        'request_id': 101,
        'sender_id': 20,
        'receiver_id': 5,
        'sender_role': 'farmer',
        'message_type': 'voice',
        'audio_file_name': 'voice_123.m4a',
        'duration_seconds': 14,
        'is_read': false,
      };

      final voiceMsg = ChatMessageModel.fromJson(voiceJson);
      expect(voiceMsg.isVoice, true);
      expect(voiceMsg.isFromFarmer, true);
      expect(voiceMsg.durationSeconds, 14);
    });

    test('NotificationListModel and NotificationItemModel parse correctly', () {
      final json = {
        'unread_count': 1,
        'items': [
          {
            'id': 10,
            'user_id': 5,
            'title': 'New Assistance Request',
            'message':
                'Farmer Ramesh Patil submitted an urgent request for Wheat.',
            'notification_type': 'request_update',
            'related_request_id': 101,
            'is_read': false,
          },
        ],
      };

      final list = NotificationListModel.fromJson(json);
      expect(list.unreadCount, 1);
      expect(list.items.length, 1);
      expect(list.items.first.title, 'New Assistance Request');
      expect(list.items.first.relatedRequestId, 101);
    });

    test('FarmerInspectionModel computes total acreage and counts', () {
      final json = {
        'profile': {
          'user_id': 20,
          'village': 'Baramati',
          'taluk_or_block': 'Baramati',
          'district': 'Pune',
          'state': 'Maharashtra',
          'farming_experience_years': 15,
          'user': {
            'id': 20,
            'full_name': 'Ramesh Patil',
            'email': 'ramesh@example.com',
            'phone_number': '+91 9876543210',
            'preferred_language': 'Marathi',
          },
        },
        'farms': [
          {
            'id': 1,
            'farmer_profile_id': 1,
            'farm_name': 'Plot A',
            'total_area_acres': 4.5,
            'soil_type': 'Black Cotton Soil',
            'irrigation_type': 'Drip Irrigation',
            'location': 'Near River',
            'district': 'Pune',
            'state': 'Maharashtra',
            'crops': [
              {
                'id': 1,
                'farm_id': 1,
                'crop_name': 'Wheat',
                'season': 'Rabi',
                'area_acres': 3.0,
              },
            ],
            'livestock': [
              {'id': 1, 'farm_id': 1, 'category': 'Cattle', 'count': 2},
            ],
          },
        ],
      };

      final inspection = FarmerInspectionModel.fromJson(json);
      expect(inspection.fullName, 'Ramesh Patil');
      expect(inspection.district, 'Pune');
      expect(inspection.totalLandAcres, 4.5);
      expect(inspection.totalCropsCount, 1);
      expect(inspection.totalLivestockCount, 1);
    });
  });

  group('OfficerRepository Integration with MockClient', () {
    late OfficerRepository repo;

    setUp(() {
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/officers/profile' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'user_id': 5,
              'designation': 'Agricultural Officer',
              'specialization': 'Agronomy',
              'district': 'Pune',
              'state': 'Maharashtra',
              'experience_years': 8,
              'languages_spoken': 'English, Hindi',
              'is_available': true,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/officers/profile' && request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          body['id'] = 1;
          body['user_id'] = 5;
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/officers/availability' && request.method == 'PATCH') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 1,
              'user_id': 5,
              'designation': 'Agricultural Officer',
              'specialization': 'Agronomy',
              'district': 'Pune',
              'state': 'Maharashtra',
              'is_available': body['is_available'],
              'availability_hours': body['availability_hours'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/requests/officer' && request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 101,
                'farmer_id': 20,
                'title': 'Pest attack on Cotton',
                'category': 'Pest Management',
                'description': 'Bollworms identified on bolls.',
                'priority': 'urgent',
                'status': 'pending',
                'farmer_name': 'Ramesh Patil',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/requests/101/accept' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'id': 101,
              'farmer_id': 20,
              'title': 'Pest attack on Cotton',
              'category': 'Pest Management',
              'description': 'Bollworms identified on bolls.',
              'priority': 'urgent',
              'status': 'accepted',
              'farmer_name': 'Ramesh Patil',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/requests/101/reject' && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'id': 101,
              'farmer_id': 20,
              'title': 'Pest attack on Cotton',
              'category': 'Pest Management',
              'description': 'Bollworms identified on bolls.',
              'priority': 'urgent',
              'status': 'rejected',
              'rejection_reason': 'Outside assigned district jurisdiction.',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/farmers/20' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'profile': {
                'user_id': 20,
                'village': 'Baramati',
                'district': 'Pune',
                'state': 'Maharashtra',
                'user': {
                  'id': 20,
                  'full_name': 'Ramesh Patil',
                  'email': 'r@test.com',
                },
              },
              'farms': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/chat/requests/101/messages' &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode([
              {
                'id': 1,
                'request_id': 101,
                'sender_id': 20,
                'receiver_id': 5,
                'content': 'Need help with pest spray dosage.',
                'message_type': 'text',
                'is_read': true,
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/chat/requests/101/messages' &&
            request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 2,
              'request_id': 101,
              'sender_id': 5,
              'receiver_id': 20,
              'content': body['content'],
              'sender_role': 'agricultural_officer',
              'message_type': 'text',
              'is_read': false,
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/notifications' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'unread_count': 1,
              'items': [
                {
                  'id': 50,
                  'user_id': 5,
                  'title': 'New Request',
                  'message': 'Urgent request submitted.',
                  'is_read': false,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"error": "Not Found"}', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      repo = OfficerRepository(
        apiClient: apiClient,
        token: testOfficerSession.accessToken,
      );
    });

    test('getProfile, updateProfile, and updateAvailability succeed', () async {
      final p = await repo.getProfile();
      expect(p.designation, 'Agricultural Officer');
      expect(p.isAvailable, true);

      final updated = await repo.updateProfile(
        p.copyWith(designation: 'District Agriculture Specialist'),
      );
      expect(updated.designation, 'District Agriculture Specialist');

      final avail = await repo.updateAvailability(false);
      expect(avail.isAvailable, false);
    });

    test(
      'listRequests, acceptRequest, and rejectRequest execute accurately',
      () async {
        final reqs = await repo.listRequests();
        expect(reqs.length, 1);
        expect(reqs.first.title, 'Pest attack on Cotton');

        final accepted = await repo.acceptRequest(101);
        expect(accepted.status, 'accepted');

        final rejected = await repo.rejectRequest(
          101,
          'Outside assigned district jurisdiction.',
        );
        expect(rejected.status, 'rejected');
        expect(rejected.rejectionReason, contains('jurisdiction'));
      },
    );

    test('getFarmerDetails returns authorized farmer data', () async {
      final farmer = await repo.getFarmerDetails(20);
      expect(farmer.fullName, 'Ramesh Patil');
      expect(farmer.district, 'Pune');
    });

    test('listMessages and sendTextMessage function properly', () async {
      final messages = await repo.listMessages(101);
      expect(messages.length, 1);
      expect(messages.first.content, contains('pest spray'));

      final sent = await repo.sendTextMessage(
        101,
        'Spray 2ml Neem oil per litre water.',
      );
      expect(sent.id, 2);
      expect(sent.content, contains('Neem oil'));
    });

    test('listNotifications retrieves items and unread count', () async {
      final notifs = await repo.listNotifications();
      expect(notifs.unreadCount, 1);
      expect(notifs.items.first.title, 'New Request');
    });
  });

  group('Officer UI Widget Tests', () {
    late OfficerRepository mockRepo;

    setUp(() {
      final mockClient = MockClient((request) async {
        final path = request.url.path;

        if (path == '/api/officers/profile') {
          return http.Response(
            jsonEncode({
              'id': 1,
              'user_id': 5,
              'designation': 'Horticulture Specialist',
              'specialization': 'Fruit Crop Diseases',
              'district': 'Pune',
              'state': 'Maharashtra',
              'is_available': true,
              'languages_spoken': 'English, Hindi',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/requests/officer') {
          return http.Response(
            jsonEncode([
              {
                'id': 101,
                'farmer_id': 20,
                'title': 'Leaf spot on Pomegranate',
                'category': 'Disease Control',
                'description':
                    'Bacterial blight spots appearing on leaves and fruits.',
                'priority': 'high',
                'status': 'pending',
                'farmer_name': 'Vijay Shinde',
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path == '/api/notifications') {
          return http.Response(
            jsonEncode({'unread_count': 0, 'items': []}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('{"error": "Not Found"}', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      mockRepo = OfficerRepository(
        apiClient: apiClient,
        token: testOfficerSession.accessToken,
      );
    });

    testWidgets('OfficerHomeScreen renders tabs and switches between views', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OfficerHomeScreen(
            session: testOfficerSession,
            officerRepository: mockRepo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Destinations
      expect(find.text('Officer Dashboard'), findsOneWidget);
      expect(find.text('Welcome, Officer Dr. Sunita Rao!'), findsOneWidget);
      final navBar = find.byType(NavigationBar);
      expect(
        find.descendant(
          of: navBar,
          matching: find.byIcon(Icons.dashboard_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: navBar,
          matching: find.byIcon(Icons.assignment_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: navBar,
          matching: find.byIcon(Icons.notifications_none_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: navBar,
          matching: find.byIcon(Icons.person_outline_rounded),
        ),
        findsOneWidget,
      );

      // Tap Requests destination
      await tester.tap(
        find.descendant(
          of: navBar,
          matching: find.byIcon(Icons.assignment_outlined),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Farmer Requests'), findsOneWidget);

      // Tap Notifications destination
      await tester.tap(
        find.descendant(
          of: navBar,
          matching: find.byIcon(Icons.notifications_none_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsWidgets);

      // Tap Profile destination
      await tester.tap(
        find.descendant(
          of: navBar,
          matching: find.byIcon(Icons.person_outline_rounded),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Officer Profile'), findsWidgets);
      expect(find.text('Professional Credentials'), findsOneWidget);
    });

    testWidgets('RejectRequestDialog validates min 5 character explanation', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: RejectRequestDialog(requestTitle: 'Pest enquiry'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reject Assistance Request'), findsOneWidget);
      expect(find.text('Confirm Rejection'), findsOneWidget);

      // Tap Confirm Rejection without typing
      await tester.tap(find.text('Confirm Rejection'));
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter a detailed reason (at least 5 characters)'),
        findsOneWidget,
      );
    });

    testWidgets('UpdateStatusDialog renders status selector and updates', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: UpdateStatusDialog(currentStatus: 'accepted'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Update Advisory Status'), findsOneWidget);
      expect(find.text('Target Status *'), findsOneWidget);
      expect(find.text('Update Status'), findsOneWidget);
    });

    testWidgets('EditOfficerProfileDialog renders credentials inputs', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      const profile = OfficerProfileModel(
        id: 1,
        userId: 5,
        designation: 'Agricultural Officer',
        specialization: 'Soil Chemistry',
        district: 'Pune',
        state: 'Maharashtra',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: EditOfficerProfileDialog(existingProfile: profile),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Officer Profile'), findsOneWidget);
      expect(find.text('Designation *'), findsOneWidget);
      expect(find.text('Specialization *'), findsOneWidget);
      expect(find.text('Save Profile'), findsOneWidget);
    });
  });
}
