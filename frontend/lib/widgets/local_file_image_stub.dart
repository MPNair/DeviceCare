import 'package:flutter/material.dart';

/// Placeholder for web where Image.file is not used.
Widget buildLocalFileImage(
  String path, {
  double width = 100,
  double height = 100,
  BoxFit fit = BoxFit.cover,
}) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey.shade300,
    child: Icon(Icons.image_not_supported, color: Colors.grey),
  );
}
