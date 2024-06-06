import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:my_desktop_app/providers/image_provider.dart';
import 'package:my_desktop_app/screens/slicing_screen.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;

class DragAndDropPage extends StatefulWidget {
  @override
  _DragAndDropPageState createState() => _DragAndDropPageState();
}

class _DragAndDropPageState extends State<DragAndDropPage> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    var model = Provider.of<ImageProviderModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MEMS Pro'),
      ),
      body: Center(
        child: DropTarget(
          onDragEntered: (details) {
            setState(() {
              _dragging = true;
            });
          },
          onDragExited: (details) {
            setState(() {
              _dragging = false;
            });
          },
          onDragDone: (details) {
            List<File> files =
                details.files.map((file) => File(file.path)).toList();
            Provider.of<ImageProviderModel>(context, listen: false)
                .addFiles(files);
            setState(() {
              _dragging = false;
            });
          },
          child: Container(
            width: 300,
            height: 300,
            color: _dragging
                ? Colors.blue.withOpacity(0.4)
                : Colors.grey.withOpacity(0.4),
            child: Consumer<ImageProviderModel>(
              builder: (context, model, child) {
                return model.droppedFiles.isEmpty
                    ? const Center(child: Text('Drag and drop images here'))
                    : ListView.builder(
                        itemCount: model.droppedFiles.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.file(model.droppedFiles[index]),
                          );
                        },
                      );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: model.droppedFiles.isNotEmpty
            ? () async {
                await _printImageSizes();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SlicingScreen(),
                  ),
                );
              }
            : () {
                print("image null");
              },
        child: const Text('SLICE'),
      ),
    );
  }

  Future<void> _printImageSizes() async {
    // This code print the size of image
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    for (var file in model.droppedFiles) {
      var decodedImage = await decodeImageFromList(file.readAsBytesSync());
      model.decodedImage = decodedImage;
      print(
          'Image: ${file.path}, Width: ${decodedImage.width}, Height: ${decodedImage.height}');
      await _convertImageToGray(file.path);

      model.imageWidth = decodedImage.width;
      model.imageHeigth = decodedImage.height;
      if (model.imageHeigth > model.imageWidth) {
        model.dpi = 4 / model.imageHeigth;
      } else {
        model.dpi = 4 / model.imageWidth;
      }

      print(decodedImage.colorSpace);
    }
  }

  Future _convertImageToGray(String path) async {
    // This function converts image to grayscle and saves it to both provider 'grayImagePAth' and 'Desktop path'

    var model = Provider.of<ImageProviderModel>(context, listen: false);
    // Read the image from the given path
    final File imageFile = File(path);
    final Uint8List imageBytes = await imageFile.readAsBytes();

    // Decode the image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      print('Error: Could not decode image.');
      return;
    }

    // Convert the image to grayscale
    img.Image grayscaleImage = img.grayscale(image);

    // Encode the grayscale image to PNG
    List<int> grayscaleBytes = img.encodePng(grayscaleImage);

    // Save the grayscale image to a new file with `_gray` suffix
    String newPath = _addGraySuffixToFilename(path);
    final File grayscaleFile = File(newPath);
    await grayscaleFile.writeAsBytes(grayscaleBytes);
    model.grayImagePath = grayscaleFile.path;
    print('Grayscale image saved at ${grayscaleFile.path}');
  }

  String _addGraySuffixToFilename(String path) {
    final extension = path.split('.').last;
    final filenameWithoutExtension =
        path.substring(0, path.length - extension.length - 1);
    return '${filenameWithoutExtension}_gray.$extension';
  }
}
