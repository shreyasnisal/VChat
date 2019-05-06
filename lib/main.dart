import 'package:flutter/material.dart';
import 'Mapping.dart';
import 'Authentication.dart';
import 'SelectContact.dart';

void main() {
  runApp(new Messenger());
}

class Messenger extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Messenger",

      theme: new ThemeData(
        primarySwatch: Colors.indigo,
      ), //ThemeData

      home: MappingPage(auth: Auth()),
      // home: SelectContact(),
    ); //MaterialApp
  }
}
