import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationScaffold extends StatelessWidget {
  const MainNavigationScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        // Using Material 3 NavigationBar with your custom gold accent
        indicatorColor: const Color(0xFFD4AF37).withOpacity(0.15),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFFD4AF37)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on, color: Color(0xFFD4AF37)),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view, color: Color(0xFFD4AF37)),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFFD4AF37)),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFD4AF37)),
            label: 'You',
          ),
        ],
      ),
    );
  }
}