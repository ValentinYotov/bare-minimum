import 'package:flutter/material.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  const TopNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8F8F8),
      surfaceTintColor: const Color(0xFFF8F8F8),
      elevation: 1,
      leading: Builder(
        builder: (context) => IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu, color: Color(0xFF111827)),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
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
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_outlined,
                color: Color(0xFF111827),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A00),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}