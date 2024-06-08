import 'dart:io';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:my_desktop_app/providers/image_provider.dart';
import 'package:my_desktop_app/screens/image_drag_drop_screen.dart';
import 'package:provider/provider.dart';

// import 'package:window_size/window_size.dart' as window_size;
// print width : 3.1 mm, heigth : 2.4 mm
//  width : 0.122047 inch, heigth: 0.0944882 inch
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ImageProviderModel(),
      child: MyApp(),
    ),
  );

  doWhenWindowReady(() {
    appWindow.maximize();

    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DragAndDropPage(),
    );
  }
}
