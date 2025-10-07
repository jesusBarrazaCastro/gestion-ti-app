import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/app_theme.dart';
import 'package:gestion_ti_frontend/screens/private/base_screen.dart';
import 'package:gestion_ti_frontend/screens/private/departamentos.dart';
import 'package:gestion_ti_frontend/screens/private/home.dart';
import 'package:gestion_ti_frontend/screens/private/personas.dart';
import 'package:gestion_ti_frontend/screens/public/login.dart';
import 'package:gestion_ti_frontend/screens/public/not_found.dart';
import 'package:gestion_ti_frontend/widgets/appbar.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
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
      GoRoute(
        path: '/users',
        builder: (context, state) {
          return MainLayout(
            child: Personas(),
          );
        },
      ),
      GoRoute(
        path: '/departamentos',
        builder: (context, state) {
          return MainLayout(
            child: Departamentos(),
          );
        },
      ),
      GoRoute(
        path: '/configuraciones',
        builder: (context, state) {
          return MainLayout(
            child: Departamentos(),
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

Future<Map<String, String>> _loadUserData() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'name': prefs.getString('user_name') ?? 'Usuario Desconocido',
    'role': prefs.getString('role') ?? 'No Asignado',
  };
}


class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  Widget build(BuildContext context) {
    const double iconSize = 28.0;

    return FutureBuilder(
      future: _loadUserData(),
      builder: (context, snapshot) {
        String userName = 'Cargando...';
        String userRole = 'Cargando...';

        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          userName = snapshot.data!['name']!;
          userRole = snapshot.data!['role']!.toUpperCase();
        } else if (snapshot.hasError) {
          userName = 'Error de Carga';
          userRole = 'Intente de nuevo';
        }


        return Scaffold(
          appBar: CustomAppBar(),
          drawer: Drawer(
            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF283593)], // navy shades
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 34,
                          child: Icon(Icons.person, color: Colors.white, size: 34),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userRole,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40,),
                  // Inicio
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.indigo, size: iconSize),
                    title: Text('Inicio', style: AppTheme.light.body),
                    onTap: () {
                      navigateWithPersistence(context, '/home');
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.computer_outlined, color: Colors.indigo, size: iconSize),
                    title:  Text('Gestión de configuraciones', style: AppTheme.light.body),
                    onTap: () {
                      navigateWithPersistence(context, '/configuraciones');
                      Navigator.of(context).pop();
                    },
                  ),
                  // Ubicaciones
                  ListTile(
                    leading: const Icon(Icons.apartment, color: Colors.indigo, size: iconSize),
                    title:  Text('Ubicaciones', style: AppTheme.light.body),
                    onTap: () {
                      navigateWithPersistence(context, '/departamentos');
                      Navigator.of(context).pop();
                    },
                  ),
                  // Usuarios
                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.indigo, size: iconSize),
                    title:  Text('Usuarios', style: AppTheme.light.body),
                    onTap: () {
                      navigateWithPersistence(context, '/users');
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.indigo, size: iconSize), // Usa el color principal aquí
                    title:  Text('Configuraciones', style: AppTheme.light.body),
                    onTap: () {
                      Navigator.of(context).pop(); // Cierra el drawer aunque no haya navegación
                    },
                  ),

                  // Un poco de espacio extra al final
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(10.0),
            child: child,
          ),
        );
      },
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
