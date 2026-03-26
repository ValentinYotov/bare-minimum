import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _HeroSection(
                    onLoginTap: () => Navigator.of(context).pushNamed('/login'),
                    onSignUpTap:
                        () => Navigator.of(context).pushNamed('/signup'),
                  ),
                  const _FeatureSection(),
                  _CallToActionSection(
                    onGetStartedTap:
                        () => Navigator.of(context).pushNamed('/signup'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onLoginTap, required this.onSignUpTap});

  final VoidCallback onLoginTap;
  final VoidCallback onSignUpTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF32BF69), Color(0xFF0A5C3D)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Soil\nWatering System',
            style: TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Smart irrigation and safety for your crops',
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontSize: 35,
              fontWeight: FontWeight.w600,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Monitor soil moisture, detect fire hazards, and get '
            'AI-powered crop recommendations - all in one intelligent system.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 27,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onLoginTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0D7E43),
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSignUpTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(color: Colors.white.withOpacity(0.72)),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 22),
      child: Column(
        children: const [
          Text(
            'Why Choose SSWS?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Harness the power of IoT and AI to optimize your agricultural operations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              height: 1.4,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 24),
          _FeatureCard(
            icon: Icons.water_drop_outlined,
            iconBackground: Color(0xFF09BD5E),
            title: 'Smart Watering',
            description:
                'Automated irrigation based on real-time soil moisture levels. '
                'Save water and ensure optimal crop hydration.',
          ),
          _FeatureCard(
            icon: Icons.local_fire_department_outlined,
            iconBackground: Color(0xFFF97316),
            title: 'Fire Detection',
            description:
                'Real-time smoke and fire detection alerts to protect your crops '
                'and property from potential disasters.',
          ),
          _FeatureCard(
            icon: Icons.auto_awesome_outlined,
            iconBackground: Color(0xFF3B82F6),
            title: 'AI Crop Recommendations',
            description:
                'Get personalized crop suggestions based on NPK sensors and soil '
                'conditions for maximum yield.',
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 28,
              height: 1.45,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallToActionSection extends StatelessWidget {
  const _CallToActionSection({required this.onGetStartedTap});

  final VoidCallback onGetStartedTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFDDF3E8)),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 58),
      child: Column(
        children: [
          const Text(
            'Ready to Transform Your Farm?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: Color(0xFF020617),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join thousands of farmers using SSWS to increase productivity and sustainability',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              height: 1.4,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 280,
            child: ElevatedButton(
              onPressed: onGetStartedTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A63E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Text(
                'Get Started Today',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
