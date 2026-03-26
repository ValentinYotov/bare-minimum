import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends StatelessWidget {
  final String selectedPage;

  const AppDrawer({super.key, required this.selectedPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF8F8F8),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF08C24E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.spa_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SSWS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: selectedPage == 'dashboard',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            _DrawerItem(
              icon: Icons.chat_bubble_outline,
              label: 'AI Chat',
              selected: selectedPage == 'chat',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/chat');
              },
            ),
            _DrawerItem(
              icon: Icons.lightbulb_outline,
              label: 'Recommendations',
              selected: selectedPage == 'recommendations',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/recommendations');
              },
            ),
            _DrawerItem(
              icon: Icons.map_outlined,
              label: 'Map View',
              selected: selectedPage == 'map',
              onTap: () {
  Navigator.pop(context);
  Navigator.pushReplacementNamed(context, '/map');
},
            ),
            _DrawerItem(
              icon: Icons.error_outline,
              label: 'Alerts',
              selected: selectedPage == 'alerts',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/alerts');
              },
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: selectedPage == 'settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/settings');
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Log out',
                selected: false,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Material(
        color: selected ? const Color(0xFF08C24E) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : const Color(0xFF374151),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
