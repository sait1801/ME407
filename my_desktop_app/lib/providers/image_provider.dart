import 'dart:io';
import 'package:flutter/material.dart';

class ImageProviderModel extends ChangeNotifier {
  List<File> _droppedFiles = [];
  late var decodedImage;
  List<File> _gridImages = [];
  String grayImagePath = '';
  int imageWidth = 0;
  int imageHeigth = 0;
  double dpi = 0;

  List<File> get droppedFiles => _droppedFiles;
  List<File> get gridImages => _gridImages;

  void addFiles(List<File> files) {
    _droppedFiles = files;
    notifyListeners();
  }

  void setGridImages(List<File> images) {
    _gridImages = images;
    notifyListeners();
  }
}
