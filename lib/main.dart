import 'package:flutter/material.dart';

import 'controller/home.dart';

void main() {
  runApp(const DlaApp());
}

class DlaApp extends StatelessWidget {
  const DlaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DLA',
      theme: ThemeData(
        colorSchemeSeed: Colors.cyan
      ),
      home: const DlaHomePage(title: 'DLA'),
      debugShowCheckedModeBanner: false,
    );
  }
}
