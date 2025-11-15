class AppConstants {
  // API Endpoints
  static const String baseUrl = 'http://localhost:8081/api/v1';
  
  // Asset Types
  static const List<String> assetTypes = [
    'PC',
    'Monitor',
    'Keyboard',
    'Mouse',
    'Headset',
    'UPS',
  ];

  // Ticket Types
  static const List<String> ticketTypes = [
    'activation',
    'deactivation',
    'it_help',
    'transition',
  ];

  // Ticket Priorities
  static const List<String> ticketPriorities = [
    'low',
    'normal',
    'high',
    'critical',
  ];

  // Ticket Statuses
  static const List<String> ticketStatuses = [
    'open',
    'received',
    'in_progress',
    'resolved',
    'closed',
  ];

  // Asset Statuses
  static const List<String> assetStatuses = [
    'IN_USE',
    'IN_STORAGE',
    'RETIRED',
    'REPAIR',
  ];

  // Service Types
  static const List<String> serviceTypes = [
    'MAINTENANCE',
    'REPAIR',
    'UPGRADE',
  ];

  // Role IDs
  static const int roleAdmin = 1;
  static const int roleIT = 2;
  static const int roleStaff = 3;
  static const int roleAgent = 4;
  static const int roleViewer = 5;
}

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String assets = '/assets';
  static const String assetDetail = '/asset/detail';
  static const String createAsset = '/asset/create';
  static const String tickets = '/tickets';
  static const String ticketDetail = '/ticket/detail';
  static const String createTicket = '/ticket/create';
  static const String profile = '/profile';
}