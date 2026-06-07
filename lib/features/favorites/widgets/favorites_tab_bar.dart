import 'package:flutter/material.dart';

class FavoritesTabBar extends StatelessWidget {
  final String currentTab;
  final Function(String) onTabChanged;
  final Map<String, int> counts;

  const FavoritesTabBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabs = [
      {'key': 'items', 'label': 'Products'},
      {'key': 'collections', 'label': 'Collections'},
      {'key': 'artisans', 'label': 'Artisans'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: tabs.map((t) {
          final isSelected = currentTab == t['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(t['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.scaffoldBackgroundColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 1)]
                      : [],
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    children: [
                      TextSpan(text: t['label']),
                      TextSpan(
                        text: '  (${counts[t['key']]})',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}