import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import '../../app_theme.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';

class ConfigGestionCam extends StatefulWidget {
  const ConfigGestionCam({super.key});

  @override
  State<ConfigGestionCam> createState() => _ConfigGestionCamState();
}

class _ConfigGestionCamState extends State<ConfigGestionCam> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = false;

  // Controladores de formulario
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  // Valores del formulario
  String _tipoCambio = 'Normal';
  String _prioridadCambio = 'Media';
  String _estadoCambio = 'Pendiente';

  final List<String> _tipoCambioOptions = [
    'Normal',
    'Estándar',
    'Urgente',
  ];

  final List<String> _prioridadOptions = [
    'Alta',
    'Media',
    'Baja',
  ];

  final List<String> _estadoCambioOptions = [
    'Pendiente',
    'Aprobado',
    'Rechazado',
    'Implementado',
  ];

  // Lista local de cambios (se llena desde Supabase)
  final List<Map<String, dynamic>> _cambios = [];

  @override
  void initState() {
    super.initState();
    _fetchCambios();
  }

  Future<void> _fetchCambios() async {
  try {
    setState(() {
      _isLoading = true;
    });

    final response = await supabase
        .from('solicitud_cambio')
        .select('id, tipo, prioridad, estado, motivo')
        .eq('registro_estado', true)
        .order('registro_fecha', ascending: false);

    // Asegurarnos de que realmente tenemos una lista
    if (response is! List) {
      // Algo raro regresó Supabase, evitamos crashear la UI
      _cambios.clear();
      setState(() {});
      return;
    }

    final List<dynamic> data = response;

    _cambios
      ..clear()
      ..addAll(
        data.map((row) {
          // Cada row debería ser un Map<String, dynamic>
          return Map<String, dynamic>.from(row as Map);
        }),
      );

    setState(() {});
  } catch (e) {
    MsgtUtil.showError(context, 'Error al obtener cambios: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  Future<void> _guardarCambio() async {
    final titulo = _tituloController.text.trim();
    final descripcion = _descripcionController.text.trim();

    if (titulo.isEmpty || descripcion.isEmpty) {
      MsgtUtil.showWarning(
        context,
        'Título y descripción del cambio son obligatorios.',
      );
      return;
    }

    // Como en la tabla solo tenemos "motivo", vamos a guardar
    // título + descripción en ese campo para no perder info.
    final String motivo = '$titulo - $descripcion';

    try {
      setState(() {
        _isLoading = true;
      });

      // TODO: si ya tienes elemento_id y solicitante_persona_id,
      // agrégalos aquí.
      final insertPayload = {
        'motivo': motivo,
        'tipo': _tipoCambio,
        'prioridad': _prioridadCambio,
        'estado': _estadoCambio,
        'registro_fecha': DateTime.now().toIso8601String(),
        'registro_estado': true,
        // 'elemento_id': <ID_DEL_ELEMENTO>?,
        // 'solicitante_persona_id': <UUID_PERSONA>?,
      };

      final inserted = await supabase
          .from('solicitud_cambio')
          .insert(insertPayload)
          .select('id, tipo, prioridad, estado, motivo')
          .single();

      // Añadimos a la lista local para que se vea inmediatamente
      _cambios.insert(0, Map<String, dynamic>.from(inserted));

      _tituloController.clear();
      _descripcionController.clear();
      _tipoCambio = 'Normal';
      _prioridadCambio = 'Media';
      _estadoCambio = 'Pendiente';

      setState(() {});

      MsgtUtil.showSuccess(context, 'Cambio registrado correctamente.');
    } catch (e) {
      MsgtUtil.showError(context, 'Error al guardar cambio: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<dynamic>> _buildStringDropdownItems(
    List<String> options,
  ) {
    return options
        .map(
          (opt) => DropdownMenuItem<dynamic>(
            value: opt,
            child: Text(opt),
          ),
        )
        .toList();
  }

  Widget _buildFormulario(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del bloque
          const Row(
            children: [
              Text(
                'Registrar nuevo cambio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Título del cambio
          Input(
            controller: _tituloController,
            labelText: 'Título del cambio',
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Descripción
          Input(
            controller: _descripcionController,
            labelText: 'Descripción / Motivo del cambio',
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          // Tipo + Prioridad + Estado
          Row(
            children: [
              Expanded(
                child: Dropdown(
                  labelText: 'Tipo de cambio',
                  value: _tipoCambio,
                  items: _buildStringDropdownItems(_tipoCambioOptions),
                  onChanged: (value) {
                    setState(() {
                      _tipoCambio = value as String;
                    });
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Dropdown(
                  labelText: 'Prioridad',
                  value: _prioridadCambio,
                  items: _buildStringDropdownItems(_prioridadOptions),
                  onChanged: (value) {
                    setState(() {
                      _prioridadCambio = value as String;
                    });
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Dropdown(
                  labelText: 'Estado',
                  value: _estadoCambio,
                  items: _buildStringDropdownItems(_estadoCambioOptions),
                  onChanged: (value) {
                    setState(() {
                      _estadoCambio = value as String;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTablaCambios() {
    if (_cambios.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text(
          'No hay cambios registrados.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Motivo')),
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('Prioridad')),
          DataColumn(label: Text('Estado')),
        ],
        rows: _cambios.map((cambio) {
          return DataRow(
            cells: [
              DataCell(Text('${cambio['id']}')),
              DataCell(Text('${cambio['motivo'] ?? ''}')),
              DataCell(Text('${cambio['tipo'] ?? ''}')),
              DataCell(Text('${cambio['prioridad'] ?? ''}')),
              DataCell(Text('${cambio['estado'] ?? ''}')),
            ],
          );
        }).toList(),
      ),
    );
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
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CONTENIDO SCROLLEABLE
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        'Gestión de cambios',
                        style: AppTheme.light.title1,
                      ),
                      const SizedBox(height: 16),

                      // Formulario
                      _buildFormulario(context),

                      // Tabla de cambios registrados
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cambios registrados',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: _fetchCambios,
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: 'Actualizar lista',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTablaCambios(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 3),
            const Divider(),
            const SizedBox(height: 3),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Button(
                  width: 180,
                  icon: Icons.save,
                  text: 'Guardar cambio',
                  onPressed: _guardarCambio,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
