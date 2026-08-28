// ignore_for_file: prefer_const_declarations

import 'package:flutter/material.dart';
import 'package:podcastplayer/theme/app_theme.dart';

class WhistilBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const WhistilBottomNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  static const _items = [
    _NavItemData(icon: Icons.menu_book_rounded, label: 'Library'),
    _NavItemData(icon: Icons.home_rounded, label: 'Home'),
    _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: WhistilPalette.primary.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final bool isActive = index == currentIndex;
            final Color activeColor = WhistilPalette.primary;

            return GestureDetector(
              onTap: () => onItemSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 24,
                      color: isActive ? activeColor : WhistilPalette.textSecondary,
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: activeColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.label,
  });
}
