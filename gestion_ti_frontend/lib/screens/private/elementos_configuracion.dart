import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/utilities/constants.dart';
import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';
import '../../widgets/button.dart';

class ElementosConfiguracion extends StatefulWidget {
  const ElementosConfiguracion({super.key});

  @override
  State<ElementosConfiguracion> createState() => _ElementosConfiguracion();
}

class _ElementosConfiguracion extends State<ElementosConfiguracion> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;
  int? hoverIndex;

  List<dynamic> _elementos = [];

  @override
  void initState() {
    _getData();
    super.initState();
  }

  _getData() async {
    try {
      setState(() => _isLoading = true);

      final response = await supabase
          .from('elemento_configuracion')
          .select('*')
          .order('clave', ascending: true);

      _elementos = response;
    } catch (e) {
      MsgtUtil.showError(context, e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  _openElemento({required String? elementoID}) async {
    // Open dialog or details screen
    _getData();
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
          _HeaderCell('CLAVE', flex: 2),
          _HeaderCell('DESCRIPCIÓN', flex: 4),
          _HeaderCell('TIPO', flex: 3),
          _HeaderCell('MARCA', flex: 3),
          _HeaderCell('MODELO', flex: 3),
          _HeaderCell('N° SERIE', flex: 3),
          _HeaderCell('ESTADO', flex: 3),
          _HeaderCell('UBICACIÓN', flex: 3),
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
      onTap: () => () {

      },
      enableFeedback: true,
      splashColor: AppTheme.light.primary.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          color: hoverIndex == i ? AppTheme.light.primary.withOpacity(0.1) : null
        ),
        child: Row(
          children: [
            _Cell(e['clave'] ?? '', flex: 2, bold: true,),
            _Cell(e['descripcion'] ?? '', flex: 4),
            _Cell(e['elemento_tipo'] ?? '-', flex: 3),
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

            _Cell(e['ubicacion_lugar_id']?.toString() ?? '-', flex: 3),

            _Cell(
              (e['registro_fecha'] ?? '').toString().split('T')[0],
              flex: 3,
            ),
          ],
        ),
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

            // LIST
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
