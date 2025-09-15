import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../widgets/button.dart';
import '../../widgets/input.dart';

class Base extends StatefulWidget {
  const Base({super.key});

  @override
  State<Base> createState() => _Base();
}

class _Base extends State<Base> {

  bool _isLoading = false;

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

            ],
          ),
        )
    );
  }
}
