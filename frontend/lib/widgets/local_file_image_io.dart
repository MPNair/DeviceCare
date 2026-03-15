import 'dart:io';
import 'package:flutter/material.dart';

/// Builds an Image.file widget for a local path. Used on non-web only.
Widget buildLocalFileImage(
  String path, {
  double width = 100,
  double height = 100,
  BoxFit fit = BoxFit.cover,
}) {
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
  );
}
