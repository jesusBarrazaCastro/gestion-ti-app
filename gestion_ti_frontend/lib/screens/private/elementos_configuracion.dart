import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/screens/private/persona_detail.dart';
import 'package:gestion_ti_frontend/utilities/constants.dart';
import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import 'package:gestion_ti_frontend/widgets/pilltag.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';
import '../../utilities/dialog_util.dart';
import '../../widgets/button.dart';
import '../../widgets/input.dart';

class ElementosConfiguracion extends StatefulWidget {
  const ElementosConfiguracion({super.key});

  @override
  State<ElementosConfiguracion> createState() => _ElementosConfiguracion();
}

class _ElementosConfiguracion extends State<ElementosConfiguracion> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _elementos = [];


  @override
  void initState() {
    _getData();
    super.initState();
  }

  _getData() async{
    try{
      setState(() {_isLoading = true;});
      final personaResponse = await supabase
          .from('elemento_configuracion')
          .select('*')
          .order('clave', ascending: true);
      if(personaResponse.isEmpty) return;
      _elementos = personaResponse;
    } catch(e){
      MsgtUtil.showError(context, e.toString());
      return;
    } finally {
      setState(() {_isLoading = false;});
    }
  }

  _openElemento({required String? elementoID}) async {
    //await DialogUtil.showCustomDialog(
    //    context: context,
    //    height: MediaQuery.sizeOf(context).height * 0.8,
    //    width: MediaQuery.sizeOf(context).width * 0.5,
    //    child: PersonaDetail(personaId: elementoID),
    //    title: 'Datos del usuario'
    //);
    _getData();
  }


  Widget _buildElementoCard(Map<String, dynamic> elemento) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.indigo,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10,),
            Expanded(
              flex: 2,
              child: Text(
                '${elemento['nombre']} ${elemento['apellido_paterno']} ${elemento['apellido_materno']}' ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10,),
            SizedBox(
              width: 115,
              child: PillTag(
                text: elemento['role'] ?? '-',
                backgroundColor: Constants.getColorForRole(elemento['role']),
                icon: Constants.getIconForRole(elemento['role']),
              ),
            ),
            const SizedBox(width: 20,),
            Expanded(
              flex: 2,
              child: Text(
                elemento['correo_electronico'] ?? '-',
                style: AppTheme.light.body,
              ),
            ),
            const Spacer(flex: 3,),
            const SizedBox(width: 10,),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                _openElemento(elementoID: elemento['id']);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black),
              onPressed: () {
                // TODO: Implement delete persona
              },
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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Elementos de configuración', style: AppTheme.light.title1),
                  const Spacer(),
                  Button(
                    width: 200,
                    text: 'Crear CI',
                    icon: Icons.add_box_outlined,
                    onPressed: () {
                      _openElemento(elementoID: null);
                    },
                  )
                ],
              ),
              const SizedBox(height: 20),
              //_buildPersonaHeader(),
              Expanded(
                child: _elementos.isEmpty
                    ? Center(
                  child: Text(
                    "No hay CI's registrados",
                    style: AppTheme.light.body,
                  ),
                )
                    : ListView.builder(
                  itemCount: _elementos.length,
                  itemBuilder: (context, index) {
                    final elemento = _elementos[index];
                    return _buildElementoCard(elemento);
                  },
                ),
              ),
            ],
          ),
        )
    );
  }
}
