// Stub for web: provides File-like type when dart:io is not available.
import 'dart:typed_data';

class File {
  final String path;
  File(this.path);
  Future<Uint8List> readAsBytes() async =>
      throw UnsupportedError('File.readAsBytes not available on web');
}
