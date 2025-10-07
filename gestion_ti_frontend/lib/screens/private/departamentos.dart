import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

// Utilidades personalizadas
import 'package:gestion_ti_frontend/utilities/constants.dart';
import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import '../../app_theme.dart';
import '../../utilities/confirm_dialog_util.dart';
import '../../utilities/dialog_util.dart';
import '../../widgets/button.dart';
import '../../widgets/input.dart';

class Departamentos extends StatefulWidget {
  const Departamentos({super.key});

  @override
  State<Departamentos> createState() => _DepartamentosState();
}

class _DepartamentosState extends State<Departamentos> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  List<Map<String, dynamic>> _departamentos = [];
  dynamic _selectedDepartamento;

  List<Map<String, dynamic>> _edificios = [];
  dynamic _selectedEdificio;

  List<Map<String, dynamic>> _ubicaciones = [];

  @override
  void initState() {
    _loadDepartamentos();
    super.initState();
  }

  // ===========================================================================
  // CARGA DE DATOS
  // ===========================================================================
  Future<void> _loadDepartamentos() async {
    try {
      setState(() => _isLoading = true);
      final data = await supabase
          .from('departamento')
          .select('id, nombre, descripcion')
          .eq('registro_estado', true)
          .order('nombre', ascending: true);
      setState(() {
        _departamentos = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      MsgtUtil.showError(context, 'Error cargando departamentos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEdificios(int departamentoId) async {
    try {
      final data = await supabase
          .from('edificio')
          .select('id, nombre, descripcion')
          .eq('departamento_id', departamentoId)
          .eq('registro_estado', true)
          .order('nombre', ascending: true);
      setState(() {
        _edificios = List<Map<String, dynamic>>.from(data);
        _ubicaciones = [];
      });
    } catch (e) {
      MsgtUtil.showError(context, 'Error cargando edificios: $e');
    }
  }

  Future<void> _loadUbicaciones(int edificioId) async {
    try {
      final data = await supabase
          .from('ubicacion_lugar')
          .select('id, nombre, descripcion')
          .eq('edificio_id', edificioId)
          .eq('registro_estado', true)
          .order('nombre', ascending: true);
      setState(() {
        _ubicaciones = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      MsgtUtil.showError(context, 'Error cargando ubicaciones: $e');
    }
  }

  // ===========================================================================
  // SELECCIONES
  // ===========================================================================
  void _selectDepartamento(Map<String, dynamic> depto) {
    if (_selectedDepartamento?['id'] == depto['id']) {
      _clearDepartamentoSelection();
      return;
    }
    setState(() {
      _selectedDepartamento = depto;
      _selectedEdificio = null;
      _edificios = [];
      _ubicaciones = [];
    });
    _loadEdificios(depto['id']);
  }

  void _selectEdificio(Map<String, dynamic> edificio) {
    if (_selectedEdificio?['id'] == edificio['id']) {
      _clearEdificioSelection();
      return;
    }
    setState(() {
      _selectedEdificio = edificio;
      _ubicaciones = [];
    });
    _loadUbicaciones(edificio['id']);
  }

  void _clearDepartamentoSelection() {
    setState(() {
      _selectedDepartamento = null;
      _selectedEdificio = null;
      _edificios = [];
      _ubicaciones = [];
    });
  }

  void _clearEdificioSelection() {
    setState(() {
      _selectedEdificio = null;
      _ubicaciones = [];
    });
  }

  // ===========================================================================
  // CRUD PRINCIPAL
  // ===========================================================================

  void _onAddPressed(String header) {
    if (header.startsWith('Departamentos')) {
      _showFormDialog('departamento');
    } else if (header.startsWith('Edificios')) {
      if (_selectedDepartamento == null) {
        MsgtUtil.showError(context, 'Seleccione un departamento primero.');
        return;
      }
      _showFormDialog('edificio');
    } else if (header.startsWith('Ubicaciones')) {
      if (_selectedEdificio == null) {
        MsgtUtil.showError(context, 'Seleccione un edificio primero.');
        return;
      }
      _showFormDialog('ubicacion');
    }
  }

  void _showFormDialog(String tipo, {Map<String, dynamic>? existing}) {
    final nombreController = TextEditingController(text: existing?['nombre'] ?? '');
    final descripcionController = TextEditingController(text: existing?['descripcion'] ?? '');

    DialogUtil.showCustomDialog(
      context: context,
      title: existing == null ? 'Agregar ${tipo.capitalize()}' : 'Editar ${tipo.capitalize()}',
      width: MediaQuery.sizeOf(context).width * 0.4,
      showCloseButton: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Input(labelText: 'Nombre', controller: nombreController),
          const SizedBox(height: 10),
          Input(labelText: 'Descripción', controller: descripcionController),
          const Spacer(),
          Row(
            children: [
              Button(
                width: 130,
                text: 'Guardar',
                icon: Icons.save,
                onPressed: () async{
                  final nombre = nombreController.text.trim();
                  final descripcion = descripcionController.text.trim();
                  if (nombre.isEmpty) {
                    MsgtUtil.showError(context, 'El nombre es obligatorio.');
                    return;
                  }
                  Navigator.pop(context);
                  await _addOrEditRecord(tipo, nombre, descripcion, existing);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _addOrEditRecord(
      String tipo, String nombre, String descripcion, Map<String, dynamic>? existing) async {
    try {
      setState(() => _isLoading = true);

      String table;
      Map<String, dynamic> values = {
        'nombre': nombre,
        'descripcion': descripcion,
        'registro_estado': true,
      };

      switch (tipo) {
        case 'departamento':
          table = 'departamento';
          break;
        case 'edificio':
          table = 'edificio';
          values['departamento_id'] = _selectedDepartamento!['id'];
          break;
        case 'ubicacion':
          table = 'ubicacion_lugar';
          values['edificio_id'] = _selectedEdificio!['id'];
          break;
        default:
          throw Exception('Tipo desconocido: $tipo');
      }

      if (existing == null) {
        await supabase.from(table).insert(values);
        MsgtUtil.showSuccess(context, 'Registro agregado correctamente.');
      } else {
        await supabase.from(table).update(values).eq('id', existing['id']);
        MsgtUtil.showSuccess(context, 'Registro actualizado correctamente.');
      }

      // Recargar lista correspondiente
      if (tipo == 'departamento') {
        await _loadDepartamentos();
      } else if (tipo == 'edificio') {
        await _loadEdificios(_selectedDepartamento!['id']);
      } else if (tipo == 'ubicacion') {
        await _loadUbicaciones(_selectedEdificio!['id']);
      }
    } catch (e) {
      MsgtUtil.showError(context, 'Error al guardar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord(String tipo, int id) async {
    final confirmed = await ConfirmDialog.confirm(
      context,
      title: 'Eliminar registro',
      message: '¿Seguro que deseas eliminar este registro?',
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      String table;
      switch (tipo) {
        case 'departamento':
          table = 'departamento';
          break;
        case 'edificio':
          table = 'edificio';
          break;
        case 'ubicacion':
          table = 'ubicacion_lugar';
          break;
        default:
          throw Exception('Tipo desconocido: $tipo');
      }

      await supabase.from(table).update({'registro_estado': false}).eq('id', id);
      MsgtUtil.showSuccess(context, 'Registro eliminado.');

      if (tipo == 'departamento') {
        await _loadDepartamentos();
      } else if (tipo == 'edificio') {
        await _loadEdificios(_selectedDepartamento!['id']);
      } else {
        await _loadUbicaciones(_selectedEdificio!['id']);
      }
    } catch (e) {
      MsgtUtil.showError(context, 'Error al eliminar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // LISTAS (COMPONENTE REUTILIZABLE)
  // ===========================================================================
  Widget _buildList({
    required List<Map<String, dynamic>> data,
    required String titleKey,
    required Map<String, dynamic>? selectedItem,
    required Function(Map<String, dynamic>) onTap,
    required String header,
    required String emptyMessage,
    VoidCallback? onClearSelection,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(header,
                    style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Button(
                      width: 130,
                      height: 30,
                      text: 'Agregar',
                      icon: Icons.add,
                      onPressed: () => _onAddPressed(header),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista
          Expanded(
            child: data.isEmpty
                ? Center(child: Text(emptyMessage))
                : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final isSelected = selectedItem?['id'] == item['id'];

                return ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          item[titleKey]?.toString() ?? '',
                          style:
                          const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['descripcion']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showFormDialog(
                          header.toLowerCase().contains('departamento')
                              ? 'departamento'
                              : header.toLowerCase().contains('edificio')
                              ? 'edificio'
                              : 'ubicacion',
                          existing: item,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            size: 18, color: Colors.red),
                        onPressed: () => _deleteRecord(
                          header.toLowerCase().contains('departamento')
                              ? 'departamento'
                              : header.toLowerCase().contains('edificio')
                              ? 'edificio'
                              : 'ubicacion',
                          item['id'],
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  selectedTileColor: Colors.indigo.withOpacity(0.1),
                  onTap: () => onTap(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD PRINCIPAL
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      color: Colors.black,
      progressIndicator: const CircularProgressIndicator(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestión de Ubicaciones', style: AppTheme.light.title1),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Departamentos
                  Expanded(
                    child: _buildList(
                      data: _departamentos,
                      titleKey: 'nombre',
                      selectedItem: _selectedDepartamento,
                      onTap: _selectDepartamento,
                      header: 'Departamentos',
                      emptyMessage: 'No hay departamentos disponibles.',
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Edificios
                  Expanded(
                    child: _selectedDepartamento == null
                        ? const Center(
                        child: Text('← Seleccione un Departamento'))
                        : _buildList(
                      data: _edificios,
                      titleKey: 'nombre',
                      selectedItem: _selectedEdificio,
                      onTap: _selectEdificio,
                      header:
                      'Edificios de ${_selectedDepartamento!['nombre']}',
                      emptyMessage:
                      'No hay edificios para este departamento.',
                      onClearSelection: _clearDepartamentoSelection,
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Ubicaciones
                  Expanded(
                    child: _selectedEdificio == null
                        ? const Center(child: Text('← Seleccione un Edificio'))
                        : _buildList(
                      data: _ubicaciones,
                      titleKey: 'nombre',
                      selectedItem: null,
                      onTap: (_) {},
                      header:
                      'Ubicaciones en ${_selectedEdificio!['nombre']}',
                      emptyMessage:
                      'No hay ubicaciones para este edificio.',
                      onClearSelection: _clearEdificioSelection,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// UTILIDAD OPCIONAL (SI NO EXISTE YA EN TU PROYECTO)
// ===========================================================================
extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}
