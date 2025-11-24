// filename: lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/asset_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/service_log_provider.dart';
import 'providers/ticket_provider.dart';
import 'providers/user_provider.dart'; // ADD THIS IMPORT

import 'screens/assets/asset_form_screen.dart';
import 'screens/assets/asset_list_screen.dart';
import 'screens/assets/my_assets_sceen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/placeholder/placeholder_screen.dart';
import 'screens/splash_screen.dart';

// ADD THESE TICKET SCREEN IMPORTS
import 'screens/tickets/ticket_list_screen.dart';
import 'screens/tickets/ticket_detail_screen.dart';
import 'screens/tickets/ticket_form_screen.dart';

// ADD USER MANAGEMENT IMPORTS
import 'screens/users/user_list_screen.dart'; // ADD THIS
import 'screens/users/user_form_screen.dart'; // ADD THIS
import 'screens/users/user_detail_screen.dart'; // ADD THIS

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
        ChangeNotifierProvider(create: (context) => UserProvider()), // ADD THIS
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
          '/users': (context) => const UserListScreen(), // CHANGED THIS
          '/users/create': (context) => const UserFormScreen(), // ADD THIS
          '/users/edit': (context) => const UserFormScreen(), // ADD THIS

          '/notifications': (context) => const PlaceholderScreen(
                title: 'Notifications',
                description:
                    'View and manage your system notifications and alerts.',
              ),
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
          '/roles': (context) => const PlaceholderScreen(
                title: 'Role Management',
                description:
                    'Configure system roles and permissions (Admin Only).',
              ),
          '/analytics': (context) => const PlaceholderScreen(
                title: 'System Analytics',
                description:
                    'View system-wide analytics and performance metrics (Admin Only).',
              ),

          // IT Staff Routes
          '/ticket-assignment': (context) => const PlaceholderScreen(
                title: 'Ticket Assignment',
                description:
                    'Assign and manage ticket assignments for IT staff.',
              ),
          '/service-management': (context) => const PlaceholderScreen(
                title: 'Service Management',
                description: 'Manage asset service schedules and maintenance.',
              ),

          // Staff/Team Lead Routes
          '/my-team': (context) => const PlaceholderScreen(
                title: 'My Team',
                description:
                    'View and manage your team members and their assignments.',
              ),
          '/ticket-verification': (context) => const PlaceholderScreen(
                title: 'Ticket Verification',
                description: 'Verify and close completed support tickets.',
              ),

          // Agent Routes
          '/my-tickets': (context) => const PlaceholderScreen(
                title: 'My Tickets',
                description: 'View and manage tickets assigned to you.',
              ),
          '/my-assets': (context) => const MyAssetsScreen(),
          // Viewer Routes
          '/view-assets': (context) => const PlaceholderScreen(
                title: 'View Assets',
                description: 'View company assets (Read-only access).',
              ),
          '/view-tickets': (context) => const PlaceholderScreen(
                title: 'View Tickets',
                description: 'View support tickets (Read-only access).',
              ),

          // Common Reports
          '/reports': (context) => const PlaceholderScreen(
                title: 'Reports',
                description: 'Generate and view system reports.',
              ),
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