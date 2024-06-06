import 'dart:io';
import 'package:flutter/material.dart';

class GridDisplayScreen extends StatelessWidget {
  final List<File> gridImages;

  GridDisplayScreen({required this.gridImages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grid Display'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        itemCount: gridImages.length,
        itemBuilder: (context, index) {
          return Image.file(gridImages[index]);
        },
      ),
    );
  }
}
