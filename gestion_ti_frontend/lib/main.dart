import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/screens/private/base_screen.dart';
import 'package:gestion_ti_frontend/screens/private/home.dart';
import 'package:gestion_ti_frontend/screens/public/login.dart';
import 'package:gestion_ti_frontend/screens/public/not_found.dart';
import 'package:gestion_ti_frontend/widgets/appbar.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Restro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        iconTheme: const IconThemeData(color: Colors.white),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    // Listen to auth changes to trigger router refresh
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final loggedIn = session != null;
      final loggingIn = state.matchedLocation == '/';

      if (!loggedIn && !loggingIn) {
        // Redirect to login if not logged in
        return '/';
      }
      // No redirect
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Login(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Home';
          return MainLayout(
            child: HomeScreen(title: title),
          );
        },
      ),
      GoRoute(
        path: '/base',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? '';
          return MainLayout(
            child: Base(),
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => const MaterialPage(
      child: MainLayout(child: NotFound()),
    ),
  );

}

/// Helper for GoRouter to refresh on auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners(); // Notify router when auth state changes
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

void navigateWithPersistence(BuildContext context, String path) {
  html.window.localStorage['lastPath'] = path;
  context.go(path);
}

void navigateAndClearStack(BuildContext context, String path) {
  // Pop all routes first
  Navigator.of(context).popUntil((route) => route.isFirst);

  // Then go to the new route
  context.go(path);

  // For web, also replace browser history entry to avoid back
  // This ensures back button won't go to login
  // ignore: avoid_web_libraries_in_flutter
  html.window.history.replaceState(null, '', path);
}


class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                navigateWithPersistence(context, '/home');
                Navigator.of(context).pop(); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

class MyNavigatorObserver extends NavigatorObserver {
  final void Function(String) onNavigate;

  MyNavigatorObserver({required this.onNavigate});

  @override
  void didPush(Route route, Route? previousRoute) {
    _notify(route);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _notify(newRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _notify(previousRoute);
  }

  void _notify(Route? route) {
    if (route is PageRoute) {
      final settings = route.settings;
      onNavigate(settings.name ?? 'desconocida');
    }
  }
}
