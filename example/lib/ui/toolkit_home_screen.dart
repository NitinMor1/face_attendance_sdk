import 'package:flutter/material.dart';

class ToolkitHomeScreen extends StatelessWidget {
  const ToolkitHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo.shade900, Colors.blue.shade800],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.face_retouching_natural, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'FACE RECOGNITION KIT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Professional Biometric SDK Showcase',
                style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 0.5),
              ),
              const SizedBox(height: 60),
              
              _FeatureCard(
                title: 'SDK Feature Explorer',
                subtitle: 'Live Detection, Registry & Metrics',
                icon: Icons.explore_outlined,
                onTap: () {
                  // Simply enter the showcase
                  Navigator.of(context).pushReplacementNamed('/showcase');
                },
              ),
              
              const SizedBox(height: 20),
              
              _FeatureCard(
                title: 'Quick Documentation',
                subtitle: 'Implementation & Platform Setup',
                icon: Icons.menu_book_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('See README.md for full implementation details.')),
                  );
                },
              ),
              
              const Spacer(),
              const Text(
                'Powered by Face Recognition Kit v1.1.0',
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
