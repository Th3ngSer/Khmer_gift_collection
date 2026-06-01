import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/main_navigation_scaffold.dart';
import '../../features/home/screens/splash_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/nearby/screens/nearby_screen.dart';
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/quiz/screens/quiz_results_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Content',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

final goRouter = GoRouter(
  initialLocation: '/', 
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: '/quiz',
      builder: (context, state) => const QuizScreen(),
    ),

    GoRoute(
      path: '/quiz/results',
      builder: (context, state) => const QuizResultsScreen(),
    ),

    GoRoute(
      path: '/products/:id',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return ProductDetailScreen(productId: productId);
      },
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 2: Nearby
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/nearby',
              builder: (context, state) => const NearbyScreen(),
            ),
          ],
        ),
        // Tab 3: Saved (Favorites)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const PlaceholderScreen(title: 'Favorites'),
            ),
          ],
        ),
        // Tab 4: Chat
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const PlaceholderScreen(title: 'Chat Messages'),
            ),
          ],
        ),
        // Tab 5: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const PlaceholderScreen(title: 'Your Profile'),
            ),
          ],
        ),
      ],
    ),
  ],
);