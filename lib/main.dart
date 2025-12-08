import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/getting_started_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/permission_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await _initializeServices();

  // Initialize permissions service
  final permissionService = PermissionService();

  runApp(MyApp(permissionService: permissionService));
}

/// Initialize all required services before app startup
Future<void> _initializeServices() async {
  try {
    // Initialize storage service first (needed for other services)
    await StorageService().initialize();

    // Initialize API service
    ApiService().initialize();

    debugPrint('✅ All services initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize services: $e');
    // Continue with app startup even if services fail to initialize
    // Services will handle their own error states
  }
}

class MyApp extends StatefulWidget {
  final PermissionService permissionService;

  const MyApp({super.key, required this.permissionService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up services when app is disposed
    ApiService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
        // App is being terminated
        ApiService().dispose();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final userProvider = UserProvider();
            // Initialize auth status on app startup
            userProvider.checkAuthStatus();
            return userProvider;
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider();
            // Initialize auth state on app startup
            authProvider.initializeAuth();
            return authProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Sangam',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const GettingStartedScreen(),
        routes: {
          '/home': (context) => const MainNavigationScreen(initialIndex: 0),
        },
      ),
    );
  }
}
