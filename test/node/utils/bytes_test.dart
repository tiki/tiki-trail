import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:tiki_sdk_dart/src/utils/bytes.dart';

void main() {
  group('bytes utils tests', () {
    test('compact uint size for all ranges', () async {
      Uint8List smallUint = Uint8List(250);
      Uint8List smallCompactSize = compactSize(smallUint);
      int smallSize = compactSizeToInt(smallCompactSize);
      expect(smallSize, 250);
      Uint8List uint = Uint8List(65535);
      Uint8List uintCompactSize = compactSize(uint);
      int uintSize = compactSizeToInt(uintCompactSize);
      expect(uintSize, 65535);
      Uint8List bigUint = Uint8List(294967295);
      Uint8List bigUintCompactSize = compactSize(bigUint);
      int bigUintSize = compactSizeToInt(bigUintCompactSize);
      expect(bigUintSize, 294967295);
    });
    test('compact size 100 random <= 252 sizes test', () async {
      for (int i = 0; i < 100; i++) {
        int tiny = Random().nextInt(252);
        Uint8List cSize = compactSize(Uint8List(tiny));
        int size = compactSizeToInt(cSize);
        expect(size, tiny);
      }
    });
    test('compact size 100 random sizes between 252 and 65535 test', () async {
      for (int i = 0; i < 100; i++) {
        int small = Random().nextInt(65283) + 252;
        Uint8List cSize = compactSize(Uint8List(small));
        int size = compactSizeToInt(cSize);
        expect(small, size);
      }
    });
    test('compact size 100 random sizes between 65535 and 4294967295 test',
        () async {
      for (int i = 0; i < 100; i++) {
        int big = Random().nextInt(4294901760) + 65535;
        Uint8List cSize = compactSize(Uint8List(big));
        int size = compactSizeToInt(cSize);
        expect(big, size);
      }
    });
    test('extract 100 serialized Uint8Lists prepended by Compact Size', () {
      List<int> sizes = [];
      BytesBuilder builder = BytesBuilder();
      for (int i = 0; i < 100; i++) {
        int size = Random().nextInt(1048560);
        sizes.add(size);
        Uint8List uint8list = Uint8List(size);
        Uint8List cSize = compactSize(uint8list);
        builder.add(cSize);
        builder.add(uint8list);
      }
      Uint8List bytes = builder.toBytes();
      List<Uint8List> extractedBytes = extractSerializeBytes(bytes);
      expect(extractedBytes.length, 100);
      for (int i = 0; i < extractedBytes.length; i++) {
        expect(extractedBytes[i].length, sizes[i]);
      }
    });
  });
}
