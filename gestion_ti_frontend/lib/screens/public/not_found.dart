import 'package:flutter/material.dart';

class NotFound extends StatefulWidget {
  const NotFound({ Key? key }) : super(key: key);

  @override
  _NotFoundState createState() => _NotFoundState();
}

class _NotFoundState extends State<NotFound> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: const Center(
        child: Text('Page Not Found'),
      ),
    );
  }
}