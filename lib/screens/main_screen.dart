import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'notification/notification_screen.dart';
import 'profile/profile_screen.dart';
import 'auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;
  final List<Widget?> _loadedScreens = List.filled(4, null);

  @override
  void initState() {
    super.initState();
    debugPrint('MainScreen initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  void _checkAuthentication() {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      debugPrint('User not authenticated, redirecting to login');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    if (!_isInitialized) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Widget _buildScreen(int index) {
    if (_loadedScreens[index] == null) {
      switch (index) {
        case 0:
          _loadedScreens[index] = const HomeScreen();
          break;
        case 1:
          _loadedScreens[index] = const SearchScreen();
          break;
        case 2:
          _loadedScreens[index] = const NotificationScreen();
          break;
        case 3:
          _loadedScreens[index] = const ProfileScreen();
          break;
      }
    }
    return _loadedScreens[index]!;
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    debugPrint('Tapped bottom nav item: $index');
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        if (!_isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: KeyedSubtree(
              key: ValueKey<int>(_selectedIndex),
              child: _buildScreen(_selectedIndex),
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _isInitialized = false;
    _loadedScreens.fillRange(0, _loadedScreens.length, null);
    super.dispose();
  }
}
