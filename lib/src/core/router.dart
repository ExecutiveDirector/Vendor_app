import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/vendor_dashboard.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/outlets/presentation/outlets_screen.dart';
import '../features/riders/presentation/riders_screen.dart';
import '../features/promotions/presentation/promotions_screen.dart';
import '../features/reviews/presentation/reviews_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/analytics/presentation/analytics_screen.dart';
import '../features/support/presentation/support_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/subscriptions/presentation/subscriptions_screen.dart';

/// Builds the router
GoRouter createRouter() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        GoRoute(
            path: '/dashboard',
            builder: (c, s) => const VendorDashboardScreen()),
        GoRoute(path: '/orders', builder: (c, s) => const OrdersScreen()),
        GoRoute(
          path: '/orders/:id',
          builder: (c, s) => OrderDetailScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(path: '/products', builder: (c, s) => const ProductsScreen()),
        GoRoute(path: '/inventory', builder: (c, s) => const InventoryScreen()),
        GoRoute(path: '/outlets', builder: (c, s) => const OutletsScreen()),
        GoRoute(path: '/riders', builder: (c, s) => const RidersScreen()),
        GoRoute(
            path: '/promotions', builder: (c, s) => const PromotionsScreen()),
        GoRoute(path: '/reviews', builder: (c, s) => const ReviewsScreen()),
        GoRoute(
            path: '/notifications',
            builder: (c, s) => const NotificationsScreen()),
        GoRoute(path: '/analytics', builder: (c, s) => const AnalyticsScreen()),
        GoRoute(path: '/support', builder: (c, s) => const SupportScreen()),
        GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        GoRoute(
            path: '/transactions',
            builder: (c, s) => const TransactionsScreen()),
        GoRoute(
            path: '/subscriptions',
            builder: (c, s) => const SubscriptionsScreen()),
      ],
    );

/// Single global instance for the app
final appRouter = createRouter();
