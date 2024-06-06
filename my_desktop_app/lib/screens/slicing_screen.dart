import 'dart:io';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:my_desktop_app/providers/image_provider.dart';
import 'package:my_desktop_app/screens/grid_display_Screen.dart';
import 'package:provider/provider.dart';

class SlicingScreen extends StatefulWidget {
  @override
  _SlicingScreenState createState() => _SlicingScreenState();
}

class _SlicingScreenState extends State<SlicingScreen> {
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _gridWidthController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    if (model.droppedFiles.isNotEmpty) {
      final firstImage = model.droppedFiles.first;
      _widthController.text = (model.decodedImage!.width! / 96)
          .toStringAsFixed(2); // Assuming 96 DPI
      _heightController.text = (model.decodedImage!.height! / 96)
          .toStringAsFixed(2); // Assuming 96 DPI
    }
  }

  void _validateDimensions() {
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;

    if (width > 4 || height > 4) {
      setState(() {
        _errorText = 'Width and height must not exceed 4 inches';
      });
    } else {
      setState(() {
        _errorText = null;
      });
    }
  }

  void _printDimensions() {
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final gridWidth = double.tryParse(_gridWidthController.text) ?? 0;

    if (_errorText == null) {
      print(
          'Image Dimensions: Width: ${width} inches, Height: ${height} inches');
      print('Grid Width: ${gridWidth} inches');
      _showGrids();
    }
  }

  void _showGrids() {
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    final gridWidth = double.tryParse(_gridWidthController.text) ?? 0;
    final gridSize =
        gridWidth * 96; // Convert inches to pixels (assuming 96 DPI)

    if (gridWidth > 0 && model.droppedFiles.isNotEmpty) {
      final image = model.droppedFiles.first;
      final decodedImage = model.decodedImage!;
      final rows = (decodedImage.height! / gridSize).ceil();
      final cols = (decodedImage.width! / gridSize).ceil();

      List<File> gridImages = [];

      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          // Here you would slice the image into grids and save them as files
          // For simplicity, we are just adding the original image multiple times
          gridImages.add(image);
        }
      }

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
                      onChanged: (_) => _validateDimensions(),
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
                      onChanged: (_) => _validateDimensions(),
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
