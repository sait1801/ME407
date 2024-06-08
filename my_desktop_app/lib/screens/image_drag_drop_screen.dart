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
            List<File> files = details.files
                .map((file) => File(file.path))
                .where((file) => _isImageFile(file))
                .toList();

            if (files.isNotEmpty) {
              Provider.of<ImageProviderModel>(context, listen: false)
                  .addFiles(files);
            }

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

  bool _isImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff'].contains(extension);
  }

  Future<void> _printImageSizes() async {
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    for (var file in model.droppedFiles) {
      var decodedImage = await decodeImageFromList(file.readAsBytesSync());
      model.decodedImage = decodedImage;
      print(
          'Image: ${file.path}, Width: ${decodedImage.width}, Height: ${decodedImage.height}');
      await _convertImageToGray(file.path);

      model.imageWidth = decodedImage.width;
      model.imageHeigth = decodedImage.height;

      print(decodedImage.colorSpace);
    }
  }

  Future _convertImageToGray(String path) async {
    var model = Provider.of<ImageProviderModel>(context, listen: false);
    final File imageFile = File(path);
    final Uint8List imageBytes = await imageFile.readAsBytes();

    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      print('Error: Could not decode image.');
      return;
    }

    img.Image grayscaleImage = img.grayscale(image);
    List<int> grayscaleBytes = img.encodePng(grayscaleImage);

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
