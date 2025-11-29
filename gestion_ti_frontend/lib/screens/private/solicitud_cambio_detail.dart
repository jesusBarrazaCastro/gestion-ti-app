import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../app_theme.dart';
import '../../utilities/msg_util.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';
import '../../utilities/dialog_util.dart';
import 'elemento_configuracion_detail.dart';

class SolicitudCambioDetail extends StatefulWidget {
  final int? solicitudCambioId; // null = nueva solicitud
  final int? elementoId;        // para cuando vienes desde elemento_configuracion_detail

  const SolicitudCambioDetail({
    super.key,
    this.solicitudCambioId,
    this.elementoId,
  });

  @override
  State<SolicitudCambioDetail> createState() => _SolicitudCambioDetailState();
}

class _SolicitudCambioDetailState extends State<SolicitudCambioDetail> {
  final SupabaseClient supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isEditing = false;

  // Campos tabla solicitud_cambio
  int? _elementoId;
  String _elementoClave = 'N/A';

  String _tipo = 'Normal';
  String _prioridad = 'Media';
  String _estado = 'Pendiente';
  bool _registroEstado = true;

  DateTime? _registroFecha;
  DateTime? _resolucionFecha;

  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _resolucionComentarioController =
      TextEditingController();

  // Catálogos (los que me diste)
  final List<String> _tipoOptions = ['Normal', 'Estándar', 'Urgente'];
  final List<String> _prioridadOptions = ['Alta', 'Media', 'Baja'];
  final List<String> _estadoOptions = [
    'Pendiente',
    'Aprobado',
    'Rechazado',
    'Implementado',
  ];

  String _tituloIdText = 'NUEVA';

  @override
  void initState() {
    super.initState();
    _isEditing = widget.solicitudCambioId != null;
    _tituloIdText =
        _isEditing ? widget.solicitudCambioId.toString() : 'NUEVA';

    _elementoId = widget.elementoId;
    _loadData();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _resolucionComentarioController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Si es edición, primero cargamos la solicitud
      if (_isEditing && widget.solicitudCambioId != null) {
        await _loadSolicitudCambio(widget.solicitudCambioId!);
      } else {
        // Nueva solicitud: si viene elementoId, cargamos su clave
        if (_elementoId != null) {
          await _loadElementoClave(_elementoId!);
        }
        _registroFecha = DateTime.now();
      }
    } catch (e) {
      MsgtUtil.showError(context, 'Error al cargar datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadElementoClave(int id) async {
    try {
      final data = await supabase
          .from('elemento_configuracion')
          .select('clave')
          .eq('id', id)
          .single();

      setState(() {
        _elementoClave = (data['clave'] as String?) ?? 'N/A';
      });
    } catch (e) {
      MsgtUtil.showError(context, 'Error al cargar clave de CI: $e');
    }
  }

  Future<void> _loadSolicitudCambio(int id) async {
    try {
      final data = await supabase
          .from('solicitud_cambio')
          .select(
              '*, elemento_configuracion:elemento_id(id, clave)') // join simple
          .eq('id', id)
          .maybeSingle();

      if (data == null) {
        MsgtUtil.showWarning(
            context, 'No se encontró la solicitud de cambio #$id');
        return;
      }

      setState(() {
        _elementoId = data['elemento_id'] as int?;
        _elementoClave =
            data['elemento_configuracion']?['clave'] as String? ?? 'N/A';

        _tipo = data['tipo'] as String? ?? 'Normal';
        _prioridad = data['prioridad'] as String? ?? 'Media';
        _estado = data['estado'] as String? ?? 'Pendiente';
        _registroEstado = data['registro_estado'] as bool? ?? true;

        _motivoController.text = data['motivo'] as String? ?? '';
        _resolucionComentarioController.text =
            data['resolucion_comentario'] as String? ?? '';

        _registroFecha = data['registro_fecha'] != null
            ? DateTime.parse(data['registro_fecha'] as String)
            : null;

        _resolucionFecha = data['resolucion_fecha'] != null
            ? DateTime.tryParse(data['resolucion_fecha'] as String)
            : null;
      });
    } catch (e) {
      MsgtUtil.showError(context, 'Error al cargar solicitud: $e');
    }
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
  }

  void _openElemento() {
    if (_elementoId == null) return;

    DialogUtil.showCustomDialog(
      context: context,
      width: MediaQuery.sizeOf(context).width * 0.9,
      height: MediaQuery.sizeOf(context).height * 0.9,
      child: ElementoForm(elementoId: _elementoId!),
      showCloseButton: true,
      title: 'Elemento de configuración',
    );
  }

  Future<void> _saveSolicitud() async {
    final motivo = _motivoController.text.trim();

    if (motivo.isEmpty) {
      MsgtUtil.showWarning(context, 'El motivo del cambio es obligatorio.');
      return;
    }

    if (_elementoId == null) {
      MsgtUtil.showWarning(
          context, 'No se ha definido un elemento de configuración.');
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'elemento_id': _elementoId,
      'estado': _estado,
      'tipo': _tipo,
      'prioridad': _prioridad,
      'motivo': motivo,
      // TODO: sustituir con el uuid real del usuario logueado
      //'solicitante_persona_id': '<uuid-usuario>',
      'registro_estado': _registroEstado,
      'resolucion_comentario':
          _resolucionComentarioController.text.trim().isEmpty
              ? null
              : _resolucionComentarioController.text.trim(),
    };

    // resolución_fecha solo si hay comentario y estado != Pendiente
    if (_resolucionComentarioController.text.trim().isNotEmpty &&
        _estado != 'Pendiente') {
      payload['resolucion_fecha'] = DateTime.now().toIso8601String();
    }

    try {
      if (_isEditing && widget.solicitudCambioId != null) {
        await supabase
            .from('solicitud_cambio')
            .update(payload)
            .eq('id', widget.solicitudCambioId!);

        MsgtUtil.showSuccess(
            context, 'Solicitud de cambio #${widget.solicitudCambioId} actualizada.');
      } else {
        payload['registro_fecha'] = DateTime.now().toIso8601String();

        final inserted = await supabase
            .from('solicitud_cambio')
            .insert(payload)
            .select()
            .single();

        final newId = inserted['id'];
        MsgtUtil.showSuccess(
            context, 'Solicitud de cambio #$newId registrada correctamente.');
      }

      // regresar al listado (ajusta la ruta a la que uses)
      context.go('/gestion_cambios');
    } catch (e) {
      MsgtUtil.showError(context, 'Error al guardar solicitud: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'SOLICITUD DE CAMBIO: #$_tituloIdText',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _estado,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        Button(
          width: 160,
          icon: Icons.save,
          text: _isEditing ? 'Actualizar' : 'Guardar',
          onPressed: _saveSolicitud,
        ),
      ],
    );
  }

  Widget _buildBloqueInformacion() {
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
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Información básica',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),

          // CI afectado
          Row(
            children: [
              const Text(
                'CI afectado:',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _elementoId != null ? _openElemento : null,
                child: Text(
                  _elementoClave,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        _elementoId != null ? Colors.blue : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Motivo
          Input(
            controller: _motivoController,
            labelText: 'Motivo del cambio',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildBloqueClasificacion() {
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
          const Row(
            children: [
              Icon(Icons.class_outlined, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Clasificación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),

          Row(
            children: [
              Expanded(
                child: Dropdown(
                  labelText: 'Tipo de cambio',
                  value: _tipo,
                  items: _buildStringDropdownItems(_tipoOptions),
                  onChanged: (value) {
                    setState(() {
                      _tipo = value as String;
                    });
                  },
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Dropdown(
                  labelText: 'Prioridad',
                  value: _prioridad,
                  items: _buildStringDropdownItems(_prioridadOptions),
                  onChanged: (value) {
                    setState(() {
                      _prioridad = value as String;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Dropdown(
                  labelText: 'Estado',
                  value: _estado,
                  items: _buildStringDropdownItems(_estadoOptions),
                  onChanged: (value) {
                    setState(() {
                      _estado = value as String;
                    });
                  },
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fechas', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Registro: ${_formatDate(_registroFecha)}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Resolución: ${_formatDate(_resolucionFecha)}',
            style: const TextStyle(fontSize: 12),
          ),
          const Divider(height: 32),

          const Text('Resolución', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Input(
            controller: _resolucionComentarioController,
            labelText: 'Comentario de resolución',
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Registro activo'),
              Switch(
                value: _registroEstado,
                onChanged: (val) {
                  setState(() {
                    _registroEstado = val;
                  });
                },
              ),
            ],
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulario principal
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildBloqueInformacion(),
                            _buildBloqueClasificacion(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Sidebar
                  _buildSidebar(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Button(
                  width: 160,
                  icon: Icons.arrow_back,
                  text: 'Regresar',
                  backgroundColor: Colors.grey,
                  onPressed: () => context.go('/gestion_cambios'),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
