import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';
import '../../utilities/msg_util.dart';

class SolicitudCambioList extends StatefulWidget {
  const SolicitudCambioList({super.key});

  @override
  State<SolicitudCambioList> createState() => _SolicitudCambioListState();
}

class _SolicitudCambioListState extends State<SolicitudCambioList> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = false;
  List<Map<String, dynamic>> _solicitudes = [];

  @override
  void initState() {
    super.initState();
    _fetchSolicitudes();
  }

  Future<void> _fetchSolicitudes() async {
    try {
      setState(() => _isLoading = true);

      final response = await supabase
          .from('solicitud_cambio')
          .select('id, tipo, prioridad, estado, motivo, registro_fecha, elemento_configuracion:elemento_id(clave)')
          .order('registro_fecha', ascending: false);

      _solicitudes =
          List<Map<String, dynamic>>.from(response as List<dynamic>);
      setState(() {});
    } catch (e) {
      MsgtUtil.showError(context, 'Error al obtener solicitudes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      color: Colors.black,
      progressIndicator: const CircularProgressIndicator(),
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 12, right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestión de cambios', style: AppTheme.light.title1),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitudes de cambio',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: _fetchSolicitudes,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _solicitudes.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay solicitudes registradas.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('CI')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Prioridad')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Motivo')),
                        ],
                        rows: _solicitudes.map((sol) {
                          final id = sol['id'];
                          final ciClave =
                              sol['elemento_configuracion']?['clave'] ??
                                  'N/A';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text('$id'),
                                onTap: () {
                                  context.go('/gestion_cambios/$id');
                                },
                              ),
                              DataCell(
                                Text(ciClave),
                                onTap: () {
                                  context.go('/gestion_cambios/$id');
                                },
                              ),
                              DataCell(Text('${sol['tipo']}')),
                              DataCell(Text('${sol['prioridad']}')),
                              DataCell(Text('${sol['estado']}')),
                              DataCell(
                                SizedBox(
                                  width: 250,
                                  child: Text(
                                    '${sol['motivo']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
