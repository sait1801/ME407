import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:my_desktop_app/providers/image_provider.dart';
import 'package:provider/provider.dart';

class ImageResizer extends StatefulWidget {
  @override
  _ImageResizerState createState() => _ImageResizerState();
}

class _ImageResizerState extends State<ImageResizer> {
  double _width = 300;
  double _height = 300;
  bool _isResizing = false;
  Offset _initialFocalPoint = Offset.zero;
  double _initialWidth = 300;
  double _initialHeight = 300;
  img.Image? _image;

  final double _minWidth = 100;
  final double _minHeight = 100;
  final double _maxWidth = 800;
  final double _maxHeight = 800;

  @override
  void initState() {
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    super.initState();
    _loadImage(model.grayImagePath);
  }

  Future<void> _loadImage(String path) async {
    final File imageFile = File(path);
    final Uint8List imageBytes = await imageFile.readAsBytes();

    // Decode the image
    img.Image? image = img.decodeImage(imageBytes);
    setState(() {
      _image = image;
      _width = image?.width.toDouble() ?? 300;
      _height = image?.height.toDouble() ?? 300;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isResizing = true;
      _initialFocalPoint = details.globalPosition;
      _initialWidth = _width;
      _initialHeight = _height;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isResizing) {
      final Offset delta = details.globalPosition - _initialFocalPoint;
      double newWidth = _initialWidth + delta.dx;
      double newHeight = _initialHeight + delta.dy;

      // Maintain aspect ratio
      double aspectRatio = _initialWidth / _initialHeight;
      if (newWidth / newHeight > aspectRatio) {
        newHeight = newWidth / aspectRatio;
      } else {
        newWidth = newHeight * aspectRatio;
      }

      // Apply constraints
      newWidth = newWidth.clamp(_minWidth, _maxWidth);
      newHeight = newHeight.clamp(_minHeight, _maxHeight);

      setState(() {
        _width = newWidth;
        _height = newHeight;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Resizer'),
      ),
      body: Center(
        child: _image == null
            ? CircularProgressIndicator()
            : Stack(
                children: [
                  Container(
                    width: _width,
                    height: _height,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: MemoryImage(
                            Uint8List.fromList(img.encodePng(_image!))),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpLeftDownRight,
                        child: Container(
                          width: 20,
                          height: 20,
                          color: Colors.blue.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        child: Container(
                          width: 10,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeLeftRight,
                        child: Container(
                          width: 10,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: Container(
                          height: 10,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: Container(
                          height: 10,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
