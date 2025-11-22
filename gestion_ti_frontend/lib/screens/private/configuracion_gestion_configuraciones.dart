import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/screens/private/persona_detail.dart';
import 'package:gestion_ti_frontend/utilities/constants.dart';
import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import 'package:gestion_ti_frontend/widgets/pilltag.dart';
import 'package:gestion_ti_frontend/widgets/simple_table.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';
import '../../utilities/dialog_util.dart';
import '../../widgets/button.dart';
import '../../widgets/input.dart';

class ConfigGestionConf extends StatefulWidget {
  const ConfigGestionConf({super.key});

  @override
  State<ConfigGestionConf> createState() => _ConfigGestionConf();
}

class _ConfigGestionConf extends State<ConfigGestionConf> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _elementoTipos = [];

  @override
  void initState() {
    _getData();
    super.initState();
  }

  _getData() async{
    try{
      setState(() {_isLoading = true;});
      final response = await supabase
          .from('configuracion_general')
          .select('elemento, valores')
          .eq('modulo', 'gestion_configuraciones');
      if(response.isEmpty) return;
      List<dynamic> data = response;
      _elementoTipos = data.where((element) => element['elemento'] == 'elemento_configuracion_tipo').toList()[0]['valores'];
    } catch(e){
      MsgtUtil.showError(context, e.toString());
      return;
    } finally {
      setState(() {_isLoading = false;});
    }
  }

  _save() async{
    try {
      setState(() {
        _isLoading = true;
      });
      //guardar elementos de configuracion
      final response = await supabase
          .from('configuracion_general')
          .update({'valores': _elementoTipos,})
          .eq('modulo', 'gestion_configuraciones')
          .eq('elemento', 'elemento_configuracion_tipo');

      MsgtUtil.showSuccess(context, 'Configuración guardada exitosamente.');
    } catch (e) {
      MsgtUtil.showError(context, 'Error al guardar la configuración: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SimpleTable(dataList: _elementoTipos, title: 'Tipos de elementos de cofiguración',),
                          ],
                        ),
                        SizedBox(height: 500,)
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3,),
              const Divider(),
              const SizedBox(height: 3,),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Button(
                    width: 140,
                    icon: Icons.save,
                    text: 'Guardar',
                    onPressed: _save,
                  )
                ],
              )
            ],
          ),
        )
    );
  }
}
