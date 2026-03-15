import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'image_ops.dart';

/// 信號量，用於限制並行任務數量。
class Semaphore {
  final int maxCount;
  int _current = 0;
  final _queue = <Completer<void>>[];

  Semaphore(this.maxCount) : assert(maxCount > 0);

  Future<void> acquire() {
    if (_current < maxCount) {
      _current++;
      return Future.value();
    }
    final c = Completer<void>();
    _queue.add(c);
    return c.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete();
    } else {
      _current--;
    }
  }

  /// 在獲取許可後執行 [fn]，完成後自動釋放。
  Future<T> withPermit<T>(Future<T> Function() fn) async {
    await acquire();
    try {
      return await fn();
    } finally {
      release();
    }
  }
}

/// 在 isolate 中生成單張 PNG 圖片，回傳編碼後的位元組。
///
/// 所有參數均透過可序列化的型別傳遞，確保跨 isolate 通訊安全。
Future<Uint8List> generatePngInIsolate({
  required Uint8List? fgBytes,
  required Uint8List? bgBytes,
  required int targetW,
  required int targetH,
  required String layer,
  required bool whiteBase,
  required double? radius,
  required double margin,
}) async {
  try {
    final receivePort = ReceivePort();
    final params = <Object?>[
      receivePort.sendPort,
      fgBytes,
      bgBytes,
      targetW,
      targetH,
      layer,
      whiteBase,
      radius,
      margin,
    ];

    await Isolate.spawn(_isolateWorker, params);

    final result = await receivePort.first.timeout(
      const Duration(seconds: 30),
      onTimeout: () => Uint8List(0),
    );
    receivePort.close();
    return result as Uint8List;
  } catch (e) {
    return Uint8List(0);
  }
}

/// Isolate 工作函式：接收原始參數、執行圖片處理、回傳 PNG 位元組。
void _isolateWorker(List<Object?> params) {
  final sendPort = params[0]! as SendPort;
  final fgBytes = params[1] as Uint8List?;
  final bgBytes = params[2] as Uint8List?;
  final targetW = params[3]! as int;
  final targetH = params[4]! as int;
  final layer = params[5]! as String;
  final whiteBase = params[6]! as bool;
  final radius = params[7] as double?;
  final margin = params[8]! as double;

  try {
    final fgImg = fgBytes != null ? img.decodeImage(fgBytes) : null;
    final bgImg = bgBytes != null ? img.decodeImage(bgBytes) : null;

    if (fgBytes != null && fgImg == null) {
      Isolate.exit(sendPort, Uint8List(0));
    }
    if (bgBytes != null && bgImg == null) {
      Isolate.exit(sendPort, Uint8List(0));
    }

    img.Image result;
    if (layer == 'foreground') {
      result = scaleProportional(fgImg!, targetW, targetH, margin: margin);
    } else if (layer == 'background') {
      result = stretch(bgImg!, targetW, targetH);
    } else if (layer == 'merged') {
      result = merge(fgImg, bgImg, targetW, targetH,
          whiteBase: whiteBase, margin: margin);
    } else {
      Isolate.exit(sendPort, Uint8List(0));
    }

    result = applyRoundedCorners(result, radius);

    final pngBytes = Uint8List.fromList(img.encodePng(result));
    Isolate.exit(sendPort, pngBytes);
  } catch (e) {
    Isolate.exit(sendPort, Uint8List(0));
  }
}

/// 在 isolate 中為指定尺寸生成圖片，回傳 PNG 位元組。
///
/// 此為 ICO/ICNS 多尺寸生成所使用的 isolate 入口，使用 [generateImageForSize]。
Future<Uint8List> generateImageForSizeInIsolate({
  required Uint8List? fgBytes,
  required Uint8List? bgBytes,
  required int size,
  required bool whiteBase,
  required double? radius,
  required double margin,
}) async {
  try {
    final receivePort = ReceivePort();
    final params = <Object?>[
      receivePort.sendPort,
      fgBytes,
      bgBytes,
      size,
      whiteBase,
      radius,
      margin,
    ];

    await Isolate.spawn(_isolateWorkerForSize, params);

    final result = await receivePort.first.timeout(
      const Duration(seconds: 30),
      onTimeout: () => Uint8List(0),
    );
    receivePort.close();
    return result as Uint8List;
  } catch (e) {
    return Uint8List(0);
  }
}

void _isolateWorkerForSize(List<Object?> params) {
  final sendPort = params[0]! as SendPort;
  final fgBytes = params[1] as Uint8List?;
  final bgBytes = params[2] as Uint8List?;
  final size = params[3]! as int;
  final whiteBase = params[4]! as bool;
  final radius = params[5] as double?;
  final margin = params[6]! as double;

  try {
    final fgImg = fgBytes != null ? img.decodeImage(fgBytes) : null;
    final bgImg = bgBytes != null ? img.decodeImage(bgBytes) : null;

    if (fgBytes != null && fgImg == null) {
      Isolate.exit(sendPort, Uint8List(0));
    }
    if (bgBytes != null && bgImg == null) {
      Isolate.exit(sendPort, Uint8List(0));
    }

    final result = generateImageForSize(
      size, size, fgImg, bgImg,
      whiteBase: whiteBase, radius: radius, margin: margin,
    );

    final pngBytes = Uint8List.fromList(img.encodePng(result));
    Isolate.exit(sendPort, pngBytes);
  } catch (e) {
    Isolate.exit(sendPort, Uint8List(0));
  }
}
