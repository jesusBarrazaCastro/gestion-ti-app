import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../widgets/button.dart';
import '../../widgets/dropdown.dart';
import '../../widgets/input.dart';


class HomeScreen extends StatefulWidget {
  final String? title;
  const HomeScreen({ Key? key, this.title }) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {

  bool _isLoading = false;
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  String? _selectedValue;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title??'',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20,),
            Input(
              labelText: 'Usuario',
              controller: _userController
            ),
            const SizedBox(height: 10,),
            Input(
              labelText: 'Contraseña',
              controller: _passController
            ),
            const SizedBox(height: 10,),
            Dropdown(
              labelText: 'Opciones',
              value: _selectedValue,
              items: const [
                DropdownMenuItem(value: '1', child: Text('Opcion 1'),),
                DropdownMenuItem(value: '2', child: Text('Opcion 2'),),
                DropdownMenuItem(value: '3', child: Text('Opcion 3'),)
              ],
              onChanged: (value){
                _selectedValue = value;
                setState(() {});
              }
            ),
            const SizedBox(height: 10,),
            Button(
              text: 'Load',
              onPressed: () async{
                _isLoading = true;
                setState(() {});
                await Future.delayed(const Duration(seconds: 4));
                _isLoading = false;
                setState(() {});
              }
            )
          ],
        ),
      )
    );
  }
}