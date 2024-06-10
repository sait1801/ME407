import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_desktop_app/providers/image_provider.dart';
import 'package:my_desktop_app/screens/grid_display_Screen.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

class SlicingScreen extends StatefulWidget {
  const SlicingScreen({super.key});

  @override
  _SlicingScreenState createState() => _SlicingScreenState();
}

class _SlicingScreenState extends State<SlicingScreen> {
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

  void _printDimensions() {
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final gridWidth = double.tryParse(_gridWidthController.text) ?? 0;
    final gridHeight = double.tryParse(_gridHeightController.text) ?? 0;

    if (_errorText == null) {
      print('Image Dimensions: Width: $width inches, Height: $height inches');
      print('Grid Width: $gridWidth inches, Grid Height: $gridHeight inches');
    }
  }

  Future<void> sendCommandToPico(String command) async {
    try {
      Socket socket = await Socket.connect('192.168.220.128', 80);
      print('Connected to Pico');

      // Convert the command to bytes
      List<int> bytes = command.codeUnits;
      Uint8List data = Uint8List.fromList(bytes);

      // Send the command data
      socket.add(data);
      await socket.flush();
      print('Command sent: $command');

      // Close the socket
      socket.close();
    } catch (e) {
      print('Error: $e');
    }
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
                width: 4 * 96, // 4 inches in pixels (assuming 96 DPI)
                height: 4 * 96, // 4 inches in pixels (assuming 96 DPI)
                color: Colors.grey[300],
                child: Stack(
                  children: [
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
                        gridHeight:
                            double.tryParse(_gridHeightController.text) ?? 0,
                      ),
                      size: const Size(4 * 96, 4 * 96),
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

          await sendCommandToPico("led_off");
          print("LEDON WORKED");
          //TODO: UNCOMMENT HERE
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => GridDisplayScreen(),
          //   ),
          // );
        },
        child: const Text('PRINT'),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double gridWidth;
  final double gridHeight;

  GridPainter({required this.gridWidth, required this.gridHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    if (gridWidth > 0 && gridHeight > 0) {
      final gridWidthSize =
          gridWidth * 96; // Convert inches to pixels (assuming 96 DPI)
      final gridHeightSize =
          gridHeight * 96; // Convert inches to pixels (assuming 96 DPI)

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
