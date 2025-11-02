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


  Widget _UIElementoTipos(){
    bool isEditing = false;
    int? editingIndex = null;
    TextEditingController nombreController = TextEditingController();
    TextEditingController descripcionController = TextEditingController();

    return Container(
      height: 400,
      width: 600,
      decoration: BoxDecoration(
        color: AppTheme.light.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18)
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text('Nombre', style: AppTheme.light.bodyBold,)
              ),
              const SizedBox(width: 10,),
              Expanded(
                  flex: 2,
                  child: Text('Descripcion', style: AppTheme.light.bodyBold,)
              ),
              const Spacer(),
              Button(
                width: 130,
                text: 'Agregar',
                icon: Icons.add_box_outlined,
                onPressed: (){},
              )
            ],
          ),
          const SizedBox(height: 5,),
          const Divider(),
          const SizedBox(height: 5,),
          ListView.builder(
            shrinkWrap: true,
            itemCount: _elementoTipos.length,
            itemBuilder:  (context, index) {
              dynamic item = _elementoTipos[index];
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                      child: Text(item['nombre'], style: AppTheme.light.body,)
                  ),
                  const SizedBox(width: 10,),
                  Expanded(
                      flex: 2,
                      child: Text(item['descripcion'], style: AppTheme.light.body,)
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 130,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if(!isEditing)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.black,),
                            onPressed: () {
                              isEditing = true;
                              editingIndex = index;
                              setState(() {});
                            },
                          ),
                        if(isEditing && editingIndex == index)...[
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green,),
                            onPressed: () {
                              isEditing = false;
                              editingIndex = null;
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 5,),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.black,),
                            onPressed: () {
                              isEditing = false;
                              editingIndex = null;
                              setState(() {});
                            },
                          ),
                        ]
                      ],
                    ),
                  )
                ],
              );
            },
          )
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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tipos de elementos de cofiguración', style: AppTheme.light.title2,),
                      const SizedBox(height: 10,),
                      SimpleTable(dataList: _elementoTipos)
                    ],
                  ),
                ],
              )
            ],
          ),
        )
    );
  }
}
