import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import services to access SystemChrome

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        body: Center(
          child: AODNotificationWidget(),
        ),
      ),
    );
  }
}

class AODNotificationWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'MURADOĞLU',
          style: TextStyle(
            fontSize: 1.0, // Font size 1 pixel
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'MURAT BOZ',
          style: TextStyle(
            fontSize: 3.0, // Font size 1 pixel
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'EKREMOĞLU',
          style: TextStyle(
            fontSize: 5.0, // Font size 1 pixel
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'MELAK DENŞTAŞ',
          style: TextStyle(
            fontSize: 10.0, // Font size 1 pixel
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'EKREM İMARO',
          style: TextStyle(
            fontSize: 15.0, // Font size 1 pixel
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10), // Space between texts
        Text(
          'MURAT KAVURMA',
          style: TextStyle(
            fontSize: 17.0, // Font size 3 pixels
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10), // Space between texts
        Text(
          'FUAT KURUM',
          style: TextStyle(
            fontSize: 25.0, // Font size 5 pixels
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10), // Space between texts
        Text(
          'MİLADGORUN',
          style: TextStyle(
            fontSize: 25.0, // Font size 5 pixels
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10), // Space between texts
        Text(
          'İMAMHATİPOĞLU',
          style: TextStyle(
            fontSize: 25.0, // Font size 5 pixels
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
