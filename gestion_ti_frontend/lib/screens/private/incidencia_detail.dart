import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/screens/private/elemento_configuracion_detail.dart';
import 'package:gestion_ti_frontend/utilities/dialog_util.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Asumiendo que estos son los imports de tus componentes y utilidades
import '../../app_theme.dart';
import '../../utilities/msg_util.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';

// --- MODELO PARA REGISTRO DE ACTIVIDAD (Sin Cambios) ---
class Actividad {
  final String id;
  final String autor;
  final String mensaje;
  final DateTime fecha;
  final bool esSistema;

  Actividad({
    required this.id,
    required this.autor,
    required this.mensaje,
    required this.fecha,
    this.esSistema = false,
  });

  Actividad.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? UniqueKey().toString(),
        autor = json['autor'] ?? 'Sistema',
        mensaje = json['mensaje'] ?? '',
        fecha = json['fecha'] is String
            ? DateTime.tryParse(json['fecha'] as String) ?? DateTime.now()
            : json['fecha'] is DateTime
            ? json['fecha'] as DateTime
            : DateTime.now(),
        esSistema = json['esSistema'] ?? true;
}

class IncidenciaDetail extends StatefulWidget {
  final int? incidenciaId;
  final int? elementoId; // <<-- CAMBIO AÑADIDO: ID del CI si se registra desde ahí

  const IncidenciaDetail({
    super.key,
    this.incidenciaId,
    this.elementoId // Recibir el ID del elemento
  });

  @override
  State<IncidenciaDetail> createState() => _IncidenciaDetailState();
}

class _IncidenciaDetailState extends State<IncidenciaDetail> {
  final SupabaseClient supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  // ID del CI (Elemento de Configuración) afectado
  int? _elementoId; // Inicializado en initState
  String _elementoClave = 'N/A';

  // Controladores de Texto
  final _descripcionController = TextEditingController();
  final _notaResolucionController = TextEditingController();
  final _nuevaNotaController = TextEditingController();

  // Datos de la Incidencia (Inicialización/Edición)
  String _currentIncidenciaTipo = '';
  String _currentPrioridad = '';
  String _currentComplejidad = '';
  String _currentEstado = '';
  DateTime? _registroFecha;
  DateTime? _limiteFecha;
  String _solicitudUsuarioNombre = 'N/A';
  String _solicitudUsuarioCorreo = '';
  String _asignadoUsuarioNombre = 'N/A';

  // Catálogos para Dropdowns
  List<Map<String, dynamic>> _prioridadItems = [];
  List<Map<String, dynamic>> _estadoItems = [];
  List<Map<String, dynamic>> _complejidadItems = [];
  List<Map<String, dynamic>> _tipoIncidenciaItems = []; // Se cargará dinámicamente

  // Valores Seleccionados para Dropdowns
  dynamic _prioridadSelected;
  dynamic _estadoSelected;
  dynamic _complejidadSelected;
  dynamic _tipoIncidenciaSelected;

  // Registro de Actividad
  List<Actividad> _actividades = [];

  bool _isLoading = false;
  bool _isEditing = false;

  String _incidenciaIDText = 'NUEVA';

  @override
  void initState() {
    super.initState();
    _isEditing = widget.incidenciaId != null;
    _incidenciaIDText = _isEditing ? widget.incidenciaId.toString() : 'NUEVA';

    // ✨ CAMBIO AÑADIDO 1: Inicializar _elementoId si viene del constructor
    _elementoId = widget.elementoId;

    _getDropdownData();

    // ✨ CAMBIO AÑADIDO 2: Si es una nueva incidencia Y tenemos elementoId, cargamos su clave
    if (!_isEditing && _elementoId != null) {
      _loadElementoClave(_elementoId!);
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _notaResolucionController.dispose();
    _nuevaNotaController.dispose();
    super.dispose();
  }

  // --- Lógica de Datos ---

  // NUEVA FUNCIÓN: Carga la clave del Elemento de Configuración
  Future<void> _loadElementoClave(int id) async {
    try {
      setState(() => _isLoading = true);

      final data = await supabase
          .from('elemento_configuracion')
          .select('clave')
          .eq('id', id)
          .single();

      setState(() {
        _elementoClave = data['clave'] as String? ?? 'N/A';
      });

    } catch (e) {
      MsgtUtil.showError(context, 'Error al cargar clave de CI: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getDropdownData() async {
    setState(() => _isLoading = true);

    // 1. Catálogos Fijos
    _getPrioridadItems();
    _getEstadosItems();
    _getComplejidadItems();

    // 2. Catálogo de Tipos de Incidencia (Carga dinámica)
    await _getTiposIncidenciaItems();

    // 3. Cargar datos de la Incidencia si estamos editando
    if (_isEditing) {
      await _loadIncidencia();
    } else {
      // Valores predeterminados para nueva incidencia
      _prioridadSelected = _prioridadItems.firstWhere((e) => e['clave'] == 'Baja', orElse: () => _prioridadItems.first);
      _estadoSelected = _estadoItems.firstWhere((e) => e['clave'] == 'Registrada', orElse: () => _estadoItems.first);
      _complejidadSelected = _complejidadItems.firstWhere((e) => e['clave'] == 'BAJA', orElse: () => _complejidadItems.first);
      _tipoIncidenciaSelected = _tipoIncidenciaItems.isNotEmpty ? _tipoIncidenciaItems.first : null;

      // Suponemos que el usuario loggeado es el solicitante
      _solicitudUsuarioNombre = 'Usuario Loggeado';
      _solicitudUsuarioCorreo = 'usuario@empresa.com';
    }

    setState(() => _isLoading = false);
  }

  // FUNCIÓN MODIFICADA: Carga de Tipos de Incidencia desde configuracion_general
  _getTiposIncidenciaItems() async{
    try{
      final response = await supabase
          .from('configuracion_general')
          .select('elemento, valores')
          .eq('modulo', 'gestion_incidencias');
      if(response.isEmpty) return;

      List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      final elementoConfig = data.firstWhere(
            (element) => element['elemento'] == 'incidencia_tipo',
        orElse: () => {},
      );

      if (elementoConfig.isNotEmpty && elementoConfig['valores'] is List) {
        _tipoIncidenciaItems = List<Map<String, dynamic>>.from(elementoConfig['valores'] as List);
      } else {
        _tipoIncidenciaItems = [];
      }

    } catch(e){
      MsgtUtil.showError(context, "Error cargando Tipos de Incidencia: ${e.toString()}");
      _tipoIncidenciaItems = [];
    }
  }

  _getPrioridadItems() {
    _prioridadItems = [
      {'clave': 'Critica'},
      {'clave': 'Alta'},
      {'clave': 'Media'},
      {'clave': 'Baja'},
    ];
  }

  _getComplejidadItems() {
    _complejidadItems = [
      {'clave': 'ALTA'},
      {'clave': 'MEDIA'},
      {'clave': 'BAJA'},
    ];
  }

  _getEstadosItems() {
    _estadoItems = [
      {'clave': 'Registrada'},
      {'clave': 'Asignada'},
      {'clave': 'En progreso'},
      {'clave': 'Pendiente'},
      {'clave': 'Resuelta'},
      {'clave': 'Cerrada'},
    ];
  }

  // Carga de la Incidencia (Incluyendo relaciones)
  Future<void> _loadIncidencia() async {
    if (widget.incidenciaId == null) return;
    try {
      setState(() => _isLoading = true);

      const String selectString =
          '*, '
          'elemento_configuracion(id, clave, descripcion), '
          'solicitud_usuario:solicitud_persona_id(nombre, apellido_paterno, correo_electronico), '
          'asignado_usuario:asignado_persona_id(nombre, apellido_paterno)';

      final data = await supabase
          .from('incidencia')
          .select(selectString)
          .eq('id', widget.incidenciaId!)
          .single();

      // Rellenar campos del Formulario
      _elementoId = data['elemento_id'] as int?;
      _elementoClave = data['elemento_configuracion']['clave'] as String? ?? 'N/A';
      _descripcionController.text = data['descripcion'] ?? '';
      _notaResolucionController.text = data['nota_resolucion'] ?? '';

      // Set Dropdowns (Lógica omitida por brevedad)
      _currentPrioridad = data['prioridad'] as String? ?? 'Baja';
      _prioridadSelected = _prioridadItems.firstWhere((item) => item['clave'] == _currentPrioridad, orElse: () => _prioridadItems.first,);
      _currentEstado = data['estado'] as String? ?? 'Registrada';
      _estadoSelected = _estadoItems.firstWhere((item) => item['clave'] == _currentEstado, orElse: () => _estadoItems.first,);
      _currentComplejidad = data['complejidad'] as String? ?? 'BAJA';
      _complejidadSelected = _complejidadItems.firstWhere((item) => item['clave'] == _currentComplejidad, orElse: () => _complejidadItems.first,);
      _currentIncidenciaTipo = data['incidencia_tipo'] as String? ?? 'APLICACION';
      _tipoIncidenciaSelected = _tipoIncidenciaItems.firstWhere((item) => item['clave'] == _currentIncidenciaTipo, orElse: () => _tipoIncidenciaItems.first,);

      // Rellenar Panel Lateral
      _registroFecha = data['registro_fecha'] != null ? DateTime.parse(data['registro_fecha']) : null;
      _limiteFecha = data['limite_fecha'] != null ? DateTime.parse(data['limite_fecha']) : null;

      // Usuarios
      _solicitudUsuarioNombre = _formatUserName(data['solicitud_usuario']);
      _solicitudUsuarioCorreo = data['solicitud_usuario']['correo_electronico'] ?? '';
      _asignadoUsuarioNombre = _formatUserName(data['asignado_usuario']);

      // Cargar actividades (Simulación, en la vida real se cargaría el log)
      _actividades = _loadSimulatedActivities(data);


    } catch (e) {
      MsgtUtil.showError(context, 'Error al cargar incidencia: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Función auxiliar para obtener el nombre completo
  String _formatUserName(Map<String, dynamic>? user) {
    if (user == null) return 'N/A';
    String nombre = user['nombre']?.split(' ')[0] ?? '';
    return '${nombre} ${user['apellido_paterno'] ?? ''}'.trim();
  }

  // Simula la carga de actividades
  List<Actividad> _loadSimulatedActivities(Map<String, dynamic> data) {
    // [CÓDIGO DE SIMULACIÓN DE ACTIVIDADES OMITIDO POR BREVEDAD]
    final List<Actividad> simulatedActivities = [];
    if (_registroFecha != null) {
      simulatedActivities.add(Actividad(id: '1', autor: _solicitudUsuarioNombre, mensaje: 'Incidencia creada.', fecha: _registroFecha!.subtract(const Duration(hours: 8)), esSistema: false,));
      simulatedActivities.add(Actividad(id: '2', autor: 'Sistema', mensaje: 'Estado cambiado a "En Progreso"', fecha: _registroFecha!.subtract(const Duration(hours: 4)), esSistema: true,));
      if (_asignadoUsuarioNombre != 'N/A') {
        simulatedActivities.add(Actividad(id: '3', autor: _asignadoUsuarioNombre, mensaje: 'Iniciando diagnóstico remoto.', fecha: _registroFecha!.subtract(const Duration(hours: 2)), esSistema: false,));
      }
    }
    simulatedActivities.sort((a, b) => b.fecha.compareTo(a.fecha));
    return simulatedActivities;
  }

  // --- Lógica de Envío ---

  Future<void> _saveIncidencia() async {
    if (!_formKey.currentState!.validate()) {
      MsgtUtil.showWarning(context, 'Revise los campos obligatorios.');
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'elemento_id': _elementoId,
      'incidencia_tipo': _tipoIncidenciaSelected?['clave'],
      'descripcion': _descripcionController.text.trim(),
      'estado': _estadoSelected?['clave'],
      'prioridad': _prioridadSelected?['clave'],
      'complejidad': _complejidadSelected?['clave'],
      'nota_resolucion': _notaResolucionController.text.trim(),
      // Datos para NUEVA incidencia
      'registro_fecha': DateTime.now().toIso8601String(),
      // 'solicitud_persona_id': 1, // <--- REEMPLAZAR con el ID del usuario loggeado
    };

    try {
      if (_isEditing) {
        await supabase
            .from('incidencia')
            .update(payload)
            .eq('id', widget.incidenciaId!);
        MsgtUtil.showSuccess(context, 'Incidencia \#${widget.incidenciaId} actualizada exitosamente.');
      } else {
        await supabase
            .from('incidencia')
            .insert(payload);
        MsgtUtil.showSuccess(context, 'Incidencia registrada exitosamente.');
      }
      context.go('/gestion_incidencias');

    } catch (e) {
      MsgtUtil.showError(context, 'Error al guardar incidencia: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  _openElemento({required int elementoId}) async{
    DialogUtil.showCustomDialog(
        context: context,
        width: MediaQuery.sizeOf(context).width * 0.9,
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: ElementoForm(elementoId: elementoId,),
        showCloseButton: true,
        title: 'Elemento de configuración'
    );
  }

  // --- Widgets Auxiliares (Omitidos por brevedad) ---

  List<DropdownMenuItem<dynamic>> _buildDropdownItems(List<dynamic> data) {
    return data.map<DropdownMenuItem<dynamic>>((item) {
      final String clave = item['clave'] ?? 'Sin Nombre';
      return DropdownMenuItem<dynamic>(
        value: item,
        child: Text(clave),
      );
    }).toList();
  }

  // (Funciones _buildPrioridadChip, _buildComplejidadChip, _buildEstadoChip,
  // _buildPrioridadDropdownItems, _buildComplejidadDropdownItems, _buildFechaRow,
  // _buildUserRow, _buildActividadItem permanecen sin cambios)

  Widget _buildPrioridadChip(String prioridad) {
    Color bg;
    Color textColor;

    switch (prioridad.toUpperCase()) {
      case 'CRITICA': bg = Colors.red.shade100; textColor = Colors.red.shade800; break;
      case 'ALTA': bg = Colors.orange.shade100; textColor = Colors.orange.shade800; break;
      case 'MEDIA': bg = Colors.yellow.shade100; textColor = Colors.yellow.shade800; break;
      case 'BAJA': bg = Colors.green.shade100; textColor = Colors.green.shade800; break;
      default: bg = Colors.grey.shade200; textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        prioridad,
        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildComplejidadChip(String complejidad) {
    Color bg;
    Color textColor;

    switch (complejidad.toUpperCase()) {
      case 'ALTA': bg = Colors.purple.shade100; textColor = Colors.purple.shade800; break;
      case 'MEDIA': bg = Colors.cyan.shade100; textColor = Colors.cyan.shade800; break;
      case 'BAJA': bg = Colors.blueGrey.shade100; textColor = Colors.blueGrey.shade800; break;
      default: bg = Colors.grey.shade200; textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        complejidad,
        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<DropdownMenuItem<dynamic>> _buildPrioridadDropdownItems(List<dynamic> data) {
    return data.map<DropdownMenuItem<dynamic>>((item) {
      final String clave = item['clave'] ?? 'Sin Nombre';
      return DropdownMenuItem<dynamic>(
        value: item,
        child: _buildPrioridadChip(clave),
      );
    }).toList();
  }

  List<DropdownMenuItem<dynamic>> _buildComplejidadDropdownItems(List<dynamic> data) {
    return data.map<DropdownMenuItem<dynamic>>((item) {
      final String clave = item['clave'] ?? 'Sin Nombre';
      return DropdownMenuItem<dynamic>(
        value: item,
        child: _buildComplejidadChip(clave),
      );
    }).toList();
  }

  Widget _buildEstadoChip(String estado) {
    Color bg;
    Color textColor;

    switch (estado.toLowerCase()) {
      case 'registrada':
      case 'asignada': bg = Colors.blue.shade100; textColor = Colors.blue.shade800; break;
      case 'en progreso': bg = Colors.amber.shade200; textColor = Colors.amber.shade800; break;
      case 'resuelta':
      case 'cerrada': bg = Colors.green.shade100; textColor = Colors.green.shade800; break;
      case 'pendiente': bg = Colors.purple.shade100; textColor = Colors.purple.shade800; break;
      default: bg = Colors.grey.shade200; textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        estado,
        style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFechaRow(String label, DateTime? date, {bool isOverdue = false}) {
    final String formattedDate = date != null ? DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal()) : 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              formattedDate,
              style: TextStyle(
                color: isOverdue ? Colors.red.shade700 : Colors.black,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(String label, String name, {String? email}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blueGrey,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        if (email != null)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Text(email, style: TextStyle(fontSize: 12, color: Colors.blue)),
          ),
      ],
    );
  }

  Widget _buildActividadItem(Actividad actividad) {
    final duration = DateTime.now().difference(actividad.fecha);
    String timeAgo;
    if (duration.inMinutes < 60) { timeAgo = 'hace ${duration.inMinutes} minutos'; }
    else if (duration.inHours < 24) { timeAgo = 'hace ${duration.inHours} horas'; }
    else { timeAgo = DateFormat('dd/MM/yy').format(actividad.fecha.toLocal()); }

    final bool isSystem = actividad.esSistema;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isSystem ? 'Sistema' : actividad.autor,
                style: TextStyle(
                    color: isSystem ? Colors.purple : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(width: 5),
              Text(
                timeAgo,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          Text(
            actividad.mensaje,
            style: const TextStyle(fontSize: 13),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  // --- SECCIONES DEL FORMULARIO PRINCIPAL ---

  Widget _buildInformacionBasica() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Información Básica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20),

          Row(
            children: [
              SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CI Afectado', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),),
                    const SizedBox(height: 4,),
                    InkWell(
                      child: Ink(
                          child: Text(
                            _elementoClave,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _elementoId != null ? Colors.blue : Colors.grey
                            ),
                          )
                      ),
                      // Solo permitir abrir si el ID está presente
                      onTap: _elementoId != null ? () {
                        _openElemento(elementoId: _elementoId!);
                      } : null,
                    )
                  ],
                ),
              ),

            ],
          ),
          const SizedBox(height: 20),

          Input(
            controller: _descripcionController,
            labelText: 'Descripción Detallada',
            maxLines: 5,
            //validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildClasificacion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.class_outlined, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Clasificación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 20),

          Row(
            children: [
              Expanded(
                child: Dropdown(
                  labelText: 'Tipo de Incidencia',
                  value: _tipoIncidenciaSelected,
                  items: _buildDropdownItems(_tipoIncidenciaItems),
                  onChanged: (value) => setState(() => _tipoIncidenciaSelected = value),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Dropdown(
                  labelText: 'Prioridad',
                  value: _prioridadSelected,
                  items: _buildPrioridadDropdownItems(_prioridadItems),
                  onChanged: (value) => setState(() => _prioridadSelected = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Dropdown(
                  labelText: 'Complejidad',
                  value: _complejidadSelected,
                  items: _buildComplejidadDropdownItems(_complejidadItems),
                  onChanged: (value) => setState(() => _complejidadSelected = value),
                ),
              ),
              const Spacer(flex:3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final bool isOverdue = _limiteFecha != null && _limiteFecha!.isBefore(DateTime.now());

    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ESTADO Y FECHAS
          const Text('Estado y Fechas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildEstadoChip(_estadoSelected?['clave'] ?? 'N/A'),
          const SizedBox(height: 10),

          _buildFechaRow('Fecha de Registro', _registroFecha),
          _buildFechaRow('Fecha Límite', _limiteFecha, isOverdue: isOverdue),

          const Divider(height: 30),

          // 2. USUARIOS INVOLUCRADOS
          const Text('Usuarios Involucrados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          _buildUserRow('Reportado por', _solicitudUsuarioNombre, email: _solicitudUsuarioCorreo),
          const SizedBox(height: 15),

          const Text('Asignado a', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Dropdown(
            value: _asignadoUsuarioNombre,
            items: [
              DropdownMenuItem(value: _asignadoUsuarioNombre, child: Text(_asignadoUsuarioNombre)),
              const DropdownMenuItem(value: 'Agente 1', child: Text('Agente 1 - Soporte L1')),
              const DropdownMenuItem(value: 'Agente 2', child: Text('Agente 2 - Redes')),
            ],
            onChanged: (value) {
              // Lógica de reasignación
            },
          ),

          const Divider(height: 30),

          // 3. REGISTRO DE ACTIVIDAD
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Registro de Actividad', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),

          ..._actividades.map((act) => _buildActividadItem(act)).toList(),

        ],
      ),
    );
  }


  // --- WIDGET PRINCIPAL (BUILD) ---

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _isLoading,
      color: Colors.black,
      progressIndicator: const CircularProgressIndicator(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER (con Título y Botones de Acción)
            Row(
              children: [
                Text(
                  'INCIDENCIA ID: #$_incidenciaIDText',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                _buildEstadoChip(_estadoSelected?['clave'] ?? 'N/A'),
                const Spacer(),

                // Botones de Flujo de Trabajo
                Button(
                  width: 130, text: 'Asignar', icon: Icons.person_add_alt_1, backgroundColor: Colors.grey.shade600,
                  onPressed: () => MsgtUtil.showWarning(context, 'Lógica de Asignación'),
                ),
                const SizedBox(width: 10),
                Button(
                  width: 130, text: 'Resolver', icon: Icons.check_circle_outline, backgroundColor: Colors.green,
                  onPressed: () => MsgtUtil.showWarning(context, 'Lógica de Resolución'),
                ),
                const SizedBox(width: 10),
                Button(
                  width: 130, text: 'Cerrar', icon: Icons.cancel_outlined, backgroundColor: Colors.red,
                  onPressed: () => MsgtUtil.showWarning(context, 'Lógica de Cierre'),
                ),
                const SizedBox(width: 10),

                // Botón de Guardar/Actualizar
                Button(
                  width: 140,
                  text: _isEditing ? 'Actualizar' : 'Guardar',
                  icon: Icons.save_outlined,
                  onPressed: _saveIncidencia,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CONTENIDO PRINCIPAL (Formulario + Sidebar)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna Principal (Formulario)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildInformacionBasica(),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildClasificacion()),
                                const SizedBox(width: 10,),
                                Expanded(
                                  child: Input(
                                    controller: _notaResolucionController,
                                    labelText: 'Nota de Resolución',
                                    maxLines: 5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Panel Lateral (Sidebar)
                  _buildSidebar(),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Botón de Regreso
            Row(
              children: [
                Button(
                  width: 150,
                  text: 'Regresar',
                  icon: Icons.arrow_back,
                  backgroundColor: Colors.grey,
                  onPressed: () {
                    context.go('/gestion_incidencias');
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