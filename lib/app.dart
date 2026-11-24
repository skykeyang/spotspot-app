import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/group_detail_screen.dart';

final _routerRefreshNotifier = ChangeNotifier();
void notifyRouterRefresh() => _routerRefreshNotifier.notifyListeners();

final goRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: _routerRefreshNotifier,
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context);
    final isLoggedIn = container.read(authNotifierProvider) != null;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/', builder: (context, state) => const MainShell()),
    GoRoute(path: '/groups/:id', builder: (context, state) => GroupDetailScreen(groupId: state.pathParameters['id']!)),
  ],
);

class SpotSpotApp extends ConsumerWidget {
  const SpotSpotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state to trigger router refresh on changes
    ref.watch(authStateProvider);
    final user = ref.watch(authNotifierProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null) notifyRouterRefresh();
    });

    return MaterialApp.router(
      title: 'SpotSpot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD94141)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD94141), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.light,
      routerConfig: goRouter,
    );
  }
}