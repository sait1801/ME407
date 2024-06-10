// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:wakelock/wakelock.dart'; // Import services to access SystemChrome

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   Wakelock.enable();
//   SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         backgroundColor:
//             Colors.black, // True black background for the AOD effect
//         body: Center(
//           child: AODNotificationWidget(),
//         ),
//       ),
//     );
//   }
// }

// class AODNotificationWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return const Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: <Widget>[
//         Text(
//           'MURADOĞLU',
//           style: TextStyle(
//             fontSize: 1.0,
//             color: Color.fromRGBO(0, 0, 255, 1), // Blue
//           ),
//         ),
//         SizedBox(height: 10),
//         Text(
//           'MURAT BOZ',
//           style: TextStyle(
//             fontSize: 3.0,
//             color: Color.fromRGBO(255, 0, 0, 1), // Red
//           ),
//         ),
//         SizedBox(height: 10),
//         Text(
//           'EKREMOĞLU',
//           style: TextStyle(
//             fontSize: 5.0,
//             color: Color.fromRGBO(0, 255, 0, 1), // Green
//           ),
//         ),
//         SizedBox(height: 10),
//         Text(
//           'MELAK DENŞTAŞ',
//           style: TextStyle(
//             fontSize: 10.0,
//             color: Color.fromRGBO(0, 0, 255, 1), // Blue
//           ),
//         ),
//         SizedBox(height: 10),
//         Text(
//           'EKREM İMARO',
//           style: TextStyle(
//             fontSize: 12.0,
//             color: Color.fromRGBO(255, 0, 0, 1), // Red
//           ),
//         ),
//         SizedBox(height: 10),
//         Text(
//           'MURAT KAVURMA',
//           style: TextStyle(
//             fontSize: 15.0,
//             color: Color.fromRGBO(0, 255, 0, 1), // Green
//           ),
//         ),
//         SizedBox(height: 10),
//         Text(
//           'FUAT KURUM',
//           style: TextStyle(
//             fontSize: 17.0,
//             color: Color.fromRGBO(0, 0, 255, 1), // Blue
//           ),
//         ),
//         SizedBox(height: 10),
//         Text(
//           'MİLADGORUN',
//           style: TextStyle(
//             fontSize: 20.0,
//             color: Color.fromRGBO(255, 0, 0, 1), // Red
//           ),
//         ),
//         SizedBox(height: 10),
//         Text(
//           'İMAMHATİPOĞLU',
//           style: TextStyle(
//             fontSize: 25.0,
//             color: Color.fromRGBO(0, 255, 0, 1), // Green
//           ),
//         ),
//       ],
//     );
//   }
// }
