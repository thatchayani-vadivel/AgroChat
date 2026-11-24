/// Centralized FastAPI backend endpoint paths.
class ApiEndpoints {
  ApiEndpoints._();

  static const String root = '/';
  static const String health = '/health';
  static const String ready = '/ready';

  // Authentication endpoints
  static const String registerFarmer = '/api/auth/register/farmer';
  static const String loginFarmer = '/api/auth/login/farmer';
  static const String registerOfficer = '/api/auth/register/officer';
  static const String loginOfficer = '/api/auth/login/officer';
  static const String me = '/api/auth/me';

  // Farmer Profiles
  static const String farmerProfile = '/api/farmers/profile';
  static const String farmerPreferredLanguage =
      '/api/farmers/preferred-language';
  static String farmerDetails(int farmerId) => '/api/farmers/$farmerId';

  // Agricultural Officer Profiles & Discovery
  static const String officerProfile = '/api/officers/profile';
  static const String officerAvailability = '/api/officers/availability';
  static const String officersDiscovery = '/api/officers';
  static String officerDetails(int officerId) => '/api/officers/$officerId';

  // Farms, Crops & Livestock
  static const String farms = '/api/farms';
  static String farmDetails(int id) => '/api/farms/$id';
  static String farmCrops(int farmId) => '/api/farms/$farmId/crops';
  static String farmCropDetail(int farmId, int cropId) =>
      '/api/farms/$farmId/crops/$cropId';
  static String farmLivestock(int farmId) => '/api/farms/$farmId/livestock';
  static String farmLivestockDetail(int farmId, int livestockId) =>
      '/api/farms/$farmId/livestock/$livestockId';

  // Assistance Requests & Consultations
  static const String requests = '/api/requests';
  static const String myRequests = '/api/requests/my';
  static const String officerRequests = '/api/requests/officer';
  static String requestDetails(int id) => '/api/requests/$id';
  static String cancelRequest(int id) => '/api/requests/$id/cancel';
  static String acceptRequest(int id) => '/api/requests/$id/accept';
  static String rejectRequest(int id) => '/api/requests/$id/reject';
  static String updateRequestStatus(int id) => '/api/requests/$id/status';
  static String requestAttachments(int requestId) =>
      '/api/requests/$requestId/attachments';

  static const String consultations = '/api/consultations';
  static String consultationDetails(int id) => '/api/consultations/$id';

  // Chat & Voice
  static String requestMessages(int requestId) =>
      '/api/chat/requests/$requestId/messages';
  static String requestVoice(int requestId) =>
      '/api/chat/requests/$requestId/voice';
  static String voiceFile(String filename) => '/api/chat/voice/$filename';

  // Advisory: Schemes, Equipment, Services
  static const String schemes = '/api/schemes';
  static String schemeDetails(int id) => '/api/schemes/$id';

  static const String equipmentRentals = '/api/equipment-rentals';
  static String equipmentRentalDetails(int id) => '/api/equipment-rentals/$id';
  static const String equipmentBookings = '/api/equipment-rentals/bookings';
  static const String myEquipmentBookings =
      '/api/equipment-rentals/bookings/my';
  static String equipmentBookingDetails(int id) =>
      '/api/equipment-rentals/bookings/$id';
  static String cancelEquipmentBooking(int id) =>
      '/api/equipment-rentals/bookings/$id/cancel';
  static String updateEquipmentBookingStatus(int id) =>
      '/api/equipment-rentals/bookings/$id/status';

  static const String agriculturalServices = '/api/services';
  static String agriculturalServiceDetails(int id) => '/api/services/$id';

  // Loan Advisory Enquiries
  static const String loanEnquiries = '/api/loans/enquiries';
  static const String myLoanEnquiries = '/api/loans/enquiries/my';
  static String loanEnquiryDetails(int id) => '/api/loans/enquiries/$id';
  static String updateLoanGuidance(int id) =>
      '/api/loans/enquiries/$id/guidance';

  // Subsidy Advisory Enquiries
  static const String subsidyEnquiries = '/api/subsidies/enquiries';
  static const String mySubsidyEnquiries = '/api/subsidies/enquiries/my';
  static String subsidyEnquiryDetails(int id) => '/api/subsidies/enquiries/$id';
  static String updateSubsidyGuidance(int id) =>
      '/api/subsidies/enquiries/$id/guidance';

  // Agricultural Marketplace
  static const String marketplaceCategories = '/api/marketplace/categories';
  static const String marketplaceProducts = '/api/marketplace/products';
  static String marketplaceProductDetails(int id) =>
      '/api/marketplace/products/$id';
  static const String marketplaceCart = '/api/marketplace/cart';
  static const String marketplaceCartItems = '/api/marketplace/cart/items';
  static String marketplaceCartItemDetail(int productId) =>
      '/api/marketplace/cart/items/$productId';
  static const String marketplaceOrders = '/api/marketplace/orders';
  static const String myMarketplaceOrders = '/api/marketplace/orders/my';
  static String marketplaceOrderDetails(int id) =>
      '/api/marketplace/orders/$id';
  static String updateMarketplaceOrderStatus(int id) =>
      '/api/marketplace/orders/$id/status';

  // In-App Notifications
  static const String notifications = '/api/notifications';
  static String markNotificationRead(int id) => '/api/notifications/$id/read';
  static const String markAllNotificationsRead = '/api/notifications/read-all';
}
