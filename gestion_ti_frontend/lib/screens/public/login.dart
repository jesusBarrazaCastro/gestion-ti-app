import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../main.dart';
import '../../widgets/button.dart';
import '../../widgets/input.dart';


class Login extends StatefulWidget {
  const Login({ Key? key }) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {

  //final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        color: Colors.black,
        progressIndicator: const CircularProgressIndicator(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 20,),
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
                  onPressed: () async{
                    navigateWithPersistence(context, '/home');
                    Navigator.of(context).pop();
                   /* if(!_formKey.currentState!.validate()){
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
                      print(Navigator.of(context).widget.pages);
                      Fluttertoast.showToast(
                        msg: '¡Bienvenido!',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.TOP,
                        webPosition: "right",
                        timeInSecForIosWeb: 3,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                        fontSize: 16
                      );
                      if(context.mounted){
                        context.replace('/home');
                      }
                    } catch(e) {
                      Fluttertoast.showToast(
                        msg: 'E-mail o contraseña incorrectos.',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.TOP,
                        webPosition: "right",
                        timeInSecForIosWeb: 3,
                        webBgColor: "linear-gradient(to right, #FF0000, #FF0000)",
                        textColor: Colors.white,
                        fontSize: 16
                      );
                    }
                    setState(() {_isLoading = false;});*/
                  }
                )
              ],
            ),
          ),
        )
      ),
    );
  }
}