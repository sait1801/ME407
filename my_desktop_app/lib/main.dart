import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_desktop_app/providers/image_provider.dart';
import 'package:my_desktop_app/screens/image_drag_drop_screen.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the minimum and maximum window size
  if (Platform.isWindows) {
    setWindowMinSize(const Size(1200, 800));
    setWindowMaxSize(const Size(1200, 800));
  }
  runApp(
    ChangeNotifierProvider(
      create: (context) => ImageProviderModel(),
      child: MyApp(),
    ),
  );
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
