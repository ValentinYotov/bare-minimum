import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F5),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF33C463),
                Color(0xFF0B5A3C),
                Color(0xFF062A22),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.only(top: 72, bottom: 40),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10C74F),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.spa_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join SSWS and start smart farming',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 30),

                        const _FieldLabel('Full Name'),
                        const SizedBox(height: 8),
                        const _InputField(
                          hintText: 'Enter your name',
                          icon: Icons.person_outline,
                        ),

                        const SizedBox(height: 18),

                        const _FieldLabel('Email'),
                        const SizedBox(height: 8),
                        const _InputField(
                          hintText: 'Enter your email',
                          icon: Icons.mail_outline,
                        ),

                        const SizedBox(height: 18),

                        const _FieldLabel('Password'),
                        const SizedBox(height: 8),
                        const _InputField(
                          hintText: 'Create a password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF05B63D),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(56),
                              elevation: 3,
                              shadowColor: const Color(0x22000000),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF334155),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                context,
                                '/login',
                              ),
                              child: const Text(
                                'Sign in',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF00A63E),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                          ),
                          child: const Text(
                            '← Back to home',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool obscureText;

  const _InputField({
    required this.hintText,
    required this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.4),
        ),
      ),
    );
  }
}