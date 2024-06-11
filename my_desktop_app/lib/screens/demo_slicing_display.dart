import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_desktop_app/providers/image_provider.dart';
import 'package:my_desktop_app/screens/grid_display_Screen.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

class DemoSlicingScreen extends StatefulWidget {
  const DemoSlicingScreen({super.key});

  @override
  _DemoSlicingScreenState createState() => _DemoSlicingScreenState();
}

class _DemoSlicingScreenState extends State<DemoSlicingScreen> {
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _gridWidthController = TextEditingController();
  final TextEditingController _gridHeightController = TextEditingController();
  String? _errorText;

  late var model;

  @override
  void initState() {
    super.initState();
    model = Provider.of<ImageProviderModel>(context, listen: false);
    _widthController.text = 4.toStringAsFixed(2); // Set to 4.00
    _heightController.text = 4.toStringAsFixed(2); // Set to 4.00
    _gridWidthController.text = '0.122047'; // Set to 0.122047 inch
    _gridHeightController.text = '0.0944882'; // Set to 0.0944882 inch
  }

  @override
  Widget build(BuildContext context) {
    var model = Provider.of<ImageProviderModel>(context);
    List<File> droppedFiles = model.droppedFiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SLICING ALGORITHM'),
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
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gridWidthController,
                      decoration: const InputDecoration(
                        labelText: 'Grid Width',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: false, // Set to non-editable
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _gridHeightController,
                      decoration: const InputDecoration(
                        labelText: 'Grid Height',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      enabled: false, // Set to non-editable
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: (0.4 * model.imageWidth)
                    .toDouble(), // 4 inches in pixels (assuming 96 DPI)
                height: (0.4 * model.imageHeigth)
                    .toDouble(), // 4 inches in pixels (assuming 96 DPI)
                color: Colors.grey[300],
                child: Stack(
                  children: [
                    if (droppedFiles.isNotEmpty)
                      Image.file(
                        droppedFiles.first,
                        // fit: BoxFit.cover,
                        width: (0.4 * model.imageWidth)
                            .toDouble(), // 4 inches in pixels (assuming 96 DPI)
                        height: (0.4 * model.imageHeigth).toDouble(),
                      ),
                    CustomPaint(
                      painter: GridPainter(
                        context: context,
                        gridWidth:
                            double.tryParse(_gridWidthController.text) ?? 0,
                        gridHeight:
                            double.tryParse(_gridHeightController.text) ?? 0,
                      ),
                      size: Size((0.4 * model.imageWidth).toDouble(),
                          (0.4 * model.imageHeigth).toDouble()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // here will be communication with pi pico
          model.sliceSize = double.tryParse(_gridWidthController.text) ?? 0;
        },
        child: const Text('PRINT'),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridWidth;
  final double gridHeight;
  final BuildContext context;

  GridPainter(
      {required this.gridWidth,
      required this.gridHeight,
      required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final model = Provider.of<ImageProviderModel>(context, listen: false);

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    print("SLICA SIZE: ${model.sliceSize}");
    print("DPI: ${model.dpi}");

    if (gridWidth > 0 && gridHeight > 0) {
      final gridWidthSize = (0.4 * model.imageWidth) *
          gridWidth /
          4.toDouble(); // Convert inches to pixels (assuming 96 DPI)
      final gridHeightSize = (0.4 * model.imageHeigth) *
          gridHeight /
          4.toDouble(); // Convert inches to pixels (assuming 96 DPI)

      for (double x = 0; x < size.width; x += gridWidthSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }

      for (double y = 0; y < size.height; y += gridHeightSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
