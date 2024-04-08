import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services to access SystemChrome

void main() {
  // Ensure widgets are initialized before setting the preferred orientations.
  WidgetsFlutterBinding.ensureInitialized();

  // Hide the status bar and the navigation bar.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor:
            Colors.black, // True black background for the AOD effect
        body: Stack(
          children: [
            AODNotificationWidget(),
          ],
        ),
      ),
    );
  }
}

class AODNotificationWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get the screen size for positioning your notification
    Size screenSize = MediaQuery.of(context).size;

    return Positioned(
      top: screenSize.height * 0.5 - 0.5, // Centered vertically
      left: screenSize.width * 0.5 - 0.5, // Centered horizontally
      child: Container(
        height: 1,
        width: 1,
        color: Colors.white, // Single white pixel
      ),
    );
  }
}
