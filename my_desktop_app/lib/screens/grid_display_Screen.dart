import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_desktop_app/providers/image_provider.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

class GridDisplayScreen extends StatefulWidget {
  @override
  _GridDisplayScreenState createState() => _GridDisplayScreenState();
}

class _GridDisplayScreenState extends State<GridDisplayScreen> {
  img.Image? _currentCroppedImage;
  Timer? _timer;
  int x = 0;
  int y = 0;

  @override
  void initState() {
    super.initState();
    _enableKioskMode();
    _startCroppingProcess();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disableKioskMode();
    super.dispose();
  }

  void _enableKioskMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  void _disableKioskMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _startCroppingProcess() async {
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    if (model.droppedFiles.isNotEmpty) {
      img.Image? originalImage =
          img.decodeImage(model.droppedFiles.first.readAsBytesSync());
      if (originalImage != null) {
        int cropWidth = (model.imageWidth * (0.122047 / 4)).toInt();
        int cropHeight = (model.imageHeigth * (0.0944882 / 4)).toInt();

        if (x + cropWidth > originalImage.width) {
          cropWidth = originalImage.width - x;
        }
        if (y + cropHeight > originalImage.height) {
          cropHeight = originalImage.height - y;
        }

        var croppedImage = img.copyCrop(originalImage,
            x: x, y: y, width: cropWidth, height: cropHeight);

        print(
            'Cropped image: x=$x, y=$y, width=$cropWidth, height=$cropHeight');
        if (cropHeight == 0) return;
        x += (model.imageWidth * (0.122047 / 4)).toInt();
        if (x >= originalImage.width) {
          x = 0;
          y += (model.imageHeigth * (0.0944882 / 4)).toInt();
        }

        _showCroppedImage(croppedImage);
      }
    }
  }

  void _showCroppedImage(img.Image croppedImage) {
    _timer?.cancel();
    setState(() {
      _currentCroppedImage = croppedImage;
    });
    _timer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _currentCroppedImage = null;
      });
      _startCroppingProcess();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event.logicalKey == LogicalKeyboardKey.keyQ) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: _currentCroppedImage == null
            ? const Center(child: Text('No images to display'))
            : Container(
                color: Colors.black,
                child: Center(
                  child: Image.memory(
                    Uint8List.fromList(img.encodePng(_currentCroppedImage!)),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
      ),
    );
  }
}
