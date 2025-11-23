import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/app_theme.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Asumo que tienes estas utilidades y widgets en tu proyecto:
import '../utilities/msg_util.dart';
import 'button.dart';
import 'dropdown.dart'; // Tu widget Dropdown personalizado

// Definición para el tipo de datos (para claridad)
typedef LocationData = Map<String, dynamic>;

// Objeto estático que representa la opción "Todos"
const LocationData _allOption = {
  'id': null,
  'nombre': 'Todos',
  'departamento_id': null,
  'edificio_id': null,
  'ubicacion_id': null,
  'departamento_nombre': 'Todos los departamentos',
  'edificio_nombre': 'Todos los edificios',
  'ubicacion_nombre': 'Todas las ubicaciones',
};

class LocationSelectionDialog extends StatefulWidget {
  final LocationData? initialLocation;

  const LocationSelectionDialog({super.key, this.initialLocation});

  @override
  State<LocationSelectionDialog> createState() => _LocationSelectionDialogState();
}

class _LocationSelectionDialogState extends State<LocationSelectionDialog> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  LocationData? _departamentoSelected;
  List<LocationData> _departamentoItems = [];
  LocationData? _edificioSelected;
  List<LocationData> _edificioItems = [];
  LocationData? _ubicacionSelected;
  List<LocationData> _ubicacionItems = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // ===========================================================================
  // CARGA INICIAL Y PRECARGA DE DATOS (Soporte para null/Todos)
  // ===========================================================================
  Future<void> _loadInitialData() async {
    // 1. Cargar todos los departamentos con la opción "Todos"
    await _loadDepartamentos();

    if (!mounted) return;

    // 2. Si hay una ubicación inicial (precarga), seleccionarla y cargar sus hijos
    if (widget.initialLocation != null) {
      final initial = widget.initialLocation!;

      try {
        final initialDepartamentoId = initial['departamento_id'];

        // Seleccionar Departamento (maneja ID nulo o específico)
        _departamentoSelected = _departamentoItems.firstWhere(
              (item) => item['id'] == initialDepartamentoId,
          //orElse: () => null as LocationData?,
        );

        if (_departamentoSelected != null) {
          // Cargar edificios del departamento inicial (puede ser null/Todos)
          await _loadEdificios(initialDepartamentoId as int?);

          final initialEdificioId = initial['edificio_id'];

          // Seleccionar Edificio (maneja ID nulo o específico)
          if (_edificioItems.isNotEmpty) {
            _edificioSelected = _edificioItems.firstWhere(
                  (item) => item['id'] == initialEdificioId,
              //orElse: () => null as LocationData?,
            );
          }

          if (_edificioSelected != null) {
            // Cargar ubicaciones del edificio inicial (puede ser null/Todos)
            await _loadUbicaciones(initialEdificioId as int?);

            final initialUbicacionId = initial['ubicacion_id'];

            // Seleccionar Ubicación (maneja ID nulo o específico)
            if (_ubicacionItems.isNotEmpty) {
              _ubicacionSelected = _ubicacionItems.firstWhere(
                    (item) => item['id'] == initialUbicacionId,
                //orElse: () => null as LocationData?,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error durante la precarga: $e');
      }

      if (mounted) setState(() {});
    } else {
      // Si no hay precarga, selecciona "Todos" por defecto en el primer dropdown
      if (_departamentoItems.isNotEmpty) {
        _departamentoSelected = _departamentoItems.firstWhere(
              (item) => item['id'] == null,
          //orElse: () => null as LocationData?,
        );
        // Carga Edificios para la opción 'Todos' si existe la opción
        if (_departamentoSelected != null) {
          await _loadEdificios(_departamentoSelected!['id'] as int?);
        }
      }
    }
  }

  // ===========================================================================
  // FUNCIONES DE CARGA DE SUPABASE (CASCADA con inyección de "Todos")
  // ===========================================================================
  Future<void> _loadDepartamentos() async {
    try {
      if (mounted) setState(() => _isLoading = true);
      final data = await supabase
          .from('departamento')
          .select('id, nombre')
          .eq('registro_estado', true)
          .order('nombre', ascending: true);

      final List<LocationData> loadedItems = [
        _allOption.copyWith({'nombre': _allOption['departamento_nombre']})
      ];
      loadedItems.addAll(List<LocationData>.from(data));
      _departamentoItems = loadedItems;

    } catch (e) {
      if (mounted) MsgtUtil.showError(context, 'Error cargando departamentos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEdificios(int? departamentoId) async {
    if (departamentoId == null) {
      if (mounted) setState(() {
        _edificioItems = [_allOption.copyWith({'nombre': _allOption['edificio_nombre']})];
        _edificioSelected = _edificioItems.first;
        _ubicacionItems = [_allOption.copyWith({'nombre': _allOption['ubicacion_nombre']})];
        _ubicacionSelected = _ubicacionItems.first;
      });
      return;
    }

    try {
      if (mounted) setState(() => _isLoading = true);
      final data = await supabase
          .from('edificio')
          .select('id, nombre, departamento_id')
          .eq('departamento_id', departamentoId)
          .eq('registro_estado', true)
          .order('nombre', ascending: true);

      if (mounted) setState(() {
        final List<LocationData> loadedItems = [
          _allOption.copyWith({'nombre': _allOption['edificio_nombre']})
        ];
        loadedItems.addAll(List<LocationData>.from(data));

        _edificioItems = loadedItems;
        _edificioSelected = _edificioItems.first; // Seleccionar "Todos" por defecto
        _ubicacionItems = [_allOption.copyWith({'nombre': _allOption['ubicacion_nombre']})];
        _ubicacionSelected = _ubicacionItems.first;
      });
    } catch (e) {
      if (mounted) MsgtUtil.showError(context, 'Error cargando edificios: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUbicaciones(int? edificioId) async {
    if (edificioId == null) {
      if (mounted) setState(() {
        _ubicacionItems = [_allOption.copyWith({'nombre': _allOption['ubicacion_nombre']})];
        _ubicacionSelected = _ubicacionItems.first;
      });
      return;
    }

    try {
      if (mounted) setState(() => _isLoading = true);
      final data = await supabase
          .from('ubicacion_lugar')
          .select('id, nombre, edificio_id')
          .eq('edificio_id', edificioId)
          .eq('registro_estado', true)
          .order('nombre', ascending: true);

      if (mounted) setState(() {
        final List<LocationData> loadedItems = [
          _allOption.copyWith({'nombre': _allOption['ubicacion_nombre']})
        ];
        loadedItems.addAll(List<LocationData>.from(data));

        _ubicacionItems = loadedItems;
        _ubicacionSelected = _ubicacionItems.first; // Seleccionar "Todos" por defecto
      });
    } catch (e) {
      if (mounted) MsgtUtil.showError(context, 'Error cargando ubicaciones: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // MANEJO DE SELECCIONES
  // ===========================================================================
  void _onDepartamentoChanged(LocationData? value) {
    if (value == null) return;

    setState(() {
      _departamentoSelected = value;
      _edificioItems = [];
      _edificioSelected = null;
      _ubicacionItems = [];
      _ubicacionSelected = null;
    });
    // Si el ID es null, se cargará la opción "Todos" en el siguiente nivel
    _loadEdificios(value['id'] as int?);
  }

  void _onEdificioChanged(LocationData? value) {
    if (value == null) return;

    setState(() {
      _edificioSelected = value;
      _ubicacionItems = [];
      _ubicacionSelected = null;
    });
    // Si el ID es null, se cargará la opción "Todos" en el siguiente nivel
    _loadUbicaciones(value['id'] as int?);
  }

  void _onUbicacionChanged(LocationData? value) {
    setState(() {
      _ubicacionSelected = value;
    });
  }

  void _saveSelection() {
    if (_departamentoSelected == null || _edificioSelected == null || _ubicacionSelected == null) {
      MsgtUtil.showError(context, 'Error de selección. Por favor, intente de nuevo.');
      return;
    }

    // Devolver un mapa completo, permitiendo que los IDs sean nulos si se seleccionó "Todos"
    final result = {
      'departamento_id': _departamentoSelected!['id'] as int?,
      'departamento_nombre': _departamentoSelected!['nombre'] as String?,
      'edificio_id': _edificioSelected!['id'] as int?,
      'edificio_nombre': _edificioSelected!['nombre'] as String?,
      'ubicacion_id': _ubicacionSelected!['id'] as int?,
      'ubicacion_nombre': _ubicacionSelected!['nombre'] as String?,
    };

    Navigator.pop(context, result);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  List<DropdownMenuItem<LocationData>> _buildDropdownItems(List<LocationData> data) {
    return data.map<DropdownMenuItem<LocationData>>((item) {
      // Usar el campo 'nombre' que ya está configurado con "Todos" o el nombre de la DB
      return DropdownMenuItem<LocationData>(
        value: item,
        child: Text(item['nombre'] ?? 'Sin Nombre'),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ModalProgressHUD(
        inAsyncCall: _isLoading,
        color: Colors.black,
        progressIndicator: const CircularProgressIndicator(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                // --- Dropdown Departamento ---
                Dropdown<LocationData>(
                    labelText: 'Departamento',
                    value: _departamentoSelected,
                    items: _buildDropdownItems(_departamentoItems),
                    onChanged: _onDepartamentoChanged
                ),

                // --- Dropdown Edificio ---
                const SizedBox(height: 20),
                Dropdown<LocationData>(
                    labelText: 'Edificio',
                    value: _edificioSelected,
                    items: _buildDropdownItems(_edificioItems),
                    onChanged: _onEdificioChanged,
                    enabled: _departamentoSelected?['id'] != null ||
                        (_departamentoSelected != null && _edificioItems.isNotEmpty)
                ),

                // --- Dropdown Ubicación ---
                const SizedBox(height: 20),
                Dropdown<LocationData>(
                    labelText: 'Ubicación',
                    value: _ubicacionSelected,
                    items: _buildDropdownItems(_ubicacionItems),
                    onChanged: _onUbicacionChanged,
                    enabled: _edificioSelected?['id'] != null ||
                        (_edificioSelected != null && _ubicacionItems.isNotEmpty)
                ),

                const Spacer(),
                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Button(
                      width: 150,
                      onPressed:  _saveSelection,
                      text: 'Seleccionar',
                      icon: Icons.check_circle,
                      backgroundColor: AppTheme.light.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Extensión necesaria para el método copyWith, permitiendo actualizar solo el nombre
extension on LocationData {
  LocationData copyWith(Map<String, dynamic> changes) {
    return Map.from(this)..addAll(changes);
  }
}