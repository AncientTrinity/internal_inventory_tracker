// filename: lib/main.dart
import 'package:flutter/material.dart';
import 'providers/weather_provider.dart';
import 'screens/notifications/notification_list_screen.dart';
import 'package:provider/provider.dart';

import 'providers/asset_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/service_log_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/user_provider.dart'; // ADD THIS IMPORT
import 'providers/notification_provider.dart'; //notifications

import 'screens/assets/asset_form_screen.dart';
import 'screens/assets/asset_list_screen.dart';
import 'screens/assets/my_assets_sceen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/placeholder/placeholder_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/splash_screen.dart';

// ADD THESE TICKET SCREEN IMPORTS
import 'screens/tickets/ticket_list_screen.dart';
import 'screens/tickets/ticket_detail_screen.dart';
import 'screens/tickets/ticket_form_screen.dart';

// ADD USER MANAGEMENT IMPORTS
import 'screens/users/user_list_screen.dart'; // ADD THIS
import 'screens/users/user_form_screen.dart'; // ADD THIS
import 'screens/users/user_detail_screen.dart'; // ADD THIS

// Replace the main function and InternalInventoryTrackerApp class
import 'providers/reports_provider.dart';
void main() {
  runApp(const InternalInventoryTrackerApp());
}

class InternalInventoryTrackerApp extends StatelessWidget {
  const InternalInventoryTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (context) => ServiceLogProvider()),
        ChangeNotifierProvider(create: (context) => TicketProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()), 
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider<ReportsProvider>(create: (context) => ReportsProvider()),
        ChangeNotifierProvider(create: (context) => WeatherProvider()),
      ],
      child: MaterialApp(
        title: 'Internal Inventory Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const SplashScreen(),
        routes: {
          // Authentication
          '/login': (context) => const LoginScreen(),

          // Main Dashboard
          '/dashboard': (context) => const DashboardScreen(),

          // Common Features (All Roles)
          '/assets': (context) => const AssetListScreen(),
          '/assets/add': (context) => const AssetFormScreen(),
          '/assets/edit': (context) => const AssetFormScreen(),

          // Tickets
          '/tickets': (context) => const TicketListScreen(),
          '/tickets/create': (context) => const TicketFormScreen(),

          // User Management - REPLACE PLACEHOLDER WITH ACTUAL SCREENS
          '/users': (context) => const UserListScreen(), 
          '/users/create': (context) => const UserFormScreen(), 
          '/users/edit': (context) => const UserFormScreen(), 

          '/notifications': (context) => const NotificationListScreen(),
          '/settings': (context) => const PlaceholderScreen(
                title: 'Settings',
                description:
                    'Configure your application preferences and settings.',
              ),
          '/help': (context) => const PlaceholderScreen(
                title: 'Help & Support',
                description:
                    'Get help and support for using the Internal Inventory Tracker.',
              ),

          // Admin Only Routes
          '/roles': (context) => const UserFormScreen(), 
          '/analytics': (context) => const ReportsScreen(),

          // IT Staff Routes
          '/ticket-assignment': (context) => const TicketListScreen(),
          '/service-management': (context) => const AssetFormScreen(),

          // Staff/Team Lead Routes
          '/my-team': (context) => const PlaceholderScreen(
                title: 'My Team',
                description:
                    'View and manage your team members and their assignments.',
              ),
          '/ticket-verification': (context) => const TicketListScreen(),
          // Agent Routes
          '/my-tickets': (context) => const TicketListScreen(),
          '/my-assets': (context) => const MyAssetsScreen(),
          // Viewer Routes
          '/view-assets': (context) => const AssetListScreen(),
          '/view-tickets': (context) => const TicketListScreen(),

          // Common Reports
          '/reports': (context) => const ReportsScreen(),
        },

        // Add this onGenerateRoute method to handle arguments:
        onGenerateRoute: (settings) {
          // Handle asset edit with arguments
          if (settings.name == '/assets/edit') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => AssetFormScreen(asset: args['asset']),
            );
          }

          // Handle ticket details with dynamic ID
          if (settings.name?.startsWith('/tickets/') == true) {
            final parts = settings.name!.split('/');
            if (parts.length == 3) {
              final id = int.tryParse(parts[2]);
              if (id != null) {
                return MaterialPageRoute(
                  builder: (context) => TicketDetailScreen(ticketId: id),
                );
              }
            }
          }

          // Handle user edit with arguments - ADD THIS
          if (settings.name == '/users/edit') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => UserFormScreen(user: args['user']),
            );
          }

          // Handle user details with dynamic ID - ADD THIS
          if (settings.name?.startsWith('/users/') == true) {
            final parts = settings.name!.split('/');
            if (parts.length == 3) {
              final id = int.tryParse(parts[2]);
              if (id != null) {
                return MaterialPageRoute(
                  builder: (context) => UserDetailScreen(userId: id),
                );
              }
            }
          }

          return null;
        },

        debugShowCheckedModeBanner: false,
      ),
    );
  }
}