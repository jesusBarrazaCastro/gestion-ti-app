import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/screens/private/departamentos.dart';
import 'package:gestion_ti_frontend/screens/private/elemento_configuracion_detail.dart';
import 'package:gestion_ti_frontend/utilities/constants.dart';
import 'package:gestion_ti_frontend/utilities/dialog_util.dart';
import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import 'package:gestion_ti_frontend/widgets/location_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';
import '../../utilities/debouncer.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';

class ElementosConfiguracion extends StatefulWidget {
  const ElementosConfiguracion({super.key});

  @override
  State<ElementosConfiguracion> createState() => _ElementosConfiguracion();
}

class _ElementosConfiguracion extends State<ElementosConfiguracion> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  late final LocationController _locationController;

  dynamic _tipoElementoSelected;
  List<Map<String, dynamic>> _tipoElementoItems = [];

  dynamic _estadoSelected;
  List<Map<String, dynamic>> _estadoItems = [];

  final _debouncer = Debouncer(milliseconds: 500);
  bool _isLoading = false;
  int? hoverIndex;


  List<dynamic> _elementos = [];

  @override
  void initState() {
    _locationController = LocationController(
        initialLocation: {
          'departamento_id': null,
          'departamento_nombre': 'Todos los departamentos',
          'edificio_id': null,
          'edificio_nombre': 'Todos los edificios',
          'ubicacion_id': null,
          'ubicacion_nombre': 'Todas las ubicaciones'
        }
    );
    _getEstadosItems();
    _getTiposElementos();
    _getData();
    super.initState();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  _getData() async {
    try {
      setState(() => _isLoading = true);

      const String selectString =
          '*, '
          'ubicacion_lugar(id, nombre, edificio(id, nombre, departamento(id, nombre)))' ;

      var query = supabase.from('elemento_configuracion').select(selectString);

      // 2. Filtro por Tipo de Elemento
      if (_tipoElementoSelected != null && _tipoElementoSelected['clave'] != 'Todos') {
        query = query.eq('elemento_tipo', _tipoElementoSelected['clave']);
      }

      // 3. Filtro por Estado
      if (_estadoSelected != null && _estadoSelected['clave'] != 'Todos') {
        query = query.eq('estado', _estadoSelected['clave']);
      }

      // 4. Filtro por Ubicación (usando la más específica disponible)
      final location = _locationController.getLocation();
      final specificLocationId = location?['ubicacion_id'];
      final specificEdificioId = location?['edificio_id'];
      final specificDepartamentoId = location?['departamento_id'];

      if (specificLocationId != null) {
        query = query.eq('ubicacion_lugar_id', specificLocationId);
      } else if (specificEdificioId != null) {
        query = query.eq('edificio_id', specificEdificioId);
      } else if (specificDepartamentoId != null) {
        query = query.eq('departamento_id', specificDepartamentoId);
      }

      // 5. Filtro por Búsqueda (Texto)
      final searchText = _searchController.text.trim();
      if (searchText.isNotEmpty) {
        final filterValue = '%$searchText%';
        query = query.or(
            'clave.ilike.$filterValue,descripcion.ilike.$filterValue,numero_serie.ilike.$filterValue'
        );
      }

      final response = await query.order('clave', ascending: true);

      _elementos = response;
    } catch (e) {
      MsgtUtil.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  _getTiposElementos() async{
    try{
      setState(() {_isLoading = true;});
      final response = await supabase
          .from('configuracion_general')
          .select('elemento, valores')
          .eq('modulo', 'gestion_configuraciones');
      if(response.isEmpty) return;

      List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      final elementoConfig = data.firstWhere(
            (element) => element['elemento'] == 'elemento_configuracion_tipo',
        orElse: () => {},
      );

      if (elementoConfig.isNotEmpty && elementoConfig['valores'] is List) {
        _tipoElementoItems = List<Map<String, dynamic>>.from(elementoConfig['valores'] as List);
        _tipoElementoItems.insert(0, {'clave': 'Todos'});
        _tipoElementoSelected = _tipoElementoItems.first;
      } else {
        _tipoElementoItems = [];
      }

    } catch(e){
      MsgtUtil.showError(context, e.toString());
      return;
    } finally {
      setState(() {_isLoading = false;});
    }
  }

  String formatLocationString(Map<String, dynamic> elemento) {
    final ubicacionNode = elemento['ubicacion_lugar'];

    if (ubicacionNode == null || ubicacionNode is! Map<String, dynamic>) {
      return 'Ubicación no asignada';
    }

    final List<String> parts = [];

    final edificioNode = ubicacionNode['edificio'];

    if (edificioNode != null && edificioNode is Map<String, dynamic>) {
      final departamentoNode = edificioNode['departamento'];
      if (departamentoNode != null && departamentoNode is Map<String, dynamic> && departamentoNode['nombre'] is String) {
        parts.add(departamentoNode['nombre'] as String);
      }

      if (edificioNode['nombre'] is String) {
        parts.add(edificioNode['nombre'] as String);
      }
    }

    if (ubicacionNode['nombre'] is String) {
      parts.add(ubicacionNode['nombre'] as String);
    }

    if (parts.isEmpty) {
      return 'Ubicación no asignada';
    }

    return parts.join(', ');
  }


  _getEstadosItems() {
    _estadoItems = [
      {'clave': 'Todos'},
      {'clave': 'Activo'},
      {'clave': 'En reparación'},
      {'clave': 'Fuera de servicio'},
    ];
    _estadoSelected = _estadoItems.first;
  }

  _openElemento({required int? elementoID}) async {
    try{
      final String path;
      if (elementoID != null) {
        path = '/elementos_configuracion_form/${elementoID}';
      } else {
        path = '/elementos_configuracion_form/nuevo';
      }
      context.go(path);
    } catch(e){
      MsgtUtil.showError(context, e.toString());
    } finally{
      _getData();
    }
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

  // ---------------------------
  // ESTADO CHIP
  // ---------------------------
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
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        estado,
        style: TextStyle(fontSize: 13, color: textColor),
      ),
    );
  }


  // ---------------------------
  // HEADER ROW
  // ---------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: const [
          _HeaderCell('CLAVE', flex: 3),
          _HeaderCell('DESCRIPCIÓN', flex: 5),
          _HeaderCell('TIPO', flex: 2),
          _HeaderCell('MARCA', flex: 3),
          _HeaderCell('MODELO', flex: 3),
          _HeaderCell('N° SERIE', flex: 3),
          _HeaderCell('ESTADO', flex: 3),
          _HeaderCell('UBICACIÓN', flex: 4),
          _HeaderCell('FECHA REGISTRO', flex: 3),
        ],
      ),
    );
  }

  // ---------------------------
  // ROW ITEM (CLICKABLE)
  // ---------------------------
  Widget _buildRowItem(Map<String, dynamic> e, i) {
    return InkWell(
      onHover: (value) {
        setState(() {
          hoverIndex = value ? i : null;
        });
      },
      onTap: () {
        _openElemento(elementoID: e['id']);
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
              _Cell(e['clave'] ?? '', flex: 3, bold: true,),
              _Cell(e['descripcion'] ?? '', flex: 5),
              _Cell(e['elemento_tipo'] ?? '-', flex: 2),
              _Cell(e['marca'] ?? '-', flex: 3),
              _Cell(e['modelo'] ?? '-', flex: 3),
              _Cell(e['numero_serie'] ?? '-', flex: 3),

              // Estado chip
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildEstadoChip(e['estado'] ?? '-'),
                ),
              ),

              _Cell(formatLocationString(e), flex: 4),

              _Cell(
                (e['registro_fecha'] ?? '').toString().split('T')[0],
                flex: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFilter(){
    return LocationFilterWidget(
      controller: _locationController,
      onLocationChanged: () {
        _getData();
      },
    );
  }

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
          width: 200,
          labelText: 'Tipo de elemento',
          value: _tipoElementoSelected,
          items: _buildDropdownItems(_tipoElementoItems),
          onChanged: (value) {
            _tipoElementoSelected = value;
            _getData();
          },
        ),
        const SizedBox(width: 10,),
        Dropdown(
          width: 200,
          labelText: 'Estado',
          value: _estadoSelected,
          items: _buildEstadoDropdownItems(_estadoItems),
          onChanged: (value) {
            _estadoSelected = value;
            _getData();
          },
        ),
        const SizedBox(width: 10,),
        Expanded(child: _buildLocationFilter()),
      ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Text(
                  'Elementos de Configuración',
                  style: AppTheme.light.title1,
                ),
                const Spacer(),
                Button(
                  width: 200,
                  text: 'Nuevo Elemento',
                  icon: Icons.add_box_outlined,
                  onPressed: () => _openElemento(elementoID: null),
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
                child: _elementos.isEmpty
                    ? Center(
                  child: Text("No hay elementos registrados",
                      style: AppTheme.light.body),
                )
                    : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _elementos.length,
                        itemBuilder: (context, i) {
                          return _buildRowItem(_elementos[i], i);
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
}

// -------------------------------------------------------
// REUSABLE CELLS
// -------------------------------------------------------

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;

  const _Cell(this.text, {required this.flex, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          text,
          style: !bold ? AppTheme.light.body : AppTheme.light.bodyBold,
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