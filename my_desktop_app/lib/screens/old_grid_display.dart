// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:my_desktop_app/providers/image_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:image/image.dart' as img;

// class GridDisplayScreen extends StatelessWidget {
//   GridDisplayScreen();

//   late var model;

//   // @override
//   // void initState() {
//   //   super.initState();
//   //   model = Provider.of<ImageProviderModel>(context, listen: false);
//   // }

//   // Future<img.Image> cropImageIntoGrids(
//   //     File imageFile, int rows, int cols, int rowIndex, int colIndex) async {
//   //   List<File> gridImages = [];

//   //   // Decode the image file into an Image object
//   //   final decodedImage = img.decodeImage(await imageFile.readAsBytes());

//   //   // Get the dimensions of the image
//   //   const imageWidthInch = 4;
//   //   const imageHeightInch = 4;

//   //   // Calculate the dimensions of each grid cell
//   //   final cellWidth = imageWidthInch ~/ cols; // in inch
//   //   final cellHeight = imageHeightInch ~/ rows;

//   //   // Crop the image to the current grid cell
//   //   final croppedImage = img.copyCrop(
//   //     decodedImage!,
//   //     x: rowIndex,
//   //     y: colIndex,
//   //     height: cellWidth,
//   //     width: cellHeight,
//   //   );

//   //   print("grid images length : ${gridImages.length}");

//   //   return croppedImage;
//   // }

//   // Future<void> _showGrids() async {
//   //   final gridWidth = double.tryParse(_gridWidthController.text) ?? 0;
//   //   model.dpi = (4 / gridWidth).ceil().toDouble();

//   //   if (gridWidth > 0 && model.droppedFiles.isNotEmpty) {
//   //     img.Image gridImage = await cropImageIntoGrids(
//   //       File(model.grayImagePath),
//   //       model.imageHeigth,
//   //       model.imageWidth,
//   //     );
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     var model = Provider.of<ImageProviderModel>(context, listen: false);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Grid Display'),
//       ),
//       body: GridView.builder(
//         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: model.dpi.ceil(),
//         ),
//         itemCount: 5,
//         itemBuilder: (context, index) {
//           return;
//         },
//       ),
//     );
//   }
// }
