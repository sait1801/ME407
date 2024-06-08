// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:my_desktop_app/providers/image_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:image/image.dart' as img;

// class GridDisplayScreen extends StatefulWidget {
//   @override
//   _GridDisplayScreenState createState() => _GridDisplayScreenState();
// }

// class _GridDisplayScreenState extends State<GridDisplayScreen> {
//   img.Image? _currentCroppedImage;
//   Timer? _timer;
//   int x = 0;
//   int y = 0;

//   @override
//   void initState() {
//     super.initState();
//     _startCroppingProcess();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   void _startCroppingProcess() async {
//     var model = Provider.of<ImageProviderModel>(context, listen: false);
//     if (model.droppedFiles.isNotEmpty) {
//       img.Image? originalImage =
//           img.decodeImage(model.droppedFiles.first.readAsBytesSync());
//       if (originalImage != null) {
//         int cropWidth = (model.imageWidth * (1 / 4)).toInt();
//         int cropHeight = (model.imageHeigth * (1 / 4)).toInt();

//         if (x + cropWidth > originalImage.width) {
//           cropWidth = originalImage.width - x;
//         }
//         if (y + cropHeight > originalImage.height) {
//           cropHeight = originalImage.height - y;
//         }

//         var croppedImage = img.copyCrop(originalImage,
//             x: x, y: y, width: cropWidth, height: cropHeight);

//         print(
//             'Cropped image: x=$x, y=$y, width=$cropWidth, height=$cropHeight');

//         x += (model.imageWidth * (1 / 4)).toInt();
//         if (x >= originalImage.width) {
//           x = 0;
//           y += (model.imageHeigth * (1 / 4)).toInt();
//         }

//         _showCroppedImage(croppedImage);
//       }
//     }
//   }

//   void _showCroppedImage(img.Image croppedImage) {
//     _timer?.cancel();
//     setState(() {
//       _currentCroppedImage = croppedImage;
//     });
//     _timer = Timer(const Duration(seconds: 1), () {
//       setState(() {
//         _currentCroppedImage = null;
//       });
//       _startCroppingProcess();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Grid Display'),
//       ),
//       body: Center(
//         child: _currentCroppedImage == null
//             ? const Text('No images to display')
//             : Image.memory(
//                 Uint8List.fromList(img.encodePng(_currentCroppedImage!))),
//       ),
//     );
//   }
// }
