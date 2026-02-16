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
import '../screens/admin/admin_shell.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_vendors_screen.dart';
import '../screens/admin/admin_vendor_detail_screen.dart';
import '../screens/admin/admin_orders_screen.dart';
import '../screens/admin/admin_order_detail_screen.dart';
import '../screens/admin/admin_customers_screen.dart';
import '../screens/admin/admin_categories_screen.dart';
import '../screens/admin/admin_products_screen.dart';
import '../screens/admin/admin_transactions_screen.dart';
import '../screens/admin/admin_coupons_screen.dart';
import '../screens/admin/admin_payouts_screen.dart';
import '../screens/admin/admin_reviews_screen.dart';
import '../screens/admin/admin_settings_screen.dart';

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

    // Admin panel with sidebar shell
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/vendors',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminVendorsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/vendors/:id',
          pageBuilder: (context, state) => NoTransitionPage(
            child: AdminVendorDetailScreen(
              vendorId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/admin/orders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminOrdersScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/orders/:id',
          pageBuilder: (context, state) => NoTransitionPage(
            child: AdminOrderDetailScreen(
              orderId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/admin/customers',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminCustomersScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/categories',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminCategoriesScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/products',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminProductsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/transactions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminTransactionsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/payouts',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminPayoutsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/coupons',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminCouponsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/reviews',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminReviewsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: AdminSettingsScreen(),
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
