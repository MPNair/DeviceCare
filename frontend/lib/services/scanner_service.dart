import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/foundation.dart';

class ScannerService {
  static Future<String?> scanCode() async {
    if (kIsWeb) {
      print('Scanner is not supported on Web. Defaulting to manual entry.');
      return null;
    }

    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode) {
        return result.rawContent;
      }
      return null;
    } catch (e) {
      print('Scanning error: $e');
      return null;
    }
  }
}
