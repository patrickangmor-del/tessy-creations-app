import 'dart:io';

import 'package:flutter/material.dart';

/// Full-screen, swipe-between-photos viewer — opened by tapping any
/// thumbnail in a [PhotoGalleryField] or a read-only [PhotoStrip].
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({super.key, required this.photoPaths, this.initialIndex = 0});

  final List<String> photoPaths;
  final int initialIndex;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photoPaths.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photoPaths.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          child: Center(
            child: Image.file(File(widget.photoPaths[i])),
          ),
        ),
      ),
    );
  }
}
