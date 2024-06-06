import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:my_desktop_app/providers/image_provider.dart';
import 'package:my_desktop_app/screens/grid_display_Screen.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

class SlicingScreen extends StatefulWidget {
  @override
  _SlicingScreenState createState() => _SlicingScreenState();
}

class _SlicingScreenState extends State<SlicingScreen> {
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _gridWidthController = TextEditingController();
  String? _errorText;

  late var model;

  @override
  void initState() {
    super.initState();
    model = Provider.of<ImageProviderModel>(context, listen: false);
    _widthController.text = 4.toStringAsFixed(2); // Set to 4.00
    _heightController.text = 4.toStringAsFixed(2); // Set to 4.00
  }

  void _printDimensions() {
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final gridWidth = double.tryParse(_gridWidthController.text) ?? 0;

    model.imageHeigth = height.toInt();
    model.imageWidth = width.toInt();

    if (_errorText == null) {
      print(
          'Image Dimensions: Width: ${width} inches, Height: ${height} inches');
      print('Grid Width: ${gridWidth} inches');
      _showGrids();
    }
  }

  Future<List<File>> cropImageIntoGrids(
      File imageFile, int rows, int cols) async {
    List<File> gridImages = [];

    // Decode the image file into an Image object
    final decodedImage = img.decodeImage(await imageFile.readAsBytes());

    // Get the dimensions of the image
    final imageWidth = decodedImage!.width;
    final imageHeight = decodedImage.height;

    // Calculate the dimensions of each grid cell
    final cellWidth = imageWidth ~/ cols;
    final cellHeight = imageHeight ~/ rows;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Calculate the coordinates of the current grid cell
        final x = col * cellWidth;
        final y = row * cellHeight;

        // Crop the image to the current grid cell
        final croppedImage = img.copyCrop(
          decodedImage!,
          x: x,
          y: y,
          height: cellWidth,
          width: cellHeight,
        );

        // Encode the cropped image as a PNG file
        final croppedImageFile = File('cropped_image_${row}_${col}.png');
        await croppedImageFile.writeAsBytes(img.encodePng(croppedImage));

        // Add the cropped image file to the list
        gridImages.add(croppedImageFile);
      }
    }

    return gridImages;
  }

  Future<void> _showGrids() async {
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    final gridWidth = double.tryParse(_gridWidthController.text) ?? 0;
    final gridSize = gridWidth * model.imageHeigth / 4;

    if (gridWidth > 0 && model.droppedFiles.isNotEmpty) {
      List<File> gridImages = [];

      gridImages = await cropImageIntoGrids(
        File(model.grayImagePath),
        model.imageHeigth,
        model.imageWidth,
      );

      model.setGridImages(gridImages);

      print(model.gridImages.length);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GridDisplayScreen(gridImages: gridImages),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var model = Provider.of<ImageProviderModel>(context);
    bool dragging = false;
    List<File> droppedFiles = model.droppedFiles;
    String grayImagePath = model.grayImagePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Drag and Drop Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Adjust Image Dimensions (in inches)'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      decoration: InputDecoration(
                        labelText: 'Width',
                        errorText: _errorText,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: false, // Set to non-editable
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        labelText: 'Height',
                        errorText: _errorText,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: false, // Set to non-editable
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _gridWidthController,
                      decoration:
                          const InputDecoration(labelText: 'Grid Width'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 4 * 96, // 4 inches in pixels (assuming 96 DPI)
                height: 4 * 96, // 4 inches in pixels (assuming 96 DPI)
                color: Colors.grey[300],
                child: Stack(
                  children: [
                    // if (grayImagePath != '')
                    // Image.file(File.fromUri(grayImagePath))
                    if (droppedFiles.isNotEmpty)
                      Image.file(
                        droppedFiles.first,
                        fit: BoxFit.cover,
                        width: 4 * 96,
                        height: 4 * 96,
                      ),
                    CustomPaint(
                      painter: GridPainter(
                        gridWidth:
                            double.tryParse(_gridWidthController.text) ?? 0,
                      ),
                      size: Size(4 * 96, 4 * 96),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _printDimensions,
        child: const Text('PRINT'),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridWidth;

  GridPainter({required this.gridWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    if (gridWidth > 0) {
      final gridSize =
          gridWidth * 96; // Convert inches to pixels (assuming 96 DPI)

      for (double x = 0; x < size.width; x += gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      for (double y = 0; y < size.height; y += gridSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
