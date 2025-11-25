import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/utilities/constants.dart';
import 'package:gestion_ti_frontend/utilities/dialog_util.dart';
import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import 'package:gestion_ti_frontend/widgets/location_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../app_theme.dart';
import '../../utilities/debouncer.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';
// import 'package:gestion_ti_frontend/screens/private/incidencia_detail.dart'; // Si usas DialogUtil

class Incidencias extends StatefulWidget {
  const Incidencias({super.key});

  @override
  State<Incidencias> createState() => _IncidenciasState();
}

class _IncidenciasState extends State<Incidencias> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  // Filtros específicos para Incidencias
  dynamic _prioridadSelected;
  List<Map<String, dynamic>> _prioridadItems = [];

  dynamic _estadoSelected;
  List<Map<String, dynamic>> _estadoItems = [];

  // Nuevo filtro para complejidad
  dynamic _complejidadSelected;
  List<Map<String, dynamic>> _complejidadItems = [];

  // AÑADIDO: Filtro por Tipo de Incidencia
  dynamic _tipoIncidenciaSelected;
  List<Map<String, dynamic>> _tipoIncidenciaItems = [];


  final _debouncer = Debouncer(milliseconds: 500);
  bool _isLoading = false;
  int? hoverIndex;

  List<dynamic> _incidencias = [];

  @override
  void initState() {
    _getPrioridadItems();
    _getEstadosItems();
    _getComplejidadItems();
    _getTiposIncidenciaItems();
    _getData();
    super.initState();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- Lógica de Datos (sin cambios) ---

  _getData() async {
    try {
      setState(() => _isLoading = true);
      const String selectString =
          '*, '
          'elemento_configuracion(clave, descripcion, elemento_tipo), '
          'solicitud_usuario:solicitud_persona_id(nombre, apellido_paterno), '
          'asignado_usuario:asignado_persona_id(nombre, apellido_paterno)';

      var query = supabase.from('incidencia').select(selectString);

      if (_prioridadSelected != null && _prioridadSelected['clave'] != 'Todos') {
        query = query.eq('prioridad', _prioridadSelected['clave']);
      }
      if (_estadoSelected != null && _estadoSelected['clave'] != 'Todos') {
        query = query.eq('estado', _estadoSelected['clave']);
      }
      if (_complejidadSelected != null && _complejidadSelected['clave'] != 'Todos') {
        query = query.eq('complejidad', _complejidadSelected['clave']);
      }
      if (_tipoIncidenciaSelected != null && _tipoIncidenciaSelected['clave'] != 'Todos') {
        query = query.eq('incidencia_tipo', _tipoIncidenciaSelected['clave']);
      }

      final searchText = _searchController.text.trim();
      if (searchText.isNotEmpty) {
        final filterValue = '%$searchText%';
        query = query.or(
            'descripcion.ilike.$filterValue,incidencia_tipo.ilike.$filterValue'
        );
      }

      final response = await query.order('limite_fecha', ascending: true);
      _incidencias = response;
    } catch (e) {
      MsgtUtil.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Carga de ITEMS para Dropdowns (sin cambios en la data) ---

  _getTiposIncidenciaItems() async{
    try{
      setState(() {_isLoading = true;});
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
        _tipoIncidenciaItems.insert(0, {'clave': 'Todos'});
        _tipoIncidenciaSelected = _tipoIncidenciaItems.first;
      } else {
        _tipoIncidenciaItems = [{'clave': 'Todos'}];
        _tipoIncidenciaSelected = _tipoIncidenciaItems.first;
      }

    } catch(e){
      MsgtUtil.showError(context, "Error cargando Tipos de Incidencia: ${e.toString()}");
      _tipoIncidenciaItems = [{'clave': 'Todos'}];
      _tipoIncidenciaSelected = _tipoIncidenciaItems.first;
    } finally {
      setState(() {_isLoading = false;});
    }
  }

  _getPrioridadItems() {
    _prioridadItems = [
      {'clave': 'Todos'},
      {'clave': 'Critica'},
      {'clave': 'Alta'},
      {'clave': 'Media'},
      {'clave': 'Baja'},
    ];
    _prioridadSelected = _prioridadItems.first;
  }

  _getComplejidadItems() {
    _complejidadItems = [
      {'clave': 'Todos'},
      {'clave': 'ALTA'},
      {'clave': 'MEDIA'},
      {'clave': 'BAJA'},
    ];
    _complejidadSelected = _complejidadItems.first;
  }

  _getEstadosItems() {
    _estadoItems = [
      {'clave': 'Todos'},
      {'clave': 'Registrada'},
      {'clave': 'Asignada'},
      {'clave': 'En progreso'},
      {'clave': 'Pendiente'},
      {'clave': 'Resuelta'},
      {'clave': 'Cerrada'},
    ];
    _estadoSelected = _estadoItems.first;
  }

  // --- Funciones de Construcción de Chips (sin cambios) ---

  // INCIDENCIA CHIP (usando la prioridad)
  Widget _buildPrioridadChip(String prioridad) {
    Color bg;
    Color textColor;

    switch (prioridad.toUpperCase()) {
      case 'CRITICA':
        bg = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'ALTA':
        bg = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'MEDIA':
        bg = Colors.yellow.shade100;
        textColor = Colors.yellow.shade800;
        break;
      case 'BAJA':
        bg = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        prioridad,
        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // COMPLEJIDAD CHIP (BAJA, MEDIA, ALTA)
  Widget _buildComplejidadChip(String complejidad) {
    Color bg;
    Color textColor;

    switch (complejidad.toUpperCase()) {
      case 'ALTA':
        bg = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case 'MEDIA':
        bg = Colors.cyan.shade100;
        textColor = Colors.cyan.shade800;
        break;
      case 'BAJA':
        bg = Colors.blueGrey.shade100;
        textColor = Colors.blueGrey.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        complejidad,
        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Chip de Estado
  Widget _buildEstadoChip(String estado) {
    Color bg;
    Color textColor;

    switch (estado.toLowerCase()) {
      case 'registrada':
      case 'asignada':
        bg = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'en progreso':
        bg = Colors.amber.shade200;
        textColor = Colors.amber.shade800;
        break;
      case 'resuelta':
      case 'cerrada':
        bg = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'pendiente':
        bg = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        estado,
        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }


  _openIncidencia({required int? incidenciaID}) async {
    try{
      final String path;
      if (incidenciaID != null) {
        // Redirigir a la vista de detalle
        path = '/incidencia_detail/${incidenciaID}';
      } else {
        path = '/incidencia_detail/nuevo';
      }
      context.go(path);
    } catch(e){
      MsgtUtil.showError(context, e.toString());
    } finally{
      _getData(); // Refrescar el listado al regresar
    }
  }

  // --- FUNCIÓN MODIFICADA: CONSTRUIR ITEMS CON CHIPS ---

  // Nueva función para construir DropdownItems que usan un chip personalizado
  List<DropdownMenuItem<dynamic>> _buildDropdownItemsWithChips(
      List<dynamic> data,
      Widget Function(String) chipBuilder
      ) {
    return data.map<DropdownMenuItem<dynamic>>((item) {
      final String clave = item['clave'] ?? 'Sin Nombre';

      // Manejar la opción "Todos" como texto simple
      final Widget childWidget = clave == 'Todos'
          ? Text(clave, style: TextStyle(fontSize: 14, color: Colors.grey.shade700))
          : chipBuilder(clave);

      return DropdownMenuItem<dynamic>(
        value: item,
        // Añadir padding vertical al chip para que no se recorte en el Dropdown
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: childWidget,
        ),
      );
    }).toList();
  }

  // Renombrada: Función para construir DropdownItems solo con texto
  List<DropdownMenuItem<dynamic>> _buildDropdownItemsTextOnly(List<dynamic> data) {
    return data.map<DropdownMenuItem<dynamic>>((item) {
      final String clave = item['clave'] ?? 'Sin Nombre';
      return DropdownMenuItem<dynamic>(
        value: item,
        child: Text(clave),
      );
    }).toList();
  }
  // ------------------------------------

  // Función para obtener el nombre completo del usuario
  String _formatUserName(Map<String, dynamic>? user) {
    if (user == null) return 'N/A';
    String nombre = user['nombre'].split(' ')[0];
    return '${nombre ?? ''} ${user['apellido_paterno'] ?? ''}'.trim();
  }

  // ---------------------------
  // FILTERS ROW (MODIFICADA para usar chips)
  // ---------------------------
  Widget _buildFiltersRow(){
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Input(
          width: 300,
          controller: _searchController,
          labelText: 'Buscar',
          onChanged: (p0) {
            _debouncer.run(_getData);
          },
        ),
        const SizedBox(width: 10,),
        Dropdown(
          width: 150,
          labelText: 'Prioridad',
          value: _prioridadSelected,
          items: _buildDropdownItemsWithChips(_prioridadItems, _buildPrioridadChip), // USA CHIPS
          onChanged: (value) {
            setState(() {
              _prioridadSelected = value;
              _getData();
            });
          },
        ),
        const SizedBox(width: 10,),
        Dropdown(
          width: 150,
          labelText: 'Complejidad',
          value: _complejidadSelected,
          items: _buildDropdownItemsWithChips(_complejidadItems, _buildComplejidadChip), // USA CHIPS
          onChanged: (value) {
            setState(() {
              _complejidadSelected = value;
              _getData();
            });
          },
        ),
        const SizedBox(width: 10,),
        Dropdown(
          width: 170,
          labelText: 'Tipo Incidencia',
          value: _tipoIncidenciaSelected,
          items: _buildDropdownItemsTextOnly(_tipoIncidenciaItems), // USA TEXTO SIMPLE
          onChanged: (value) {
            setState(() {
              _tipoIncidenciaSelected = value;
              _getData();
            });
          },
        ),
        const SizedBox(width: 10,),
        Dropdown(
          width: 150,
          labelText: 'Estado',
          value: _estadoSelected,
          items: _buildDropdownItemsWithChips(_estadoItems, _buildEstadoChip), // USA CHIPS
          onChanged: (value) {
            setState(() {
              _estadoSelected = value;
              _getData();
            });
          },
        ),
        const Spacer(),
      ],
    );
  }

  // ... (El resto de funciones _buildHeader, _buildRowItem, etc. se mantienen) ...

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
            // HEADER
            Row(
              children: [
                Text(
                  'Gestión de Incidencias',
                  style: AppTheme.light.title1,
                ),
                const Spacer(),
                // BOTÓN ACTUALIZADO PARA NAVEGACIÓN
                Button(
                  width: 200,
                  text: 'Nueva Incidencia',
                  icon: Icons.add_alert_outlined,
                  onPressed: () => _openIncidencia(incidenciaID: null),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFiltersRow(),
            const SizedBox(height: 10,),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _incidencias.isEmpty
                    ? Center(
                  child: Text("No hay incidencias registradas",
                      style: AppTheme.light.body),
                )
                    : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _incidencias.length,
                        itemBuilder: (context, i) {
                          return _buildRowItem(_incidencias[i], i);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------
  // HEADER ROW (sin cambios)
  // ---------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: const Row(
        children: [
          _HeaderCell('# ID', flex: 1),
          _HeaderCell('CI', flex: 3),
          _HeaderCell('PRIORIDAD', flex: 2),
          _HeaderCell('COMPLEJIDAD', flex: 3),
          _HeaderCell('TIPO', flex: 3),
          _HeaderCell('DESCRIPCIÓN', flex: 7),
          _HeaderCell('ESTADO', flex: 3),
          _HeaderCell('REPORTADO POR', flex: 4),
          _HeaderCell('ASIGNADO A', flex: 4),
          _HeaderCell('REGISTRO', flex: 3),
          _HeaderCell('LIMITE RES.', flex: 3),
        ],
      ),
    );
  }

  // ---------------------------
  // ROW ITEM (CLICKABLE) (sin cambios)
  // ---------------------------
  Widget _buildRowItem(Map<String, dynamic> e, i) {
    final DateTime? registro_fecha = e['registro_fecha'] != null ? DateTime.parse(e['registro_fecha']) : null;
    final DateTime? limiteFecha = e['limite_fecha'] != null ? DateTime.parse(e['limite_fecha']) : null;
    final bool isOverdue = limiteFecha != null && limiteFecha.isBefore(DateTime.now());

    final elementoConfig = e['elemento_configuracion'] as Map<String, dynamic>?;
    String elementoClave = elementoConfig != null ? elementoConfig['clave'] as String? ?? 'N/A' : 'N/A';

    final usuarioSolicita = e['solicitud_usuario'] as Map<String, dynamic>?;
    final usuarioAsignado = e['asignado_usuario'] as Map<String, dynamic>?;


    return InkWell(
      onHover: (value) {
        setState(() {
          hoverIndex = value ? i : null;
        });
      },
      onTap: () {
        _openIncidencia(incidenciaID: e['id']);
      },
      enableFeedback: true,
      splashColor: AppTheme.light.primary.withOpacity(0.1),
      child: Ink(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              color: hoverIndex == i ? AppTheme.light.primary.withOpacity(0.1) : null
          ),
          child: Row(
            children: [
              _Cell(e['id'].toString(), flex: 1, bold: true,),
              _Cell(elementoClave.toString(), flex: 3, bold: true,),

              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildPrioridadChip(e['prioridad'] ?? '-'),
                ),
              ),

              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildComplejidadChip(e['complejidad'] ?? '-'),
                ),
              ),

              _Cell(e['incidencia_tipo'] ?? '-', flex: 3),

              _Cell(e['descripcion'] ?? '-', flex: 7),

              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildEstadoChip(e['estado'] ?? '-'),
                ),
              ),

              _Cell(_formatUserName(usuarioSolicita), flex: 4),

              _Cell(_formatUserName(usuarioAsignado), flex: 4),

              _Cell(
                registro_fecha != null ? DateFormat('dd/MM/yyyy').format(registro_fecha.toLocal()) : 'N/A',
                flex: 3,
              ),

              _Cell(
                limiteFecha != null ? DateFormat('dd/MM/yyyy').format(limiteFecha.toLocal()) : 'N/A',
                flex: 3,
                bold: isOverdue,
                color: isOverdue ? Colors.red.shade700 : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// REUSABLE CELLS (sin cambios)
// -------------------------------------------------------

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final Color? color;

  const _Cell(this.text, {required this.flex, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          style: (bold ? AppTheme.light.bodyBold : AppTheme.light.body).copyWith(color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}