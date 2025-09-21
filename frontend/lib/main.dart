import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/upload_screen.dart';
import 'widgets/logo_showcase.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceClone AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.dark, // Default to dark theme for better AI aesthetic
      home: const MainNavigator(),
    );
  }
}

/// Main navigator with bottom navigation to showcase different features
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  bool _showSplash = true;

  final List<Widget> _screens = [
    const UploadScreen(),
    const LogoShowcase(),
  ];

  @override
  void initState() {
    super.initState();
    // Show splash screen for 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFF6C63FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.upload_file),
            selectedIcon: Icon(Icons.upload_file),
            label: 'Voice Clone',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette),
            selectedIcon: Icon(Icons.palette),
            label: 'Logo Gallery',
          ),
        ],
      ),
    );
  }
}
