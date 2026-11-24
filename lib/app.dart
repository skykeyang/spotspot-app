import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/group_list_screen.dart';
import 'screens/group_detail_screen.dart';
import 'screens/profile_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authState = ProviderScope.containerOf(context).read(authNotifierProvider);
    final isLoggedIn = authState != null;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute && state.matchedLocation != '/login') {
      return '/login';
    }
    if (isLoggedIn && isLoginRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/groups', builder: (context, state) => const GroupListScreen()),
    GoRoute(path: '/groups/:id', builder: (context, state) => GroupDetailScreen(groupId: state.pathParameters['id']!)),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
);

class SpotSpotApp extends ConsumerWidget {
  const SpotSpotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final user = ref.watch(authNotifierProvider);

    return MaterialApp.router(
      title: 'SpotSpot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD94141),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD94141),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
    );
  }
}