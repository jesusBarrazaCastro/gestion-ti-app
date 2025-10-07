import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import 'package:gestion_ti_frontend/widgets/date_input.dart';
import 'package:gestion_ti_frontend/widgets/pilltag.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_theme.dart';
import '../../utilities/constants.dart';
import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';

class PersonaDetail extends StatefulWidget {
  final String? personaId;
  const PersonaDetail({super.key, this.personaId});

  @override
  State<PersonaDetail> createState() => _PersonaDetail();
}

class _PersonaDetail extends State<PersonaDetail> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = false;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoPaternoController = TextEditingController();
  final TextEditingController _apellidoMaternoController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final DateInputController _fechaNacimientoController = DateInputController();
  final TextEditingController _passController = TextEditingController();
  DateTime? _fechaNacimiento;
  String? selectedRole;
  final List<String> roles = ['admin', 'supervisor', 'tecnico'];
  final GlobalKey<FormState> _key = GlobalKey();

  bool _logOrder = true;
  dynamic _data;


  @override
  void initState() {
    if(widget.personaId != null) _getData();
    super.initState();
  }

  _getData() async{
    try{
      setState(() {_isLoading = true;});
      final personaResponse = await supabase
          .from('persona')
          .select('*')
          .eq('id', widget.personaId!)
          .maybeSingle();
      if(personaResponse == null) return;
      _data = personaResponse;
      _nombreController.text = _data['nombre']??'';
      _apellidoPaternoController.text = _data['apellido_paterno']??'';
      _apellidoMaternoController.text = _data['apellido_materno']??'';
      _fechaNacimientoController.setDate(DateTime.parse(_data['fecha_nacimiento']));
      selectedRole = _data['role'];
      _correoController.text = _data['correo_electronico']??'';
      _celularController.text = _data['num_celular']??'';
    } catch(e){
      MsgtUtil.showError(context, e.toString());
      return;
    } finally {
      setState(() {_isLoading = false;});
    }
  }

  _savePersona() async {
    if (_nombreController.text.isEmpty ||
        _apellidoPaternoController.text.isEmpty ||
        _apellidoMaternoController.text.isEmpty ||
        selectedRole == null ||
        _fechaNacimientoController.selectedDate == null) {
      MsgtUtil.showError(context, 'Por favor llena todos los campos requeridos.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'nombre': _nombreController.text,
        'apellido_paterno': _apellidoPaternoController.text,
        'apellido_materno': _apellidoMaternoController.text,
        'correo_electronico': _correoController.text,
        'num_celular': _celularController.text,
        'fecha_nacimiento': _fechaNacimientoController.selectedDate?.toIso8601String(),
        'role': selectedRole,
      };

      if (widget.personaId == null) {
        final authResponse = await supabase.auth.signUp(
          email: _correoController.text,
          password: _passController.text,

        );
        if (authResponse.user == null) {
          throw Exception('No se pudo crear el usuario en Auth');
        }

        // Obtener el ID del usuario creado
        final authId = authResponse.user!.id;
        data['id'] = authId;
        final response = await supabase.from('persona').insert(data);
        await MsgtUtil.showSuccess(context, 'Persona creada correctamente');
      } else {
        final response = await supabase.from('persona').update(data).eq('id', widget.personaId!);
        await MsgtUtil.showSuccess(context, 'Persona actualizada correctamente');
      }
      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      MsgtUtil.showError(context, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Widget _userLog(){
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 2),
        color: const Color(0xC7F6F6F6)
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.history, color: Colors.black,),
              const SizedBox(width: 5,),
              Text('Historial de operaciones del usuario', style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),),
            ],
          ),
          const SizedBox(height: 5,),
          const Divider(color: Colors.grey, height: 2,),
          const SizedBox(height: 10,),
          Row(
            children: [
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() {
                    _logOrder = !_logOrder;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _logOrder ? 'Más recientes' : 'Más antiguos',
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontSize: 12
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      _logOrder ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.indigo,
                      size: 14,
                    ),
                  ],
                ),
              )
            ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(
                          Icons.person,
                          size: 90,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 40,),
                      Column(
                        children: [
                          Row(
                            children: [
                              Input(
                                controller: _nombreController,
                                labelText: 'Nombre(s)',
                                width: 500,
                                maxLines: 1,
                                required: true,
                              )
                            ],
                          ),
                          const SizedBox(height: 10,),
                          Row(
                            children: [
                              Input(
                                controller: _apellidoPaternoController,
                                labelText: 'Apellido paterno',
                                width: 245,
                                maxLines: 1,
                                required: true,
                              ),
                              const SizedBox(width: 10,),
                              Input(
                                controller: _apellidoMaternoController,
                                labelText: 'Apellido materno',
                                width: 245,
                                maxLines: 1,
                                required: true,
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      Dropdown<String>(
                        value: selectedRole,
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value;
                          });
                        },
                        items: roles.map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: PillTag(
                              text: role,
                              backgroundColor: Constants.getColorForRole(role),
                              textColor: Colors.white,
                              icon: Constants.getIconForRole(role),
                            ),
                          );
                        }).toList(),
                        labelText: 'Rol',
                        width: 200,
                        borderRadius: BorderRadius.circular(12),
                        borderColor: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 10,),
                      DateInput(
                        controller: _fechaNacimientoController,
                        labelText: 'Fecha de nacimiento',
                        width: 200,
                        required: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Row(
                    children: [
                      Input(
                        controller: _correoController,
                        labelText: 'Correo Electronico',
                        width: 410,
                      ),
                      if(widget.personaId == null)...[
                        const SizedBox(width: 10,),
                        Input(
                          controller: _passController,
                          labelText: 'Contraseña',
                          isPassword: true,
                          width: 250,
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 10,),
                  Input(
                    controller: _celularController,
                    labelText: 'N. de telefono',
                    width: 410,
                  )
                ],
              ),
            ),
            const SizedBox(height: 20,),
            Row(
              children: [
                Button(
                  width: 150,
                  text: 'Guardar',
                  icon: Icons.save,
                  onPressed: _savePersona,
                ),
                const Spacer(),
                Button(
                  width: 150,
                  text: 'Regresar',
                  icon: Icons.arrow_back,
                  backgroundColor: Colors.grey,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            )
          ],
        )
    );
  }
}
