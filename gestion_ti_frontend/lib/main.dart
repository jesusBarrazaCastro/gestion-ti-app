import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/screens/private/home.dart';
import 'package:gestion_ti_frontend/screens/public/login.dart';
import 'package:gestion_ti_frontend/screens/public/not_found.dart';
import 'package:gestion_ti_frontend/widgets/appbar.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'package:flutter_web_plugins/url_strategy.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  /*
  String? url = '';
  String? key = '';

  final supabase = await Supabase.initialize(
      url: url,
      anonKey: key
  );
*/
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
    ],
    errorPageBuilder: (context, state) => const MaterialPage(
      child: MainLayout(child: NotFound()),
    ),
  );

}

void navigateWithPersistence(BuildContext context, String path) {
  html.window.localStorage['lastPath'] = path;
  context.go(path);
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
