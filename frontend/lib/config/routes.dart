import 'package:go_router/go_router.dart';

import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_shell.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/product/product_list_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/orders/order_list_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/categories/categories_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // Onboarding
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Auth
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Main shell with bottom nav
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/favorites',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FavoritesScreen(),
          ),
        ),
        GoRoute(
          path: '/cart',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CartScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),

    // Categories
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen(),
    ),

    // Product
    GoRoute(
      path: '/products',
      builder: (context, state) {
        final categoryId = state.uri.queryParameters['categoryId'];
        final title = state.uri.queryParameters['title'] ?? 'Products';
        return ProductListScreen(
          categoryId: categoryId,
          categoryName: title,
        );
      },
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) => ProductDetailScreen(
        productId: state.pathParameters['id']!,
      ),
    ),

    // Search
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),

    // Orders
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrderListScreen(),
    ),
    GoRoute(
      path: '/orders/:id',
      builder: (context, state) => OrderDetailScreen(
        orderId: state.pathParameters['id']!,
      ),
    ),
  ],
);
