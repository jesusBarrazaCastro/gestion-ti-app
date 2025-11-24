import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Asumiendo que estos son los imports de tus componentes y utilidades
import '../../app_theme.dart';
import '../../utilities/msg_util.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';
import '../../widgets/location_selector.dart'; // Widget LocationFilterWidget y LocationController

class ElementoForm extends StatefulWidget {
  // Null para registro, ID para edición
  final int? elementoId;

  const ElementoForm({super.key, this.elementoId});

  @override
  State<ElementoForm> createState() => _ElementoFormState();
}

class _ElementoFormState extends State<ElementoForm> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final _claveController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _serieController = TextEditingController();
  // Controlador de Ubicación (asumiendo que LocationController maneja los IDs de Ubicación)
  late final LocationController _locationController;

  // Estado para Dropdowns
  dynamic _tipoElementoSelected;
  List<Map<String, dynamic>> _tipoElementoItems = [];

  dynamic _estadoSelected;
  List<Map<String, dynamic>> _estadoItems = [];

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.elementoId != null;

    _locationController = LocationController();

    _getDropdownData();
  }

  @override
  void dispose() {
    _claveController.dispose();
    _descripcionController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _serieController.dispose();
    super.dispose();
  }

  // --- Lógica de Datos ---

  Future<void> _getDropdownData() async {
    setState(() => _isLoading = true);

    // 1. Estados (Hardcoded - igual que en ElementosConfiguracion)
    _estadoItems = [
      {'clave': 'Activo'},
      {'clave': 'En reparación'},
      {'clave': 'Fuera de servicio'},
    ];

    try {
      // 2. Tipos de Elemento (Fetched from Supabase Config)
      final response = await supabase
          .from('configuracion_general')
          .select('valores')
          .eq('modulo', 'gestion_configuraciones')
          .eq('elemento', 'elemento_configuracion_tipo')
          .single();

      if (response['valores'] is List) {
        _tipoElementoItems = List<Map<String, dynamic>>.from(response['valores'] as List);
      }

      // Establecer valores predeterminados
      _tipoElementoSelected = _tipoElementoItems.isNotEmpty ? _tipoElementoItems.first : null;
      _estadoSelected = _estadoItems.isNotEmpty ? _estadoItems.first : null;

      // 3. Cargar datos del elemento si estamos editando
      if (_isEditing) {
        await _loadElemento();
      }

    } catch (e) {
      MsgtUtil.showError(context, 'Error al cargar datos de configuración: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadElemento() async {
    if (widget.elementoId == null) return;
    try {
      setState(() => _isLoading = true);

      final data = await supabase
          .from('elemento_configuracion')
          .select('*')
          .eq('id', widget.elementoId!)
          .single();

      // Rellenar campos
      _claveController.text = data['clave'] ?? '';
      _descripcionController.text = data['descripcion'] ?? '';
      _marcaController.text = data['marca'] ?? '';
      _modeloController.text = data['modelo'] ?? '';
      _serieController.text = data['numero_serie'] ?? '';

      // Set Dropdowns
      _tipoElementoSelected = _tipoElementoItems.firstWhere(
            (item) => item['clave'] == data['elemento_tipo'],
        orElse: () => _tipoElementoItems.first,
      );

      _estadoSelected = _estadoItems.firstWhere(
            (item) => item['clave'] == data['estado'],
        orElse: () => _estadoItems.first,
      );

      // Set Location Controller (Asumiendo que usa el ID de ubicación)
      if (data['ubicacion_lugar_id'] != null) {
        _locationController.setLocation({'ubicacion_id': data['ubicacion_lugar_id']});
      }

    } catch (e) {
      MsgtUtil.showError(context, 'Error al cargar elemento: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Lógica de Envío ---

  Future<void> _saveElemento() async {
    // Validar que el formulario sea válido
    if (!_formKey.currentState!.validate()) {
      MsgtUtil.showWarning(context, 'Revise los campos obligatorios.');
      return;
    }

    // Validar que se haya seleccionado una ubicación (asumiendo que LocationFilterWidget lo requiere)
    if (_locationController.getLocation()?['ubicacion_id'] == null) {
      MsgtUtil.showWarning(context, 'Debe seleccionar una ubicación válida.');
      return;
    }

    if (!_isEditing) {
      _claveController.text = _generateNewClave();
    }

    setState(() => _isLoading = true);

    final payload = {
      'clave': _claveController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'elemento_tipo': _tipoElementoSelected?['clave'],
      'marca': _marcaController.text.trim(),
      'modelo': _modeloController.text.trim(),
      'numero_serie': _serieController.text.trim(),
      'estado': _estadoSelected?['clave'],
      'ubicacion_lugar_id': _locationController.getLocation()?['ubicacion_id'],
      // Campos de auditoría (registro_fecha, usuario_registro, etc.) se gestionan en Supabase
    };

    try {
      if (_isEditing) {
        // UPDATE
        await supabase
            .from('elemento_configuracion')
            .update(payload)
            .eq('id', widget.elementoId!);
        MsgtUtil.showSuccess(context, 'Elemento actualizado exitosamente.');
      } else {
        // INSERT
        await supabase
            .from('elemento_configuracion')
            .insert(payload);
        MsgtUtil.showSuccess(context, 'Elemento registrado exitosamente.');
      }
      context.go('/elementos_configuracion');

    } catch (e) {
      MsgtUtil.showError(context, 'Error al guardar elemento: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateNewClave() {
    final location = _locationController.getLocation();
    final tipo = _tipoElementoSelected?['clave'] as String? ?? 'N/A';

    final edificioNombre = location?['edificio_nombre'] as String? ?? 'EDIF';
    final ubicacionNombre = location?['ubicacion_nombre'] as String? ?? 'UBIC';

    // Tomar las primeras 3 letras (o menos) y convertir a mayúsculas
    final edificioCode = edificioNombre.replaceAll(' ', '').substring(0, min(edificioNombre.length, 3)).toUpperCase();
    final ubicacionCode = ubicacionNombre.replaceAll(' ', '').substring(0, min(ubicacionNombre.length, 3)).toUpperCase();
    final tipoCode = tipo.split('_')[0];

    // Generar número aleatorio de 4 dígitos (1000 a 9999)
    final random = Random();
    final randomDigits = 1000 + random.nextInt(9000);

    // Formato sugerido: EDIF-UBIC-TIPO-XXXX
    return '$edificioCode$ubicacionCode$tipoCode$randomDigits';
  }

  // --- Dropdown Builders (Reutilizados) ---

  List<DropdownMenuItem<dynamic>> _buildDropdownItems(List<dynamic> data) {
    return data.map<DropdownMenuItem<dynamic>>((item) {
      final String clave = item['clave'] ?? 'Sin Nombre';
      return DropdownMenuItem<dynamic>(
        value: item,
        child: Text(clave),
      );
    }).toList();
  }

  List<DropdownMenuItem<dynamic>> _buildEstadoDropdownItems(List<dynamic> data) {
    return data.map<DropdownMenuItem<dynamic>>((item) {
      final String clave = item['clave'] ?? 'Sin Nombre';
      return DropdownMenuItem<dynamic>(
        value: item,
        child: _buildEstadoChip(clave),
      );
    }).toList();
  }

  // --- UI Componentes ---

  Widget _buildEstadoChip(String estado) {
    Color bg;
    Color textColor;

    switch (estado.toLowerCase()) {
      case 'activo':
        bg = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'en reparación':
      case 'en reparacion':
        bg = Colors.amber.shade200;
        textColor = Colors.amber.shade800;
        break;
      case 'fuera de servicio':
        bg = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        estado,
        style: TextStyle(fontSize: 13, color: textColor),
      ),
    );
  }

  Widget _buildDatosGenerales() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de Sección
          Text('Datos Generales', style: AppTheme.light.title2),
          const SizedBox(height: 4),
          Text('Información básica del elemento', style: AppTheme.light.body),
          const SizedBox(height: 20),

          // Fila 1: Clave & Tipo de Elemento
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: Input(
                  controller: _claveController,
                  labelText: 'Clave',
                  enabled: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Este label simula el label de LocationFilterWidget para alineación
                    Text('Ubicación', style: AppTheme.light.body),
                    const SizedBox(height: 4),
                    LocationFilterWidget(
                      isSelection: true,
                      controller: _locationController,
                      onLocationChanged: () {
                        setState(() {});
                      },
                      //isMandatory: true, // Asumimos que es obligatorio
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10,),
              Expanded(
                child: Dropdown(
                  labelText: 'Tipo de Elemento',
                  value: _tipoElementoSelected,
                  items: _buildDropdownItems(_tipoElementoItems),
                  onChanged: (value) {
                    setState(() => _tipoElementoSelected = value);
                  },
                ),
              ),
              const SizedBox(width: 10,),
              SizedBox(
                width: 200,
                child: Dropdown(
                  labelText: 'Estado',
                  value: _estadoSelected,
                  items: _buildEstadoDropdownItems(_estadoItems),
                  onChanged: (value) {
                    setState(() => _estadoSelected = value);
                  },
                  //validator: (value) => value == null ? 'Seleccione un estado.' : null,
                  //icon: Icons.bar_chart_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Input(
                  controller: _descripcionController,
                  labelText: 'Descripción',
                  //placeholder: 'Descripción detallada del elemento...',
                  //icon: Icons.description_outlined,
                  maxLines: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Input(
                  controller: _marcaController,
                  labelText: 'Marca',
                  //placeholder: 'EJ: Dell',
                  //icon: Icons.business_outlined,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Input(
                  controller: _modeloController,
                  labelText: 'Modelo',
                  //placeholder: 'EJ: OptiPlex 7090',
                  //icon: Icons.tablet_android_outlined,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Input(
                  controller: _serieController,
                  labelText: 'Número de Serie',
                  //placeholder: 'EJ: ABC123XYZ',
                  //icon: Icons.numbers_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildComponentesSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de Sección y Botón
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Componentes del Elemento', style: AppTheme.light.title2),
                  const SizedBox(height: 4),
                  Text('Gestión de componentes asociados', style: AppTheme.light.body),
                ],
              ),
              const Spacer(),
              Button(
                width: 220,
                text: 'Agregar Componente',
                icon: Icons.add,
                backgroundColor: Colors.teal,
                onPressed: () {
                  MsgtUtil.showWarning(context, 'Funcionalidad de Agregar Componente (Pendiente)');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Encabezado de la Tabla de Componentes
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Center(child: Text('Clave', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 4, child: Center(child: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 2, child: Center(child: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 3, child: Center(child: Text('Marca', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 3, child: Center(child: Text('Modelo', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 3, child: Center(child: Text('N° Serie', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 3, child: Center(child: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),

          // Placeholder de Lista de Componentes
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.add_circle_outline, size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('No hay componentes agregados', style: AppTheme.light.body),
                Text('Haga clic en "Agregar Componente" para comenzar', style: AppTheme.light.body),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      color: Colors.black,
      progressIndicator: const CircularProgressIndicator(),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildDatosGenerales(),
              const SizedBox(height: 20),
              _buildComponentesSection(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Button(
                    width: 200,
                    text: _isEditing ? 'Actualizar Elemento' : 'Guardar Elemento',
                    icon: Icons.save_outlined,
                    onPressed: () {
                      _saveElemento();
                    },
                  ),
                  const SizedBox(width: 10,),
                  Button(
                    width: 200,
                    text: 'Regresar',
                    icon: Icons.arrow_back,
                    backgroundColor: Colors.grey,
                    onPressed: () {
                      context.go('/elementos_configuracion');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}