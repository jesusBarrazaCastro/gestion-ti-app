import 'package:flutter/material.dart';
import 'package:gestion_ti_frontend/app_theme.dart';
import 'package:gestion_ti_frontend/utilities/msg_util.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../widgets/button.dart';
import '../../widgets/input.dart';
import 'dart:html' as html;



class Login extends StatefulWidget {
  const Login({ Key? key }) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();


  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userData['id'].toString());
    await prefs.setString('user_name', userData['nombre'] ?? '');
    await prefs.setString('user_mail', userData['correo_electronico'] ?? '');
    await prefs.setString('role', userData['role'] ?? '');
  }

  Future<void> _login() async{
    if(!_formKey.currentState!.validate()){
      return;
    }
    setState(() {_isLoading = true;});
    try {
      var response = await supabase.auth.signInWithPassword(
          email: _userController.text,
          password: _passController.text
      );
      final Session? session = response.session;
      final User? user = response.user;

      if(user == null) {
        MsgtUtil.showError(context, 'Usuario no encontrado.');
        return;
      }
      final personaResponse = await supabase
          .from('persona')
          .select('id, nombre, apellido_paterno, correo_electronico, role')
          .eq('id', user.id)
          .maybeSingle();
      if (personaResponse == null) {
        MsgtUtil.showError(context, 'No se encontraron datos del usuario.');
        return;
      }
      _saveUserData({
        'user_id': personaResponse['id'],
        'nombre': '${ personaResponse['nombre']} ${personaResponse['apellido_paterno']}',
        'correo': personaResponse['correo_electronico'],
        'role': personaResponse['role']
      });
      MsgtUtil.showSuccess(context, 'Bienvenido ${personaResponse['nombre']}');
      html.window.history.replaceState(null, '', '/home');
      context.go('/home');
    } catch(e) {
      MsgtUtil.showError(context, 'E-mail o contraseña incorrectos.');
    }
    setState(() {_isLoading = false;});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        color: Colors.black,
        progressIndicator: const CircularProgressIndicator(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(flex: 4, child: Image.asset('assets/images/logo.png', scale: .9)),
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: AppTheme.light.primary.withOpacity(0.1),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Iniciar Sesión', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 30),),
                            const SizedBox(height: 25,),
                            Input(
                              width: 300,
                              labelText: 'E-mail',
                              controller: _userController,
                              required: true,
                            ),
                            const SizedBox(height: 10,),
                            Input(
                              width: 300,
                              labelText: 'Contraseña',
                              controller: _passController,
                              isPassword: true,
                              required: true,
                            ),
                            const SizedBox(height: 10,),
                            Button(
                              text: 'Iniciar sesión',
                              width: 300,
                              onPressed: _login
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 100,
              color: AppTheme.light.primary,
            )
          ],
        )
      ),
    );
  }
}