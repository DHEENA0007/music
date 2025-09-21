import 'package:flutter/material.dart';
import 'package:voice_clone_app/widgets/app_logo.dart';

/// Example usage of the AppLogo widget
class LogoShowcase extends StatelessWidget {
  const LogoShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Large animated logo with text for splash screen
              const AppLogoWithText(
                logoSize: 120,
                fontSize: 32,
                animated: true,
                primaryColor: Color(0xFF6C63FF),
                secondaryColor: Color(0xFF00D4FF),
                appName: 'VoiceClone AI',
                tagline: 'Powered by RVC Technology',
              ),
              
              const SizedBox(height: 60),
              
              // Different sizes showcase
              const Text(
                'Logo Variations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Row of different logo sizes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const AppLogo(
                        size: 40,
                        animated: false,
                        primaryColor: Color(0xFF6C63FF),
                        secondaryColor: Color(0xFF00D4FF),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Small (40px)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const AppLogo(
                        size: 60,
                        animated: true,
                        primaryColor: Color(0xFF6C63FF),
                        secondaryColor: Color(0xFF00D4FF),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Medium (60px)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const AppLogo(
                        size: 80,
                        animated: true,
                        primaryColor: Color(0xFF6C63FF),
                        secondaryColor: Color(0xFF00D4FF),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Large (80px)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Color variations
              const Text(
                'Color Themes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 20),
              
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildColorVariation(
                    'Purple/Cyan',
                    const Color(0xFF6C63FF),
                    const Color(0xFF00D4FF),
                  ),
                  _buildColorVariation(
                    'Orange/Pink',
                    const Color(0xFFFF6B35),
                    const Color(0xFFFF006E),
                  ),
                  _buildColorVariation(
                    'Green/Blue',
                    const Color(0xFF00F5FF),
                    const Color(0xFF00FF7F),
                  ),
                  _buildColorVariation(
                    'Gold/Red',
                    const Color(0xFFFFD700),
                    const Color(0xFFFF4444),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Usage in app bar example
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'App Bar Usage Example',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 16),
                          AppLogo(
                            size: 32,
                            animated: false,
                            primaryColor: Color(0xFF6C63FF),
                            secondaryColor: Color(0xFF00D4FF),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'VoiceClone AI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorVariation(String name, Color primary, Color secondary) {
    return Column(
      children: [
        AppLogo(
          size: 60,
          animated: true,
          primaryColor: primary,
          secondaryColor: secondary,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
