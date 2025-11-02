import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/screens/private/configuracion_gestion_configuraciones.dart';
import 'package:gestion_ti_frontend/screens/private/persona_detail.dart';
import 'package:gestion_ti_frontend/utilities/constants.dart';
import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import 'package:gestion_ti_frontend/widgets/pilltag.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';
import '../../utilities/dialog_util.dart';
import '../../widgets/button.dart';
import '../../widgets/input.dart';

class ConfiguracionGeneral extends StatefulWidget {
  const ConfiguracionGeneral({super.key});

  @override
  State<ConfiguracionGeneral> createState() => _ConfiguracionGeneralState();
}

class _ConfiguracionGeneralState extends State<ConfiguracionGeneral>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(icon: Icon(Icons.build_circle), text: 'Gestión de configuraciones'),
    Tab(icon: Icon(Icons.report_problem_rounded), text: 'Gestión de incidencias'),
    Tab(icon: Icon(Icons.change_circle_rounded), text: 'Gestión de cambios'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _getData();
  }

  _getData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      // TODO: Add your Supabase fetch logic here
    } catch (e) {
      MsgtUtil.showError(context, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _configuracionGestionConfiguraciones() {
    return ConfigGestionConf();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      color: Colors.black,
      progressIndicator: const CircularProgressIndicator(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Configuraciones del sistema',
                  style: AppTheme.light.title1,
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: _tabs,
                    indicator: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    splashBorderRadius: BorderRadius.circular(25),
                    indicatorPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
                    indicatorSize: TabBarIndicatorSize.tab,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // TabBar Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _configuracionGestionConfiguraciones(),
                  const Center(child: Text("🐞 Contenido de Gestión de Incidencias")),
                  const Center(child: Text("🔄 Contenido de Gestión de Cambios")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gestionConfiguraciones(){
    return Column(
      children: [

      ],
    );
  }
}
