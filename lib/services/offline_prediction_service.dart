import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// Offline pest detection using TFLite model
/// Enables pest scanning without internet connection
class OfflinePredictionService {
  static OfflinePredictionService? _instance;
  static OfflinePredictionService get instance {
    _instance ??= OfflinePredictionService._();
    return _instance!;
  }

  OfflinePredictionService._();

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isModelLoaded = false;

  /// Enable to print input tensor min/max/mean and first 10 pixels.
  /// Catches silent preprocessing mismatches fast.
  bool debugPreprocessing = false;

  // Model constants
  static const int inputSize = 640;
  static const int numClasses = 7;
  static const int numAnchors = 8400;
  static const int numFeatures = 43;
  static const int topK =
      3; // Reduced from 5 → 3: fewer weak anchors in average = +3-5% confidence

  // NMS (Non-Maximum Suppression) threshold
  static const double nmsIouThreshold = 0.5;

  // Minimum average margin between best and 2nd-best class per anchor.
  static const double minAvgMargin = 0.09;

  // ── 3-STATE DETECTION THRESHOLDS ──
  // Calibrated for YOLOv11-S float16 TFLite sigmoid output.
  //
  //   ✅ DETECTED   : confidence ≥ 60%  →  reliable identification
  //   ⚠️ UNCERTAIN  : confidence 45–60% →  possible pest, retake recommended
  //   ❓ OUT_OF_SCOPE: confidence < 45%  →  no recognizable pest / unknown image
  //
  // These replace the old complex multi-guard stack.
  // 60% = 10% above sigmoid baseline (50%), proven via calibration.
  // 45% = just below baseline; anything here is noise or very marginal.
  static const double detectedThreshold = 60.0;
  static const double uncertainThreshold = 45.0;

  // Minimum number of anchors for the best class to be considered a real detection.
  // Real pest objects produce many concentrated anchor hits; random/non-pest images
  // (like humans) produce scattered low-count hits across multiple classes.
  static const int minAnchorCount = 3;

  // Maximum allowed class spread ratio. If the top 2 classes have very similar
  // confidence (ratio > this), the detection is likely noise from a non-pest image.
  // Real pests have one dominant class. Value 0.85 means second class must be < 85% of first.
  static const double maxClassSpreadRatio = 0.85;

  // Maximum number of classes that can have detections simultaneously.
  // Real pest images typically trigger 1-2 classes. If 4+ classes fire, it's noise.
  static const int maxSimultaneousClasses = 3;

  // Default labels for coconut pests
  static const List<String> defaultLabels = [
    'APW Adult',
    'APW Larvae',
    'Brontispa',
    'Brontispa Pupa',
    'Rhinoceros Beetle',
    'Slug Caterpillar',
    'White Grub',
  ];

  /// Check if model is loaded
  bool get isModelLoaded => _isModelLoaded;

  /// Get loaded labels
  List<String> get labels => _labels;

  /// Initialize and load the TFLite model
  Future<bool> loadModel() async {
    if (_isModelLoaded) return true;

    try {
      debugPrint('🤖 [TFLite] Loading model from assets...');

      // Load model from assets
      _interpreter = await Interpreter.fromAsset(
        'assets/model/best_float16.tflite',
      );

      debugPrint('🤖 [TFLite] Model interpreter created');

      // Load labels from assets
      try {
        final labelsData = await rootBundle.loadString(
          'assets/model/labels.txt',
        );
        _labels = labelsData
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
        debugPrint('🤖 [TFLite] Loaded ${_labels.length} labels: $_labels');
      } catch (e) {
        debugPrint('🤖 [TFLite] Failed to load labels, using defaults: $e');
        _labels = List.from(defaultLabels);
      }

      // Log model info
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      debugPrint(
        '🤖 [TFLite] Input: shape=${inputTensor.shape}, type=${inputTensor.type}',
      );
      debugPrint(
        '🤖 [TFLite] Output: shape=${outputTensor.shape}, type=${outputTensor.type}',
      );

      _isModelLoaded = true;
      debugPrint('🤖 [TFLite] Model loaded successfully! ✅');
      return true;
    } catch (e, stackTrace) {
      debugPrint('🤖 [TFLite] ❌ Failed to load model: $e');
      debugPrint('🤖 [TFLite] Stack trace: $stackTrace');
      _isModelLoaded = false;
      return false;
    }
  }

  // ================================================================
  //  LETTERBOX PREPROCESSING (takes decoded img.Image — used by TTA)
  // ================================================================
  Float32List _preprocessDecodedImage(img.Image image) {
    final origW = image.width;
    final origH = image.height;

    final scale = math.min(inputSize / origW, inputSize / origH);
    final newW = (origW * scale).round();
    final newH = (origH * scale).round();

    final resized = img.copyResize(
      image,
      width: newW,
      height: newH,
      interpolation: img
          .Interpolation
          .cubic, // Cubic > linear: sharper edges, better feature preservation
    );

    final padX = (inputSize - newW) ~/ 2;
    final padY = (inputSize - newH) ~/ 2;
    const double grayVal = 114.0 / 255.0;

    final inputData = Float32List(1 * inputSize * inputSize * 3);
    var pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final imgX = x - padX;
        final imgY = y - padY;
        if (imgX >= 0 && imgX < newW && imgY >= 0 && imgY < newH) {
          final pixel = resized.getPixel(imgX, imgY);
          inputData[pixelIndex++] = pixel.r.toDouble() / 255.0;
          inputData[pixelIndex++] = pixel.g.toDouble() / 255.0;
          inputData[pixelIndex++] = pixel.b.toDouble() / 255.0;
        } else {
          inputData[pixelIndex++] = grayVal;
          inputData[pixelIndex++] = grayVal;
          inputData[pixelIndex++] = grayVal;
        }
      }
    }
    return inputData;
  }

  // ================================================================
  //  PREPROCESSING DEBUG DIAGNOSTICS
  // ================================================================
  /// Print tensor statistics to catch silent preprocessing errors.
  /// Enable via `debugPreprocessing = true` before calling predict().
  void _debugTensorStats(Float32List data) {
    if (!debugPreprocessing) return;

    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    double sum = 0;
    for (int i = 0; i < data.length; i++) {
      final v = data[i];
      if (v < minVal) minVal = v;
      if (v > maxVal) maxVal = v;
      sum += v;
    }
    final mean = data.isNotEmpty ? sum / data.length : 0.0;

    debugPrint(
      '🔬 [DEBUG] Input tensor stats: '
      'min=${minVal.toStringAsFixed(4)}, '
      'max=${maxVal.toStringAsFixed(4)}, '
      'mean=${mean.toStringAsFixed(4)}, '
      'length=${data.length}',
    );

    // First 10 pixels (30 values = 10 × RGB)
    final first30 = data.length >= 30
        ? data.sublist(0, 30)
        : data.sublist(0, data.length);
    final pixelStrs = <String>[];
    for (int i = 0; i < first30.length; i += 3) {
      if (i + 2 < first30.length) {
        pixelStrs.add(
          '(${first30[i].toStringAsFixed(3)}, '
          '${first30[i + 1].toStringAsFixed(3)}, '
          '${first30[i + 2].toStringAsFixed(3)})',
        );
      }
    }
    debugPrint('🔬 [DEBUG] First ${pixelStrs.length} pixels (RGB): $pixelStrs');
    debugPrint(
      '🔬 [DEBUG] Preprocessing: RGB order, /255.0 normalize, '
      'letterbox 640×640, float32, gray pad=114/255',
    );
  }

  // ================================================================
  //  IMAGE QUALITY PRE-CHECK
  // ================================================================
  Map<String, dynamic> _assessImageQuality(img.Image image) {
    final issues = <String>[];
    final warnings = <String>[];
    final w = image.width;
    final h = image.height;

    // --- Resolution ---
    if (w < 32 || h < 32) {
      issues.add('Image too small (${w}x$h, minimum 32x32)');
    } else if (w < 100 || h < 100) {
      warnings.add('Low resolution (${w}x$h)');
    }

    // --- Brightness (sampled every 8th pixel for speed) ---
    double totalBr = 0;
    int samples = 0;
    for (int y = 0; y < h; y += 8) {
      for (int x = 0; x < w; x += 8) {
        final p = image.getPixel(x, y);
        totalBr += (p.r.toDouble() + p.g.toDouble() + p.b.toDouble()) / 3.0;
        samples++;
      }
    }
    final meanBr = samples > 0 ? totalBr / samples : 128.0;
    if (meanBr < 10) {
      issues.add(
        'Image too dark (brightness ${meanBr.toStringAsFixed(0)}/255)',
      );
    } else if (meanBr < 30) {
      warnings.add('Very dark image');
    } else if (meanBr > 250) {
      issues.add('Image overexposed');
    } else if (meanBr > 230) {
      warnings.add('Very bright image');
    }

    // --- Sharpness (gradient variance, sampled) ---
    double dxSum = 0, dxSq = 0, dySum = 0, dySq = 0;
    int dxN = 0, dyN = 0;
    for (int y = 0; y < h; y += 4) {
      for (int x = 0; x < w - 1; x += 4) {
        final a = image.getPixel(x, y);
        final b = image.getPixel(x + 1, y);
        final d =
            ((b.r.toDouble() + b.g.toDouble() + b.b.toDouble()) -
                (a.r.toDouble() + a.g.toDouble() + a.b.toDouble())) /
            3.0;
        dxSum += d;
        dxSq += d * d;
        dxN++;
      }
    }
    for (int y = 0; y < h - 1; y += 4) {
      for (int x = 0; x < w; x += 4) {
        final a = image.getPixel(x, y);
        final b = image.getPixel(x, y + 1);
        final d =
            ((b.r.toDouble() + b.g.toDouble() + b.b.toDouble()) -
                (a.r.toDouble() + a.g.toDouble() + a.b.toDouble())) /
            3.0;
        dySum += d;
        dySq += d * d;
        dyN++;
      }
    }
    final dxVar = dxN > 0 ? (dxSq / dxN) - (dxSum / dxN) * (dxSum / dxN) : 0.0;
    final dyVar = dyN > 0 ? (dySq / dyN) - (dySum / dyN) * (dySum / dyN) : 0.0;
    final sharpness = (dxVar + dyVar) / 2.0;
    if (sharpness < 15) {
      issues.add(
        'Image extremely blurry (sharpness ${sharpness.toStringAsFixed(1)})',
      );
    } else if (sharpness < 50) {
      warnings.add('Image appears blurry');
    }

    if (issues.isNotEmpty) {
      debugPrint('🤖 [Quality] ❌ Rejected: ${issues.join('; ')}');
    } else if (warnings.isNotEmpty) {
      debugPrint('🤖 [Quality] ⚠️ Warnings: ${warnings.join('; ')}');
    } else {
      debugPrint(
        '🤖 [Quality] ✅ OK '
        '(brightness=${meanBr.toStringAsFixed(0)}, '
        'sharpness=${sharpness.toStringAsFixed(1)}, ${w}x$h)',
      );
    }

    return {
      'acceptable': issues.isEmpty,
      'issues': issues,
      'warnings': warnings,
      'brightness': meanBr,
      'sharpness': sharpness,
    };
  }

  // ================================================================
  //  TTA AUGMENTATION GENERATION
  // ================================================================
  List<MapEntry<String, img.Image>> _generateAugmentations(img.Image image) {
    final augmentations = <MapEntry<String, img.Image>>[
      MapEntry('original', image),
    ];

    // 1. Horizontal flip
    augmentations.add(
      MapEntry('h-flip', img.flipHorizontal(img.Image.from(image))),
    );

    // 2. Center crop at ~1.3x zoom (multi-scale)
    final w = image.width;
    final h = image.height;
    final cropW = (w * 0.75).round();
    final cropH = (h * 0.75).round();
    final left = (w - cropW) ~/ 2;
    final top = (h - cropH) ~/ 2;
    augmentations.add(
      MapEntry(
        'center-crop-1.3x',
        img.copyCrop(image, x: left, y: top, width: cropW, height: cropH),
      ),
    );

    // 3. Brightness +15%
    final bright = img.Image.from(image);
    img.adjustColor(bright, brightness: 0.15);
    augmentations.add(MapEntry('brightness+15%', bright));

    // 4. Contrast enhancement (+20%) — helps in field conditions
    // (overcast, shade, uneven lighting) where pest features are washed out.
    final contrast = img.Image.from(image);
    img.adjustColor(contrast, contrast: 0.2);
    augmentations.add(MapEntry('contrast+20%', contrast));

    return augmentations;
  }

  // ================================================================
  //  NON-MAXIMUM SUPPRESSION (IoU-based)
  // ================================================================
  /// Remove overlapping detections for the same class, keeping only the
  /// highest-confidence box. This prevents duplicate anchors on the same
  /// pest from diluting the top-K average.
  List<_Detection> _applyNms(List<_Detection> detections, double iouThreshold) {
    if (detections.length <= 1) return detections;

    // Sort by confidence descending
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <_Detection>[];
    final suppressed = List<bool>.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      kept.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        if (_computeIou(detections[i], detections[j]) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return kept;
  }

  /// Compute Intersection-over-Union between two detections.
  double _computeIou(_Detection a, _Detection b) {
    final aX1 = a.cx - a.width / 2;
    final aY1 = a.cy - a.height / 2;
    final aX2 = a.cx + a.width / 2;
    final aY2 = a.cy + a.height / 2;

    final bX1 = b.cx - b.width / 2;
    final bY1 = b.cy - b.height / 2;
    final bX2 = b.cx + b.width / 2;
    final bY2 = b.cy + b.height / 2;

    final interX1 = math.max(aX1, bX1);
    final interY1 = math.max(aY1, bY1);
    final interX2 = math.min(aX2, bX2);
    final interY2 = math.min(aY2, bY2);

    if (interX2 <= interX1 || interY2 <= interY1) return 0.0;

    final interArea = (interX2 - interX1) * (interY2 - interY1);
    final aArea = a.width * a.height;
    final bArea = b.width * b.height;
    final unionArea = aArea + bArea - interArea;

    return unionArea > 0 ? interArea / unionArea : 0.0;
  }

  /// Apply sigmoid function
  double _sigmoid(double x) {
    // Clamp to prevent overflow
    if (x > 20) return 1.0;
    if (x < -20) return 0.0;
    return 1.0 / (1.0 + math.exp(-x));
  }

  /// Process YOLO output to extract detections
  List<Map<String, dynamic>> _processYoloOutput(
    List<List<double>> output,
    double threshold,
  ) {
    debugPrint(
      '🤖 [TFLite] Processing YOLO output with threshold: '
      '${(threshold * 100).toStringAsFixed(0)}%',
    );

    final pestDetections = <int, List<_Detection>>{};
    for (int i = 0; i < numClasses; i++) {
      pestDetections[i] = [];
    }

    // Track per-anchor confusion margins between APW Larvae (1) and White Grub (6).
    // For each anchor assigned to one of these classes, record how much higher
    // its winning logit was vs the other class. Low margins = model is confused.
    const int apwLarvaeClassId = 1;
    const int whiteGrubClassId = 6;
    final confusionMargins = <int, List<double>>{}; // classId -> [margin, ...]

    // Track per-anchor margin (best class prob - 2nd best class prob) for ALL classes.
    // Real pests have avg margins >= 9%; false positives on random objects < 9%.
    // Gap: false positives max 8.0% (scan 14), real pests min 9.8% (scan 25).
    final classMargins = <int, List<double>>{}; // classId -> [margin, ...]

    int totalAboveThreshold = 0;
    int filteredByBoxSize = 0;

    for (int anchorIdx = 0; anchorIdx < numAnchors; anchorIdx++) {
      // Find max class probability and collect all probs for margin calc
      double maxProb = 0.0;
      int maxClassId = 0;
      double secondProb = 0.0;

      for (int classIdx = 0; classIdx < numClasses; classIdx++) {
        final logit = output[4 + classIdx][anchorIdx];
        final prob = _sigmoid(logit);
        if (prob > maxProb) {
          secondProb = maxProb;
          maxProb = prob;
          maxClassId = classIdx;
        } else if (prob > secondProb) {
          secondProb = prob;
        }
      }

      // Filter by threshold
      if (maxProb >= threshold) {
        totalAboveThreshold++;

        // Track confusion margin for APW Larvae vs White Grub anchors
        if (maxClassId == apwLarvaeClassId || maxClassId == whiteGrubClassId) {
          final otherClassId = maxClassId == apwLarvaeClassId
              ? whiteGrubClassId
              : apwLarvaeClassId;
          final otherProb = _sigmoid(output[4 + otherClassId][anchorIdx]);
          final margin = maxProb - otherProb;
          confusionMargins.putIfAbsent(maxClassId, () => []).add(margin);
        }

        // Track margin vs 2nd-best class for every anchor
        final marginVs2nd = maxProb - secondProb;
        classMargins.putIfAbsent(maxClassId, () => []).add(marginVs2nd);

        // Get box coordinates (normalized 0-1 range)
        final cx = output[0][anchorIdx];
        final cy = output[1][anchorIdx];
        final w = output[2][anchorIdx];
        final h = output[3][anchorIdx];

        // Filter invalid boxes:
        // - Too small: w or h < 0.005 (< 0.5% of image = ~3px at 640)
        // - Impossibly large: w or h > 1.5 (> 150% of image)
        // - All zeros: indicates output buffer wasn't filled
        if (w < 0.005 || h < 0.005 || w > 1.5 || h > 1.5) {
          filteredByBoxSize++;
          continue;
        }

        pestDetections[maxClassId]!.add(
          _Detection(confidence: maxProb, cx: cx, cy: cy, width: w, height: h),
        );
      }
    }

    debugPrint(
      '🤖 [TFLite] Detections above threshold: $totalAboveThreshold, filtered by box: $filteredByBoxSize',
    );

    // ── Apply NMS per class to remove overlapping boxes ──
    // This keeps only the best detection in each spatial region,
    // preventing duplicate anchors from diluting confidence averages.
    int totalBeforeNms = 0;
    int totalAfterNms = 0;
    for (int classId = 0; classId < numClasses; classId++) {
      final dets = pestDetections[classId]!;
      totalBeforeNms += dets.length;
      if (dets.length > 1) {
        pestDetections[classId] = _applyNms(dets, nmsIouThreshold);
      }
      totalAfterNms += pestDetections[classId]!.length;
    }
    debugPrint(
      '🤖 [TFLite] NMS: $totalBeforeNms → $totalAfterNms detections '
      '(suppressed ${totalBeforeNms - totalAfterNms} overlapping boxes)',
    );

    // Compute stabilized confidence for each class
    final predictions = <Map<String, dynamic>>[];

    // Log detection counts per class and compute top-k averages for
    // the "too many classes" guard. Only classes with meaningful
    // confidence (top-k avg > 55%) count — the sigmoid noise floor
    // at 50% makes every class appear to have detections.
    int meaningfulClasses = 0;
    const double meaningfulConfidence = 0.55;
    for (int classId = 0; classId < numClasses; classId++) {
      final dets = pestDetections[classId]!;
      if (dets.isEmpty) continue;
      final label = classId < _labels.length ? _labels[classId] : 'Unknown';
      debugPrint(
        '🤖 [TFLite] Class $classId ($label): ${dets.length} detections',
      );
      // Compute top-k average to decide if this is a meaningful detection
      final sorted = List<_Detection>.from(dets)
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      final topKDets = sorted.take(topK).toList();
      final avgC =
          topKDets.fold<double>(0, (s, d) => s + d.confidence) /
          topKDets.length;
      if (avgC >= meaningfulConfidence && dets.length >= minAnchorCount) {
        meaningfulClasses++;
      }
    }

    // === ANTI-FALSE-POSITIVE CHECK: Per-anchor margin filter ===
    // If the average margin between best and 2nd-best class is < 9%,
    // the model is indecisive — likely a non-pest image.
    for (int classId = 0; classId < numClasses; classId++) {
      final margins = classMargins[classId];
      if (margins != null &&
          margins.isNotEmpty &&
          pestDetections[classId]!.isNotEmpty) {
        final avgMargin =
            margins.fold<double>(0, (s, m) => s + m) / margins.length;
        if (avgMargin < minAvgMargin) {
          final label = classId < _labels.length ? _labels[classId] : 'Unknown';
          debugPrint(
            '🤖 [TFLite] WARNING Margin filter: $label avg margin '
            '${(avgMargin * 100).toStringAsFixed(1)}% < ${(minAvgMargin * 100).toStringAsFixed(0)}% '
            '— model indecisive, clearing ${pestDetections[classId]!.length} detections.',
          );
          pestDetections[classId] = [];
        }
      }
    }

    // === NOISE-FLOOR DOMINANT CLASS DETECTION ===
    // Across ALL anchors, find which class the model assigns most often.
    // At the sigmoid noise floor (logit~0, sigmoid~0.5), argmax picks
    // whichever class has the slightest learned bias — typically class 0
    // (APW Adult). This is the model's "default guess" when it sees
    // something it doesn't recognize (teddy bears, food, fabric).
    // If the final detection matches this noise-dominant class, require
    // higher confidence to trust it as a real pest.
    const double noiseClassMinConfidencePct = 68.0;

    final allClassCounts = List<int>.filled(numClasses, 0);
    for (int anchorIdx = 0; anchorIdx < numAnchors; anchorIdx++) {
      double maxP = 0.0;
      int maxC = 0;
      for (int c = 0; c < numClasses; c++) {
        final prob = _sigmoid(output[4 + c][anchorIdx]);
        if (prob > maxP) {
          maxP = prob;
          maxC = c;
        }
      }
      allClassCounts[maxC]++;
    }

    int noiseDominantClass = 0;
    for (int c = 1; c < numClasses; c++) {
      if (allClassCounts[c] > allClassCounts[noiseDominantClass]) {
        noiseDominantClass = c;
      }
    }
    final noisePct = numAnchors > 0
        ? allClassCounts[noiseDominantClass] / numAnchors * 100
        : 0.0;
    final nlabel = noiseDominantClass < _labels.length
        ? _labels[noiseDominantClass]
        : 'Unknown';
    debugPrint(
      '🤖 [TFLite] Noise-dominant class: $nlabel '
      '(${noisePct.toStringAsFixed(1)}% of all $numAnchors anchors)',
    );

    // === ANTI-FALSE-POSITIVE CHECK 1: Too many classes firing ===
    // Non-pest images (humans, objects, etc.) often trigger scattered detections
    // across many classes simultaneously. Real pests concentrate in 1-2 classes.
    // Only count classes with MEANINGFUL confidence (>55%) to avoid counting
    // noise-floor (50%) classes that always appear.
    if (meaningfulClasses > maxSimultaneousClasses) {
      debugPrint(
        '🤖 [TFLite] WARNING FALSE POSITIVE GUARD: $meaningfulClasses classes '
        'have meaningful detections (max allowed: $maxSimultaneousClasses). '
        'This pattern indicates a non-pest image (e.g. human/person). '
        'Returning empty.',
      );
      return [];
    }

    for (int classId = 0; classId < numClasses; classId++) {
      final detections = pestDetections[classId]!;
      if (detections.isEmpty) continue;

      // === ANTI-FALSE-POSITIVE CHECK 2: Minimum anchor count ===
      // Real pest detections produce multiple concentrated anchor hits.
      // Random noise from non-pest images (humans) produces only 1-2 scattered hits.
      if (detections.length < minAnchorCount) {
        final label = classId < _labels.length ? _labels[classId] : 'Unknown';
        debugPrint(
          '🤖 [TFLite] WARNING Skipping $label: only ${detections.length} anchors '
          '(minimum $minAnchorCount required). Likely false positive.',
        );
        continue;
      }

      // === ANTI-FALSE-POSITIVE CHECK 2b: Noise-dominant class needs higher confidence ===
      // The noise-dominant class is what the model "guesses" when uncertain.
      // Random objects (teddy bears, food, fabric) often trigger this class
      // at moderate confidence. Require 68% instead of the normal 60%.
      if (classId == noiseDominantClass) {
        // Sort to peek at top-K average confidence
        final sorted = List<_Detection>.from(detections)
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
        final topK2 = sorted.take(topK).toList();
        final avgC =
            topK2.fold<double>(0, (s, d) => s + d.confidence) / topK2.length;
        if (avgC * 100 < noiseClassMinConfidencePct) {
          final label = classId < _labels.length ? _labels[classId] : 'Unknown';
          debugPrint(
            '🤖 [TFLite] WARNING Skipping $label: noise-dominant class requires '
            '$noiseClassMinConfidencePct% but only has ${(avgC * 100).toStringAsFixed(1)}%. '
            'Likely false positive on non-pest object.',
          );
          continue;
        }
      }

      // Sort by confidence (descending)
      detections.sort((a, b) => b.confidence.compareTo(a.confidence));

      // Take top-k and average
      final topDetections = detections.take(topK).toList();
      final avgConf =
          topDetections.fold<double>(0.0, (sum, d) => sum + d.confidence) /
          topDetections.length;
      final bestDetection = topDetections.first;

      final label = classId < _labels.length
          ? _labels[classId]
          : 'Unknown($classId)';

      debugPrint(
        '🤖 [TFLite] >>> DETECTED: $label at ${(avgConf * 100).toStringAsFixed(1)}% '
        '(${detections.length} anchors)',
      );

      predictions.add({
        'pest_type': label,
        'confidence': (avgConf * 100).roundToDouble(),
        'class_id': classId,
        'anchor_count': detections.length,
        'bbox': {
          'x': bestDetection.cx,
          'y': bestDetection.cy,
          'width': bestDetection.width,
          'height': bestDetection.height,
        },
      });
    }

    // Sort by confidence descending
    predictions.sort(
      (a, b) =>
          (b['confidence'] as double).compareTo(a['confidence'] as double),
    );

    // === CONFUSION PAIR DISAMBIGUATION: APW Larvae vs White Grub ===
    // These two pests look visually similar (both are grub-like larvae) and
    // the model frequently confuses them. When BOTH are detected, use a
    // composite score that combines confidence, anchor proportion, and
    // per-anchor logit margin to pick the true winner.
    if (predictions.length >= 2) {
      final apwIdx = predictions.indexWhere(
        (p) => p['pest_type'] == 'APW Larvae',
      );
      final wgIdx = predictions.indexWhere(
        (p) => p['pest_type'] == 'White Grub',
      );

      if (apwIdx >= 0 && wgIdx >= 0) {
        final apwAnchors = predictions[apwIdx]['anchor_count'] as int;
        final wgAnchors = predictions[wgIdx]['anchor_count'] as int;
        final apwConf = predictions[apwIdx]['confidence'] as double;
        final wgConf = predictions[wgIdx]['confidence'] as double;

        // Compute average per-anchor confusion margin for each class.
        // Higher margin = model was more certain per-anchor for that class.
        final apwMargins = confusionMargins[apwLarvaeClassId] ?? [];
        final wgMargins = confusionMargins[whiteGrubClassId] ?? [];
        final apwAvgMargin = apwMargins.isNotEmpty
            ? apwMargins.reduce((a, b) => a + b) / apwMargins.length
            : 0.0;
        final wgAvgMargin = wgMargins.isNotEmpty
            ? wgMargins.reduce((a, b) => a + b) / wgMargins.length
            : 0.0;

        // Composite score = confidence × anchor_proportion × (1 + avg_margin)
        // - confidence: how confident the top-K average is
        // - anchor_proportion: what fraction of confused anchors belong to this class
        // - (1 + avg_margin): boost for classes where per-anchor logits clearly favor it
        final totalAnchors = apwAnchors + wgAnchors;
        final apwScore =
            apwConf * (apwAnchors / totalAnchors) * (1.0 + apwAvgMargin);
        final wgScore =
            wgConf * (wgAnchors / totalAnchors) * (1.0 + wgAvgMargin);

        // Precautionary principle: APW (Asiatic Palm Weevil) is the #1
        // most destructive coconut pest in SE Asia. When scores are close
        // (within 15%), favor APW Larvae — a false positive leads to an
        // inspection (safe), while a false negative means ignoring a
        // potentially tree-killing infestation.
        final maxScore = math.max(apwScore, wgScore);
        final minScore = math.min(apwScore, wgScore);
        final scoresAreClose = maxScore > 0 && (minScore / maxScore) > 0.85;

        String winner;
        int removeIdx;

        if (scoresAreClose) {
          // Ambiguous — apply precautionary principle: favor APW Larvae
          winner = 'APW Larvae';
          removeIdx = wgIdx;
          debugPrint(
            '🤖 [TFLite] ⚠️ Scores too close (ratio>85%) — '
            'precautionary principle: favoring APW Larvae (more dangerous pest).',
          );
        } else if (apwScore >= wgScore) {
          winner = 'APW Larvae';
          removeIdx = wgIdx;
        } else {
          winner = 'White Grub';
          removeIdx = apwIdx;
        }

        final removed = predictions[removeIdx]['pest_type'];
        debugPrint(
          '🤖 [TFLite] 🔄 DISAMBIGUATION: APW Larvae vs White Grub conflict.\n'
          '   APW Larvae: ${apwConf.toStringAsFixed(1)}% | $apwAnchors anchors | '
          'avg_margin=${apwAvgMargin.toStringAsFixed(3)} | score=${apwScore.toStringAsFixed(2)}\n'
          '   White Grub: ${wgConf.toStringAsFixed(1)}% | $wgAnchors anchors | '
          'avg_margin=${wgAvgMargin.toStringAsFixed(3)} | score=${wgScore.toStringAsFixed(2)}\n'
          '   Winner: $winner, suppressing $removed.',
        );
        predictions.removeAt(removeIdx);

        // Re-sort after removal
        predictions.sort(
          (a, b) =>
              (b['confidence'] as double).compareTo(a['confidence'] as double),
        );
      }
    }

    // === CASE 1: Only White Grub in final list, but APW Larvae had raw anchors ===
    // Sometimes APW Larvae gets filtered out (e.g. not enough anchors) while
    // White Grub remains. But if APW Larvae DID have detections in raw YOLO
    // output, it's likely a genuine APW Larvae that was suppressed.
    // Apply precautionary principle: switch to APW Larvae.
    final wgOnlyIdx = predictions.indexWhere(
      (p) => p['pest_type'] == 'White Grub',
    );
    final apwNotInFinal =
        predictions.indexWhere((p) => p['pest_type'] == 'APW Larvae') < 0;
    final apwHadAnchors =
        (confusionMargins[apwLarvaeClassId] ?? []).isNotEmpty ||
        pestDetections[apwLarvaeClassId]!.isNotEmpty;

    if (wgOnlyIdx >= 0 && apwNotInFinal && apwHadAnchors) {
      final wgConf = predictions[wgOnlyIdx]['confidence'] as double;
      // Only switch if White Grub confidence is not overwhelming
      if (wgConf < 80.0) {
        debugPrint(
          '🤖 [TFLite] ⚠️ PRECAUTIONARY SWITCH: White Grub detected at '
          '${wgConf.toStringAsFixed(1)}% but APW Larvae had raw anchors. '
          'Switching to APW Larvae (precautionary principle).',
        );
        predictions[wgOnlyIdx]['pest_type'] = 'APW Larvae';
        predictions[wgOnlyIdx]['class_id'] = apwLarvaeClassId;
      }
    }

    // === ANTI-FALSE-POSITIVE CHECK 3: Class dominance / spread check ===
    // If the top two classes have very similar confidences, it means the model
    // is "confused" — a hallmark of non-pest images (humans, random objects).
    // Real pest images have one clearly dominant class.
    if (predictions.length >= 2) {
      final topConf = predictions[0]['confidence'] as double;
      final secondConf = predictions[1]['confidence'] as double;
      if (topConf > 0) {
        final ratio = secondConf / topConf;
        if (ratio > maxClassSpreadRatio) {
          debugPrint(
            '🤖 [TFLite] ⚠️ FALSE POSITIVE GUARD: Top two classes too similar '
            '(${topConf.toStringAsFixed(1)}% vs ${secondConf.toStringAsFixed(1)}%, '
            'ratio=${ratio.toStringAsFixed(2)} > $maxClassSpreadRatio). '
            'This indicates a non-pest image. Clearing all predictions.',
          );
          return [];
        }
      }
    }

    debugPrint(
      '🤖 [TFLite] === FINAL: ${predictions.length} pest types detected ===',
    );

    return predictions;
  }

  // ================================================================
  //  SINGLE-INFERENCE HELPER (preprocess → invoke → YOLO post-process)
  // ================================================================
  List<Map<String, dynamic>> _runSingleInference(
    img.Image image,
    double confidenceThreshold,
  ) {
    final outputTensor = _interpreter!.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final dim1 = outputShape[1];
    final dim2 = outputShape[2];

    // Preprocess decoded image
    final inputData = _preprocessDecodedImage(image);
    _debugTensorStats(inputData);
    final input = inputData.reshape([1, inputSize, inputSize, 3]);

    // Output buffer
    var dummyOutput = List.generate(
      1,
      (_) => List.generate(dim1, (_) => List<double>.filled(dim2, 0.0)),
    );

    // Run interpreter
    try {
      _interpreter!.run(input, dummyOutput);
    } catch (_) {
      try {
        final outputMap = <int, Object>{0: dummyOutput};
        _interpreter!.runForMultipleInputs([input], outputMap);
      } catch (_) {
        // Tensor data may still be valid
      }
    }

    // Read raw output from tensor bytes
    final rawBytes = _interpreter!.getOutputTensor(0).data;
    final rawFloats = rawBytes.buffer.asFloat32List();

    // Reshape to [numFeatures, numAnchors]
    List<List<double>> output;
    if (dim1 == numFeatures && dim2 == numAnchors) {
      output = List.generate(
        numFeatures,
        (f) => List.generate(
          numAnchors,
          (a) => rawFloats[f * numAnchors + a].toDouble(),
        ),
      );
    } else if (dim1 == numAnchors && dim2 == numFeatures) {
      output = List.generate(
        numFeatures,
        (f) => List.generate(
          numAnchors,
          (a) => rawFloats[a * numFeatures + f].toDouble(),
        ),
      );
    } else {
      output = List.generate(
        dim1,
        (i) => List.generate(dim2, (j) => rawFloats[i * dim2 + j].toDouble()),
      );
    }

    return _processYoloOutput(output, confidenceThreshold);
  }

  // ================================================================
  //  TTA RESULT AGGREGATION
  // ================================================================
  /// Keep only pest classes detected in >= [minAgreement] augmentations.
  /// Averages confidence scores across agreeing augmentations.
  List<Map<String, dynamic>> _aggregateTtaResults(
    List<List<Map<String, dynamic>>> perAugResults, {
    int minAgreement = 2,
  }) {
    final classDetections = <String, List<Map<String, dynamic>>>{};
    final totalAugs = perAugResults.length;

    for (final preds in perAugResults) {
      final seen = <String>{};
      for (final pred in preds) {
        final pt = pred['pest_type'] as String;
        if (!seen.contains(pt)) {
          classDetections.putIfAbsent(pt, () => []).add(pred);
          seen.add(pt);
        }
      }
    }

    final aggregated = <Map<String, dynamic>>[];
    for (final entry in classDetections.entries) {
      final pestType = entry.key;
      final detections = entry.value;
      final agreement = detections.length;

      if (agreement >= minAgreement) {
        // ── Weighted average: higher-confidence augmentations contribute more ──
        // Plain average treats a 60% augmentation equally to an 80% one.
        // Weighted average gives more influence to clearer detections.
        final totalWeight = detections.fold<double>(
          0,
          (s, d) => s + (d['confidence'] as double),
        );
        final weightedConf = totalWeight > 0
            ? detections.fold<double>(0, (s, d) {
                    final c = d['confidence'] as double;
                    return s + c * c; // weight = confidence itself
                  }) /
                  totalWeight
            : 0.0;

        // Skip noise-floor classes (50% sigmoid baseline)
        if (weightedConf < 55.0) {
          debugPrint(
            '🤖 [TTA] ❌ $pestType: ${weightedConf.toStringAsFixed(1)}% '
            '(below 55% noise floor, skipping)',
          );
          continue;
        }
        final bestDet = detections.reduce(
          (a, b) => (a['confidence'] as double) >= (b['confidence'] as double)
              ? a
              : b,
        );
        aggregated.add({
          'pest_type': pestType,
          'confidence': double.parse(weightedConf.toStringAsFixed(2)),
          'class_id': bestDet['class_id'],
          'anchor_count': detections
              .map((d) => d['anchor_count'] as int)
              .reduce(math.max),
          'bbox': bestDet['bbox'],
          'tta_agreement': agreement,
          'tta_total': totalAugs,
        });
        debugPrint(
          '🤖 [TTA] ✅ $pestType: ${weightedConf.toStringAsFixed(1)}% '
          '(agreed $agreement/$totalAugs augmentations, weighted avg)',
        );
      } else {
        debugPrint(
          '🤖 [TTA] ❌ $pestType: rejected '
          '(only $agreement/$totalAugs, need ≥$minAgreement)',
        );
      }
    }

    // ── Post-TTA disambiguation for APW Larvae vs White Grub ──
    // These two pests are visually identical; different augmentations may
    // pick different winners.  Keep only the one with higher agreement.
    // Tie-break: precautionary principle → favour APW Larvae (more dangerous).
    const confusionPair = {'APW Larvae', 'White Grub'};
    final pairEntries = aggregated
        .where((p) => confusionPair.contains(p['pest_type']))
        .toList();
    if (pairEntries.length == 2) {
      final a = pairEntries[0];
      final b = pairEntries[1];
      Map<String, dynamic> loser;
      if ((a['tta_agreement'] as int) != (b['tta_agreement'] as int)) {
        loser = (a['tta_agreement'] as int) > (b['tta_agreement'] as int)
            ? b
            : a;
      } else {
        // Equal agreement → precautionary: keep APW Larvae
        loser = a['pest_type'] == 'APW Larvae' ? b : a;
      }
      aggregated.remove(loser);
      final winner = pairEntries.firstWhere((p) => !identical(p, loser));
      debugPrint(
        '🤖 [TTA] 🔀 Confusion-pair disambiguation: '
        "keeping ${winner['pest_type']}, "
        "dropping ${loser['pest_type']} "
        "(agreement ${loser['tta_agreement']}/$totalAugs)",
      );
    }

    // Sort by agreement (more augmentations = more reliable), then confidence
    aggregated.sort((a, b) {
      final agreeCmp = (b['tta_agreement'] as int).compareTo(
        a['tta_agreement'] as int,
      );
      if (agreeCmp != 0) return agreeCmp;
      return (b['confidence'] as double).compareTo(a['confidence'] as double);
    });
    return aggregated;
  }

  /// Run pest detection with TTA (Test-Time Augmentation) + multi-scale.
  ///
  /// Pipeline:
  ///   1. Decode image + quality gate
  ///   2. Generate 4 augmented versions (original, h-flip, 1.3x crop, brightness+)
  ///   3. YOLO inference on each augmentation independently
  ///   4. Keep only classes detected in ≥ 2/4 augmentations
  ///   5. Average confidence, apply final 60% threshold
  Future<Map<String, dynamic>> predict(
    Uint8List imageBytes, {
    double confidenceThreshold =
        0.55, // Above 50% sigmoid baseline — filters noise, matches backend
  }) async {
    debugPrint(
      '🤖 [TFLite] ========== STARTING TTA OFFLINE PREDICTION ==========',
    );

    if (!_isModelLoaded) {
      debugPrint('🤖 [TFLite] Model not loaded, loading now...');
      final loaded = await loadModel();
      if (!loaded) {
        debugPrint('🤖 [TFLite] ❌ Failed to load model!');
        return {
          'success': false,
          'status': 'ERROR',
          'error': 'Model not loaded',
          'predictions': [],
          'best_match': null,
          'risk_level': 'out-of-scope',
          'offline': true,
        };
      }
    }

    try {
      // ── Step 1: Decode image + quality gate ──
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        return {
          'success': false,
          'status': 'ERROR',
          'error': 'Failed to decode image',
          'predictions': [],
          'best_match': null,
          'risk_level': 'out-of-scope',
          'offline': true,
        };
      }

      debugPrint(
        '🤖 [TFLite] Image: ${decodedImage.width}x${decodedImage.height}',
      );

      final quality = _assessImageQuality(decodedImage);
      if (quality['acceptable'] != true) {
        final issues = (quality['issues'] as List).join('; ');
        debugPrint(
          '🤖 [Quality] ⚠️ Image quality issues detected but proceeding: $issues',
        );
      }
      // Always proceed with detection - no rejection

      // ── Step 2: Generate augmentations (TTA + multi-scale) ──
      final augmentations = _generateAugmentations(decodedImage);
      debugPrint(
        '🤖 [TTA] Running inference on ${augmentations.length} augmentations...',
      );

      // ── Step 3: Inference per augmentation ──
      final perAugResults = <List<Map<String, dynamic>>>[];
      for (final aug in augmentations) {
        final preds = _runSingleInference(aug.value, confidenceThreshold);
        perAugResults.add(preds);
        final detected = preds
            .map(
              (p) =>
                  '${p['pest_type']}'
                  '(${(p['confidence'] as double).toStringAsFixed(1)}%)',
            )
            .toList();
        debugPrint(
          '🤖 [TTA]   ${aug.key}: '
          '${detected.isNotEmpty ? detected : 'no detections'}',
        );
      }

      // ── Step 4: Aggregate with consistency requirement ──
      final predictions = _aggregateTtaResults(perAugResults, minAgreement: 2);

      debugPrint(
        '🤖 [TTA] === FINAL: ${predictions.length} predictions '
        '(required ≥2/${augmentations.length} agreement) ===',
      );

      if (predictions.isEmpty) {
        debugPrint('🤖 [TFLite] ❌ No consistent pests detected — OUT_OF_SCOPE');
        return {
          'success': true,
          'status': 'OUT_OF_SCOPE',
          'message':
              'No coconut pests detected consistently across augmentations',
          'predictions': [],
          'best_match': null,
          'risk_level': 'out-of-scope',
          'quality': quality,
          'offline': true,
        };
      }

      // ── Step 5: 3-State classification ──
      final bestMatch = predictions.first;
      final bestConfidence = bestMatch['confidence'] as double;

      // Determine retake guidance for uncertain/marginal detections
      final retakeGuidance = _getRetakeGuidance(quality, bestConfidence);

      if (bestConfidence >= detectedThreshold) {
        // ✅ DETECTED — reliable identification
        final riskLevel = _getRiskLevel(bestMatch['pest_type'] as String);
        debugPrint(
          '🤖 [TFLite] ✅ DETECTED: ${bestMatch['pest_type']} '
          'at ${bestMatch['confidence']}% '
          '(${bestMatch['tta_agreement']}/${bestMatch['tta_total']} agreement)',
        );

        return {
          'success': true,
          'status': 'DETECTED',
          'predictions': predictions,
          'best_match': bestMatch,
          'risk_level': riskLevel,
          'total_detections': predictions.length,
          'quality': quality,
          'tta_augmentations': augmentations.length,
          'offline': true,
        };
      } else if (bestConfidence >= uncertainThreshold) {
        // ⚠️ UNCERTAIN — possible pest, retake recommended
        debugPrint(
          '🤖 [TFLite] ⚠️ UNCERTAIN: ${bestMatch['pest_type']} '
          'at ${bestConfidence.toStringAsFixed(1)}% '
          '(between $uncertainThreshold% and $detectedThreshold%) — retake recommended',
        );

        return {
          'success': true,
          'status': 'UNCERTAIN',
          'message':
              'Possible pest detected but confidence is low. '
              'Please retake the photo for a more reliable result.',
          'predictions': predictions,
          'best_match': bestMatch,
          'risk_level': 'uncertain',
          'retake_guidance': retakeGuidance,
          'total_detections': predictions.length,
          'quality': quality,
          'tta_augmentations': augmentations.length,
          'offline': true,
        };
      } else {
        // ❓ OUT_OF_SCOPE — confidence too low
        debugPrint(
          '🤖 [TFLite] ❌ Best TTA confidence '
          '${bestConfidence.toStringAsFixed(1)}% '
          '< $uncertainThreshold% — OUT_OF_SCOPE',
        );
        return {
          'success': true,
          'status': 'OUT_OF_SCOPE',
          'message': 'Detection confidence too low after TTA aggregation',
          'predictions': predictions,
          'best_match': null,
          'risk_level': 'out-of-scope',
          'quality': quality,
          'offline': true,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('🤖 [TFLite] ❌ TTA Prediction error: $e');
      debugPrint('🤖 [TFLite] Stack trace: $stackTrace');
      return {
        'success': false,
        'status': 'ERROR',
        'error': e.toString(),
        'predictions': [],
        'best_match': null,
        'risk_level': 'out-of-scope',
        'offline': true,
      };
    }
  }

  /// Get risk level for a pest type
  String _getRiskLevel(String pestType) {
    switch (pestType) {
      case 'Rhinoceros Beetle':
      case 'APW Adult':
      case 'APW Larvae':
        return 'High';
      case 'Brontispa':
      case 'Brontispa Pupa':
        return 'Medium';
      case 'Slug Caterpillar':
      case 'White Grub':
        return 'Low';
      default:
        return 'out-of-scope';
    }
  }

  // ================================================================
  //  RETAKE GUIDANCE
  // ================================================================
  /// Generate actionable guidance to help the user retake a better photo.
  /// Based on image quality metrics and confidence level.
  List<String> _getRetakeGuidance(
    Map<String, dynamic> quality,
    double confidence,
  ) {
    final guidance = <String>[];

    final brightness = (quality['brightness'] as num?)?.toDouble() ?? 128.0;
    final sharpness = (quality['sharpness'] as num?)?.toDouble() ?? 100.0;
    final warnings = (quality['warnings'] as List?) ?? [];
    final issues = (quality['issues'] as List?) ?? [];

    // Lighting guidance
    if (brightness < 60) {
      guidance.add('Dagdagan ang ilaw — masyadong madilim ang larawan.');
    } else if (brightness > 200) {
      guidance.add('Iwasan ang sobrang liwanag o direct sunlight.');
    }

    // Sharpness guidance
    if (sharpness < 80 || issues.any((i) => i.toString().contains('blur'))) {
      guidance.add('Pigilan ang pagkilos — may motion blur ang larawan.');
    }

    // Resolution guidance
    if (warnings.any((w) => w.toString().contains('Low resolution')) ||
        issues.any((i) => i.toString().contains('too small'))) {
      guidance.add('Lumapit sa peste para sa mas malinaw na larawan.');
    }

    // General confidence-based guidance
    if (confidence < 55) {
      guidance.add('I-center ang peste sa gitna ng frame.');
    }
    if (guidance.isEmpty) {
      // Default guidance when quality seems fine but confidence is still marginal
      guidance.add('Subukang kumuha ng larawan mula sa ibang anggulo.');
      guidance.add('Tiyaking malinaw at maliwanag ang larawan.');
    }

    return guidance;
  }

  /// Dispose of resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
  }
}

/// Internal class for detection data
class _Detection {
  final double confidence;
  final double cx;
  final double cy;
  final double width;
  final double height;

  _Detection({
    required this.confidence,
    required this.cx,
    required this.cy,
    required this.width,
    required this.height,
  });
}
