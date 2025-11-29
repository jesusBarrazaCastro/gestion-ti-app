import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // Importamos para manejar JSON

// Asumiendo que estos son los imports de tus componentes y utilidades
import '../../app_theme.dart';
import '../../utilities/msg_util.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';
import '../../widgets/location_selector.dart'; // Widget LocationFilterWidget y LocationController

// --- ESTRUCTURA DE DATOS PARA COMPONENTES ---
class Componente {
  // Usamos 'id' para identificar el componente en la lista localmente
  // Aunque no se guarda en Supabase, ayuda en la edición/eliminación.
  final String id;
  final TextEditingController claveController;
  final TextEditingController descripcionController;
  final TextEditingController marcaController;
  final TextEditingController modeloController;
  final TextEditingController serieController;
  final TextEditingController cantidadController;
  final GlobalKey<FormState> formKey;
  bool isEditing;

  Componente({
    String? id,
    String clave = '',
    String descripcion = '',
    String marca = '',
    String modelo = '',
    String serie = '',
    int cantidad = 1,
    this.isEditing = true, // Por defecto, al agregar uno nuevo, está en modo edición
  })  : id = id ?? UniqueKey().toString(), // Generar un ID único localmente
        claveController = TextEditingController(text: clave),
        descripcionController = TextEditingController(text: descripcion),
        marcaController = TextEditingController(text: marca),
        modeloController = TextEditingController(text: modelo),
        serieController = TextEditingController(text: serie),
        cantidadController = TextEditingController(text: cantidad.toString()),
        formKey = GlobalKey<FormState>();

  // Constructor para cargar desde JSON
  factory Componente.fromJson(Map<String, dynamic> json) {
    return Componente(
      id: json['id'] as String?,
      clave: json['clave'] as String? ?? '',
      descripcion: json['descripcion'] as String? ?? '',
      marca: json['marca'] as String? ?? '',
      modelo: json['modelo'] as String? ?? '',
      serie: json['numero_serie'] as String? ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 1,
      isEditing: false, // Por defecto, al cargar desde DB, no está en edición
    );
  }

  // Método para convertir a JSON para guardar en Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Mantenemos el ID para coherencia, aunque no se usa en DB
      'clave': claveController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'marca': marcaController.text.trim(),
      'modelo': modeloController.text.trim(),
      'numero_serie': serieController.text.trim(),
      'cantidad': int.tryParse(cantidadController.text.trim()) ?? 1,
    };
  }
}

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
  // Controlador de Ubicación
  late final LocationController _locationController;

  // Estado para Dropdowns
  dynamic _tipoElementoSelected;
  List<Map<String, dynamic>> _tipoElementoItems = [];

  dynamic _estadoSelected;
  List<Map<String, dynamic>> _estadoItems = [];

  // --- NUEVO ESTADO PARA COMPONENTES ---
  List<Componente> _componentes = [];

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
    // Liberar controladores de componentes al cerrar
    for (var comp in _componentes) {
      comp.claveController.dispose();
      comp.descripcionController.dispose();
      comp.marcaController.dispose();
      comp.modeloController.dispose();
      comp.serieController.dispose();
      comp.cantidadController.dispose();
    }
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

      const String selectString =
          '*, '
          'ubicacion_lugar(id, nombre, edificio(id, nombre, departamento(id, nombre)))';

      final data = await supabase
          .from('elemento_configuracion')
          .select(selectString)
          .eq('id', widget.elementoId!)
          .single();

      // Rellenar campos
      _claveController.text = data['clave'] ?? '';
      _descripcionController.text = data['descripcion'] ?? '';
      _marcaController.text = data['marca'] ?? '';
      _modeloController.text = data['modelo'] ?? '';
      _serieController.text = data['numero_serie'] ?? '';
      _locationController.setLocation(formatLocationJson(data));

      // Set Dropdowns
      _tipoElementoSelected = _tipoElementoItems.firstWhere(
            (item) => item['clave'] == data['elemento_tipo'],
        orElse: () => _tipoElementoItems.first,
      );

      _estadoSelected = _estadoItems.firstWhere(
            (item) => item['clave'] == data['estado'],
        orElse: () => _estadoItems.first,
      );

      // --- CARGAR COMPONENTES ---
      final List<dynamic>? componentesJson = data['componentes_json'];
      if (componentesJson != null) {
        _componentes = componentesJson
            .map((json) => Componente.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      // -------------------------

    } catch (e) {
      MsgtUtil.showError(context, 'Error al cargar elemento: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Lógica de Componentes (CRUD Local) ---

  void _addComponente() {
    setState(() {
      // Asegurarse de que cualquier componente en edición se guarde primero
      _componentes = _componentes.map((c) {
        if (c.isEditing) {
          // Intentar validar y guardar el componente
          if (c.formKey.currentState?.validate() ?? false) {
            c.isEditing = false;
            return c;
          } else {
            // Si la validación falla, mantenerlo en edición. No agregamos el nuevo.
            return c;
          }
        }
        return c;
      }).toList();

      // Verificar si hay componentes aún en edición inválida
      if (_componentes.any((c) => c.isEditing)) {
        MsgtUtil.showWarning(context, 'Debe guardar o cancelar la edición del componente actual.');
        return;
      }

      // Agregar un nuevo componente en modo edición
      _componentes.add(Componente());
    });
  }

  void _editComponente(Componente componente) {
    setState(() {
      // Desactivar el modo edición de otros componentes
      _componentes.where((c) => c.id != componente.id).forEach((c) => c.isEditing = false);
      componente.isEditing = true;
    });
  }

  void _saveComponente(Componente componente) {
    // Validar el formulario del componente
    if (componente.formKey.currentState!.validate()) {
      setState(() {
        componente.isEditing = false;
      });
    } else {
      MsgtUtil.showWarning(context, 'Revise los campos obligatorios del componente.');
    }
  }

  void _deleteComponente(Componente componente) {
    // Asegurarse de liberar los controladores
    componente.claveController.dispose();
    componente.descripcionController.dispose();
    componente.marcaController.dispose();
    componente.modeloController.dispose();
    componente.serieController.dispose();
    componente.cantidadController.dispose();

    setState(() {
      _componentes.removeWhere((c) => c.id == componente.id);
    });
  }


  // --- Lógica de Envío ---

  Future<void> _saveElemento() async {
    // 1. Validar el formulario principal
    if (!_formKey.currentState!.validate()) {
      MsgtUtil.showWarning(context, 'Revise los campos obligatorios del elemento.');
      return;
    }

    // 2. Validar ubicación
    if (_locationController.getLocation()?['ubicacion_id'] == null) {
      MsgtUtil.showWarning(context, 'Debe seleccionar una ubicación válida.');
      return;
    }

    // 3. Validar componentes: asegurarse de que ninguno esté en edición
    if (_componentes.any((c) => c.isEditing)) {
      MsgtUtil.showWarning(context, 'Guarde o cancele la edición de todos los componentes antes de guardar el elemento.');
      return;
    }

    if (!_isEditing) {
      // Generar clave solo en caso de registro nuevo
      _claveController.text = _generateNewClave();
    }

    setState(() => _isLoading = true);

    // Convertir la lista de Componente a una lista de Map<String, dynamic> (JSON)
    final List<Map<String, dynamic>> componentesJsonList = _componentes.map((c) => c.toJson()).toList();

    final payload = {
      'clave': _claveController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'elemento_tipo': _tipoElementoSelected?['clave'],
      'marca': _marcaController.text.trim(),
      'modelo': _modeloController.text.trim(),
      'numero_serie': _serieController.text.trim(),
      'estado': _estadoSelected?['clave'],
      'ubicacion_lugar_id': _locationController.getLocation()?['ubicacion_id'],
      'componentes_json': componentesJsonList, // <-- CAMPO JSON DE COMPONENTES
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
  // ... (El resto de las funciones auxiliares como formatLocationJson, _generateNewClave, _buildDropdownItems, _buildEstadoDropdownItems, _buildEstadoChip permanecen igual)

  // ... (Funciones formatLocationJson, _generateNewClave, _buildDropdownItems, _buildEstadoDropdownItems, _buildEstadoChip van aquí, sin cambios)

  Map<String, dynamic> formatLocationJson(Map<String, dynamic> elemento) {
    final ubicacionNode = elemento['ubicacion_lugar'];

    final Map<String, dynamic> result = {
      'departamento_id': null,
      'departamento_nombre': null,
      'edificio_id': null,
      'edificio_nombre': null,
      'ubicacion_id': null,
      'ubicacion_nombre': null,
      'full_location_string': 'Ubicación no asignada',
    };

    if (ubicacionNode == null || ubicacionNode is! Map<String, dynamic>) {
      return result;
    }

    final List<String> parts = [];

    if (ubicacionNode['id'] != null) {
      result['ubicacion_id'] = ubicacionNode['id'];
    }
    if (ubicacionNode['nombre'] is String) {
      result['ubicacion_nombre'] = ubicacionNode['nombre'] as String;
      parts.add(result['ubicacion_nombre']);
    }

    final edificioNode = ubicacionNode['edificio'];

    if (edificioNode != null && edificioNode is Map<String, dynamic>) {
      if (edificioNode['id'] != null) {
        result['edificio_id'] = edificioNode['id'];
      }
      if (edificioNode['nombre'] is String) {
        result['edificio_nombre'] = edificioNode['nombre'] as String;
        parts.insert(0, result['edificio_nombre']);
      }

      final departamentoNode = edificioNode['departamento'];

      if (departamentoNode != null && departamentoNode is Map<String, dynamic>) {
        if (departamentoNode['id'] != null) {
          result['departamento_id'] = departamentoNode['id'];
        }
        if (departamentoNode['nombre'] is String) {
          result['departamento_nombre'] = departamentoNode['nombre'] as String;
          parts.insert(0, result['departamento_nombre']);
        }
      }
    }
    if (parts.isNotEmpty) {
      result['full_location_string'] = parts.join(', ');
    }
    return result;
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

  // ...

  Widget _buildDatosGenerales() {
    // ... (Tu implementación original de _buildDatosGenerales)
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

  // --- NUEVA IMPLEMENTACIÓN DE COMPONENTES ---

  Widget _buildComponenteRow(Componente componente) {
    final bool isEditing = componente.isEditing;

    // Validación simplificada para Input
    String? requiredValidator(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Requerido';
      }
      return null;
    }

    String? intValidator(String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Req.';
      }
      if (int.tryParse(value) == null || (int.tryParse(value) ?? 0) < 1) {
        return 'Inválido';
      }
      return null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Form(
        key: componente.formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 2,),
            Expanded(
              flex: 3,
              child: isEditing
                  ? Input(
                controller: componente.claveController,
                labelText: 'Clave',
                //validator: requiredValidator,
                //dense: true,
              )
                  : Text(componente.claveController.text, ),
            ),
            const SizedBox(width: 10),

            // Descripción (Lectura o Input)
            Expanded(
              flex: 4,
              child: isEditing
                  ? Input(
                controller: componente.descripcionController,
                labelText: 'Descripción',
                //validator: requiredValidator,
                //dense: true,
              )
                  : Text(componente.descripcionController.text, ),
            ),
            const SizedBox(width: 10),

            // Cantidad (Lectura o Input)
            Expanded(
              flex: 2,
              child: isEditing
                  ? Input(
                controller: componente.cantidadController,
                labelText: 'Cant.',
                //validator: intValidator,
                keyboardType: TextInputType.number,
                //dense: true,
              )
                  : Text(componente.cantidadController.text, textAlign: TextAlign.start,),
            ),
            const SizedBox(width: 10),

            // Marca (Lectura o Input)
            Expanded(
              flex: 3,
              child: isEditing
                  ? Input(
                controller: componente.marcaController,
                labelText: 'Marca',
                //dense: true,
              )
                  : Text(componente.marcaController.text, ),
            ),
            const SizedBox(width: 10),

            // Modelo (Lectura o Input)
            Expanded(
              flex: 3,
              child: isEditing
                  ? Input(
                controller: componente.modeloController,
                labelText: 'Modelo',
                //dense: true,
              )
                  : Text(componente.modeloController.text, ),
            ),
            const SizedBox(width: 10),

            // N° Serie (Lectura o Input)
            Expanded(
              flex: 3,
              child: isEditing
                  ? Input(
                controller: componente.serieController,
                labelText: 'N° Serie',
                //dense: true,
              )
                  : Text(componente.serieController.text, ),
            ),
            const SizedBox(width: 10),

            // Acciones
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.save, color: Colors.black),
                      tooltip: 'Guardar',
                      onPressed: () => _saveComponente(componente),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      tooltip: 'Editar',
                      onPressed: () => _editComponente(componente),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.black),
                    tooltip: 'Eliminar',
                    onPressed: () => _deleteComponente(componente),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                onPressed: _addComponente,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Encabezado de la Tabla de Componentes
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Clave', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Marca', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Modelo', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('N° Serie', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // Lista de Componentes
          if (_componentes.isNotEmpty)
            ..._componentes.map((componente) => _buildComponenteRow(componente)).toList()
          else
          // Placeholder si no hay componentes
            const SizedBox(height: 40),
          if (_componentes.isEmpty)
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
          const SizedBox(height: 20),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDatosGenerales(),
                    const SizedBox(height: 20),
                    _buildComponentesSection(), // <-- Sección de componentes actualizada
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5,),
            const Divider(),
            const SizedBox(height: 5,),
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
                  width: 220,
                  text: 'Registrar Incidencia',
                  icon: Icons.error_outline,
                  backgroundColor: Colors.red,
                  onPressed: () {
                    if (widget.elementoId != null) {
                      final int idDelElemento = widget.elementoId!;
                      final String ruta = '/incidencia_detail/nuevo?elementoId=$idDelElemento';
                      context.go(ruta);
                    } else {
                      MsgtUtil.showWarning(
                          context,
                          'Debe guardar el Elemento de Configuración antes de registrar una incidencia asociada.'
                      );
                    }
                  },
                ),
                const SizedBox(width: 10,),
                    Button(
                  width: 220,
                  text: 'Solicitar cambio',
                  icon: Icons.swap_horiz,
                  backgroundColor: Colors.blueGrey,
                  onPressed: () {
                    if (widget.elementoId != null) {
                      final int idDelElemento = widget.elementoId!;
                      final String ruta = '/solicitud_cambio_detail/nuevo?elementoId=$idDelElemento';
                      context.go(ruta);
                    } else {
                      MsgtUtil.showWarning(
                        context,
                        'Debe guardar el Elemento de Configuración antes de solicitar un cambio.',
                      );
                    }
                  },
                ),
                const Spacer(),
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
    );
  }
}