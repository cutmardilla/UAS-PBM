import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/search/search_screen.dart';
import 'providers/auth_provider.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter error caught: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Initialize database service
  final dbService = DatabaseService();
  try {
    await dbService.connect();
  } catch (e) {
    print('Failed to initialize database: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider.value(value: dbService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sendok Garpu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF7FBFB6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7FBFB6),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        print(
            'Generating route for: ${settings.name} with args: ${settings.arguments}');

        // Handle routes that need arguments
        switch (settings.name) {
          case '/search':
            return MaterialPageRoute(
              builder: (context) => SearchScreen(
                initialQuery: settings.arguments as String?,
              ),
              settings: settings,
            );
        }

        // Handle standard routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isLoading) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return auth.isAuthenticated
                      ? const MainScreen()
                      : const OnboardingScreen();
                },
              ),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );
          case '/register':
            return MaterialPageRoute(
              builder: (context) => const RegisterScreen(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const MainScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text('Route ${settings.name} not found'),
                ),
              ),
            );
        }
      },
    );
  }
}
