import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/app_theme.dart';
import 'package:gestion_ti_frontend/screens/private/configuracion_gestion_cambio.dart';
import 'package:gestion_ti_frontend/screens/private/base_screen.dart';
import 'package:gestion_ti_frontend/screens/private/configuracion_general.dart';
import 'package:gestion_ti_frontend/screens/private/departamentos.dart';
import 'package:gestion_ti_frontend/screens/private/elemento_configuracion_detail.dart';
import 'package:gestion_ti_frontend/screens/private/elementos_configuracion.dart';
import 'package:gestion_ti_frontend/screens/private/home.dart';
import 'package:gestion_ti_frontend/screens/private/incidencia_detail.dart';
import 'package:gestion_ti_frontend/screens/private/solicitud_cambio_detail.dart';
import 'package:gestion_ti_frontend/screens/private/incidencia_list.dart';
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
      title: 'SGTI',
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
            child: ConfiguracionGeneral(),
          );
        },
      ),
      GoRoute(
        path: '/elementos_configuracion',
        builder: (context, state) {
          return MainLayout(
            child: ElementosConfiguracion(),
          );
        },
      ),GoRoute(
        path: '/gestion_cambios',
        builder: (context, state) {
          return MainLayout(
            child: ConfigGestionCam(),
          );
        },
      ),
      GoRoute(
        path: '/gestion_incidencias',
        builder: (context, state) {
          return MainLayout(
            child: Incidencias(),
          );
        },
      ),
      GoRoute(
        path: '/incidencia_detail/:id', // :id es el parámetro opcional para edición
        builder: (context, state) {
          // 1. Obtener el ID de Incidencia (parámetro de ruta)
          final String? incidenciaIdStr = state.pathParameters['id'];
          final int? incidenciaId = incidenciaIdStr != 'nuevo' ? int.tryParse(incidenciaIdStr ?? '') : null;

          // 2. Obtener el ID del Elemento de Configuración (query parameter)
          // Se usa 'elementoId' en minúsculas para consistencia con la URL
          final String? elementoIdStr = state.uri.queryParameters['elementoId'];
          final int? elementoId = int.tryParse(elementoIdStr ?? '');

          return MainLayout( // Asumo que quieres mantener el layout
            child: IncidenciaDetail(
              incidenciaId: incidenciaId,
              elementoId: elementoId, // <<-- PASAMOS EL NUEVO PARÁMETRO
            ),
          );
        },
      ),
      GoRoute(
        path: '/solicitud_cambio_detail/:id',
        builder: (context, state) {
          final idParam = state.pathParameters['id']!;
          final bool esNuevo = idParam == 'nuevo';

          final elementoIdParam = state.uri.queryParameters['elementoId'];
          final int? elementoId =
              elementoIdParam != null ? int.tryParse(elementoIdParam) : null;

          return MainLayout(
            child: SolicitudCambioDetail(
              solicitudCambioId: esNuevo ? null : int.tryParse(idParam),
              elementoId: elementoId,
            ),
          );
        },
      ),

      GoRoute(
        path: '/elementos_configuracion_form/:id', // :id es el parámetro opcional para edición
        builder: (context, state) {
          // Obtenemos el ID de la ruta. Si no existe, es null (creación)
          final String? elementoIdStr = state.pathParameters['id'];
          final int? elementoId = elementoIdStr != 'nuevo' ? int.tryParse(elementoIdStr ?? '') : null;

          return MainLayout( // Asumo que quieres mantener el layout
            child: ElementoForm(elementoId: elementoId),
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
              child: Builder(
                builder: (context) {
                  Widget buildMenuItem({
                    required String label,
                    required String path,
                    required IconData icon,
                  }) {
                    final currentPath = GoRouterState.of(context).uri.toString();
                    final bool isActive = currentPath == path;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.indigo.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(icon,
                            color: isActive ? Colors.indigo : Colors.indigo.shade400,
                            size: 28),
                        title: Text(
                          label,
                          style: AppTheme.light.body.copyWith(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? Colors.indigo.shade800 : Colors.black87,
                          ),
                        ),
                        onTap: () {
                          if (!isActive) {
                            navigateWithPersistence(context, path);
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  }

                  return ListView(
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
                      const SizedBox(height: 30),

                      // Menu items
                      buildMenuItem(
                        label: 'Inicio',
                        path: '/home',
                        icon: Icons.home,
                      ),
                      buildMenuItem(
                        label: 'Gestión de incidencias',
                        path: '/gestion_incidencias',
                        icon: Icons.warning,
                      ),
                      buildMenuItem(
                        label: 'Gestión de configuraciones',
                        path: '/elementos_configuracion',
                        icon: Icons.computer_outlined,
                      ), 
                      buildMenuItem(
                        label: 'Gestión de Cambios',
                        path: '/gestion_cambios',
                        icon: Icons.change_circle_rounded,
                      ),
                      buildMenuItem(
                        label: 'Ubicaciones',
                        path: '/departamentos',
                        icon: Icons.apartment,
                      ),
                      buildMenuItem(
                        label: 'Usuarios',
                        path: '/users',
                        icon: Icons.people,
                      ),
                      buildMenuItem(
                        label: 'Configuración general',
                        path: '/configuraciones',
                        icon: Icons.settings,
                      ),
                    ],
                  );
                },
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
