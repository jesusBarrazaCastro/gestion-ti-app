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

class Personas extends StatefulWidget {
  const Personas({super.key});

  @override
  State<Personas> createState() => _Personas();
}

class _Personas extends State<Personas> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _personas = [];


  @override
  void initState() {
    _getData();
    super.initState();
  }

  _getData() async{
    try{
      setState(() {_isLoading = true;});
      final personaResponse = await supabase
          .from('persona')
          .select('*')
          .order('apellido_paterno', ascending: true);
      if(personaResponse.isEmpty) return;
      _personas = personaResponse;
    } catch(e){
      MsgtUtil.showError(context, e.toString());
      return;
    } finally {
      setState(() {_isLoading = false;});
    }
  }

  _openPersona({required String? personaId}) async {
    await DialogUtil.showCustomDialog(
      context: context,
      height: MediaQuery.sizeOf(context).height * 0.8,
      width: MediaQuery.sizeOf(context).width * 0.5,
      child: PersonaDetail(personaId: personaId),
      title: 'Datos del usuario'
    );
    _getData();
  }

  Widget _buildPersonaHeader() {
    return const Padding(
      padding:  EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
           SizedBox(
            width: 40, // espacio para el avatar
            child: Text(''),
          ),
           SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              'Nombre',
              style:  TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
           SizedBox(width: 10),
          SizedBox(
            width: 115,
            child: Text(
              'Rol',
              style:  TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
           SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Text(
              'Correo electrónico',
              style:  TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
           Spacer(flex: 3),
           SizedBox(
            width: 48
          ),
           SizedBox(
              width: 48
          ),
        ],
      ),
    );
  }



  Widget _buildPersonaCard(Map<String, dynamic> persona) {
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
                '${persona['nombre']} ${persona['apellido_paterno']} ${persona['apellido_materno']}' ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10,),
            SizedBox(
              width: 115,
              child: PillTag(
                text: persona['role'] ?? '-',
                backgroundColor: Constants.getColorForRole(persona['role']),
                icon: Constants.getIconForRole(persona['role']),
              ),
            ),
            const SizedBox(width: 20,),
            Expanded(
              flex: 2,
              child: Text(
                persona['correo_electronico'] ?? '-',
                style: AppTheme.light.body,
              ),
            ),
            const Spacer(flex: 3,),
            const SizedBox(width: 10,),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () {
                _openPersona(personaId: persona['id']);
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
                   Text('Usuarios del sistema', style: AppTheme.light.title1),
                   const Spacer(),
                   Button(
                     width: 200,
                       text: 'Agregar persona',
                       icon: Icons.add_box_outlined,
                       onPressed: () {
                         _openPersona(personaId: null);
                       },
                   )
                 ],
               ),
              const SizedBox(height: 20),
              _buildPersonaHeader(),
              Expanded(
                child: _personas.isEmpty
                    ? Center(
                  child: Text(
                    'No hay personas registradas',
                    style: AppTheme.light.body,
                  ),
                )
                    : ListView.builder(
                  itemCount: _personas.length,
                  itemBuilder: (context, index) {
                    final persona = _personas[index];
                    return _buildPersonaCard(persona);
                  },
                ),
              ),
            ],
          ),
        )
    );
  }
}
