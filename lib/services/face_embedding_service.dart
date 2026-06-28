import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceMatchResult {
  const FaceMatchResult({
    required this.matched,
    required this.distance,
    required this.threshold,
  });

  final bool matched;
  final double distance;
  final double threshold;
}

class FaceEmbeddingService {
  FaceEmbeddingService._();
  static final instance = FaceEmbeddingService._();

  static const inputSize = 112;
  static const defaultThreshold = 0.85;

  Interpreter? _interpreter;

  Future<Interpreter> get _loadedInterpreter async {
    final existing = _interpreter;
    if (existing != null) return existing;

    try {
      final options = InterpreterOptions()..threads = 2;
      final interpreter = await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
        options: options,
      );
      _interpreter = interpreter;
      return interpreter;
    } catch (error) {
      throw StateError('Model biometrik wajah gagal dimuat: $error');
    }
  }

  Future<List<double>> embeddingFromFile(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = image_lib.decodeImage(bytes);
      if (decoded == null) {
        throw StateError('Foto wajah tidak dapat dibaca.');
      }

      final oriented = image_lib.bakeOrientation(decoded);
      final shortestSide = math.min(oriented.width, oriented.height);
      final cropSize = math.max(1, (shortestSide * 0.86).round());
      final left = ((oriented.width - cropSize) / 2).round();
      final top = ((oriented.height - cropSize) / 2).round();

      final cropped = image_lib.copyCrop(
        oriented,
        x: left,
        y: top,
        width: cropSize,
        height: cropSize,
      );
      final resized = image_lib.copyResize(
        cropped,
        width: inputSize,
        height: inputSize,
      );

      return _embeddingFromImage(resized);
    } on StateError {
      rethrow;
    } catch (error) {
      throw StateError('Gagal memproses foto wajah: $error');
    }
  }

  Future<List<double>> _embeddingFromImage(image_lib.Image image) async {
    final interpreter = await _loadedInterpreter;
    final outputShape = interpreter.getOutputTensor(0).shape;
    final outputLength = outputShape.fold<int>(1, (total, item) => total * item);
    final embeddingLength = outputShape.length > 1 ? outputShape.last : outputLength;
    final input = _imageToInput(image);
    final output = List.generate(1, (_) => List<double>.filled(embeddingLength, 0));

    try {
      interpreter.run(input, output);
      return _normalize(output.first);
    } catch (error) {
      throw StateError('Gagal membuat data biometrik wajah: $error');
    }
  }

  List<List<List<List<double>>>> _imageToInput(image_lib.Image image) {
    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final pixel = image.getPixel(x, y);
          return [
            (pixel.r.toDouble() - 128.0) / 128.0,
            (pixel.g.toDouble() - 128.0) / 128.0,
            (pixel.b.toDouble() - 128.0) / 128.0,
          ];
        });
      }),
    ];
  }

  List<double> _normalize(List<double> values) {
    final norm = math.sqrt(values.fold<double>(0, (sum, item) => sum + item * item));
    if (norm == 0) return values;
    return values.map((item) => item / norm).toList(growable: false);
  }

  FaceMatchResult compare(
    List<double> reference,
    List<double> candidate, {
    double threshold = defaultThreshold,
  }) {
    if (reference.length != candidate.length) {
      throw StateError('Data biometrik tidak valid. Silakan ulangi foto acuan.');
    }

    var distance = 0.0;
    for (var i = 0; i < reference.length; i++) {
      final diff = reference[i] - candidate[i];
      distance += diff * diff;
    }
    distance = math.sqrt(distance);

    return FaceMatchResult(
      matched: distance <= threshold,
      distance: distance,
      threshold: threshold,
    );
  }
}
