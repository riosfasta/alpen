import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feature_camera/camera.dart';
import 'package:flutter_feature_face_detection/flutter_feature_camera.dart';
import 'package:flutter_feature_face_detection/flutter_feature_face_detection.dart';

import '../core/app_theme.dart';
import '../core/navigation.dart';
import '../services/face_embedding_service.dart';
import '../services/local_face_auth_service.dart';
import '../widgets/app_widgets.dart';

class FaceAuthenticationPage extends StatefulWidget {
  const FaceAuthenticationPage({
    super.key,
    required this.user,
    this.verificationOnly = false,
  });

  final Map<String, dynamic> user;
  final bool verificationOnly;

  @override
  State<FaceAuthenticationPage> createState() => _FaceAuthenticationPageState();
}

class _FaceAuthenticationPageState extends State<FaceAuthenticationPage>
    with BaseMixinFeatureCameraV2 {
  late final FaceDetectionRepository faceRepository;
  late final name = TextEditingController(
    text: _userValue('name', fallback: widget.user['name']),
  );
  late final employeeNumber = TextEditingController(
    text: _userValue('employeeNumber', fallback: widget.user['username']),
  );
  late final address = TextEditingController(text: _userValue('address'));
  late final phone = TextEditingController(text: _userValue('phone'));

  File? capturedImage;
  bool cameraInitializing = false;
  bool streamStarted = false;
  bool processingFrame = false;
  bool waiting = false;
  bool faceDetected = false;
  bool captureHandled = false;
  int step = 1;
  double progress = 0;
  String instruction = 'Posisikan wajah Anda di dalam lingkaran.';
  String status = 'Hidup';

  String _userValue(String key, {Object? fallback}) {
    final profile = widget.user['profile'];
    if (profile is Map && profile[key] != null) return profile[key].toString();

    final faceAuth = widget.user['faceAuth'];
    if (faceAuth is Map) {
      final identityData = faceAuth['identityData'];
      final lastIdentityData = faceAuth['lastIdentityData'];
      if (lastIdentityData is Map && lastIdentityData[key] != null) {
        return lastIdentityData[key].toString();
      }
      if (identityData is Map && identityData[key] != null) {
        return identityData[key].toString();
      }
    }

    return fallback?.toString() ?? '';
  }

  Map<String, dynamic> get _identityData => {
    'name': name.text.trim(),
    'employeeNumber': employeeNumber.text.trim(),
    'status': status,
    'address': address.text.trim(),
    'phone': phone.text.trim(),
  };

  String _faceAuthError(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is CameraException) {
      return error.description ?? 'Kamera tidak dapat digunakan.';
    }
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? 'Autentikasi wajah gagal diproses.' : message;
  }

  @override
  void initState() {
    super.initState();
    faceRepository = FaceDetectionRepositoryImpl(
      faceDetector: FlutterFaceDetection.getStreamingFaceDetector(),
    );
  }

  Future<void> _startCameraStep() async {
    if ([
      name,
      employeeNumber,
      address,
      phone,
    ].any((item) => item.text.trim().isEmpty)) {
      showMessage(context, 'Lengkapi data diri terlebih dahulu.');
      return;
    }

    setState(() {
      step = 2;
      progress = 0;
      capturedImage = null;
      faceDetected = false;
      captureHandled = false;
      cameraInitializing = true;
      instruction = 'Menyiapkan kamera depan...';
    });

    await initializeStreamingCamera(
      cameraLensDirection: CameraLensDirection.front,
      onCameraInitialized: (_) {
        if (!mounted) return;
        setState(() {
          cameraInitializing = false;
          instruction = 'Posisikan wajah Anda di dalam lingkaran.';
        });
        _startFaceStream();
      },
      onCameraInitializedFailure: (exception) {
        if (!mounted) return;
        setState(() {
          cameraInitializing = false;
          instruction = exception.message;
        });
        showMessage(context, exception.message);
      },
    );
  }

  Future<void> _startFaceStream() async {
    if (streamStarted || cameraController?.value.isInitialized != true) return;
    streamStarted = true;
    await startImageStream(onImageStream: _onImageStream);
  }

  Future<void> _stopFaceStream() async {
    if (!streamStarted) return;
    streamStarted = false;
    await stopImageStream();
  }

  Future<void> _onImageStream(
    CameraImage image,
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
    CameraLensDirection cameraLensDirection,
  ) async {
    if (processingFrame || captureHandled || waiting) return;
    processingFrame = true;

    try {
      final inputImage = FlutterFaceDetection.inputImageFromCameraImage(
        image,
        sensorOrientation: sensorOrientation,
        deviceOrientation: deviceOrientation,
        cameraLensDirection: cameraLensDirection,
      );
      if (inputImage == null) {
        _setInstruction(
          'Kamera belum siap membaca wajah. Coba posisikan ulang wajah Anda.',
        );
        return;
      }

      final faces = await faceRepository.detectFace(inputImage);
      if (!mounted || captureHandled) return;

      if (faces.length == 1) {
        setState(() {
          faceDetected = true;
          progress = 1;
          instruction = 'Wajah terdeteksi. Mengambil gambar...';
        });
        await _captureDetectedFace();
      } else if (faces.length > 1) {
        _setInstruction('Pastikan hanya satu wajah yang terlihat di kamera.');
      } else {
        _setInstruction('Posisikan wajah Anda di dalam lingkaran.');
      }
    } catch (error) {
      if (mounted)
        _setInstruction(
          'Belum dapat mendeteksi wajah. Coba dekatkan wajah ke kamera.',
        );
    } finally {
      processingFrame = false;
    }
  }

  void _setInstruction(String message) {
    if (!mounted || captureHandled || instruction == message) return;
    setState(() => instruction = message);
  }

  Future<void> _captureDetectedFace() async {
    if (captureHandled || waiting) return;
    captureHandled = true;

    try {
      await _stopFaceStream();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final image = await takePicture();
      if (image == null) {
        captureHandled = false;
        if (mounted) {
          setState(() {
            progress = 0;
            instruction =
                'Gagal mengambil gambar. Tekan Kirim untuk mencoba lagi.';
          });
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        capturedImage = image;
        progress = 1;
        instruction = 'Gambar berhasil diambil. Menyimpan...';
      });
      await _saveCapturedImage(image);
    } catch (error) {
      captureHandled = false;
      if (mounted) {
        setState(() {
          progress = 0;
          instruction =
              'Gagal mengambil gambar. Tekan Kirim untuk mencoba lagi.';
        });
        showMessage(context, _faceAuthError(error));
      }
    }
  }

  Future<List<double>?> _referenceEmbedding(Object? userId, File localReference) async {
    final localEmbedding =
        await LocalFaceAuthService.instance.referenceEmbedding(userId);
    if (localEmbedding != null && localEmbedding.isNotEmpty) {
      return localEmbedding;
    }

    return FaceEmbeddingService.instance.embeddingFromFile(localReference);
  }

  Future<void> _saveCapturedImage(File image) async {
    setState(() => waiting = true);
    try {
      final userId = widget.user['_id'];
      final candidateEmbedding =
          await FaceEmbeddingService.instance.embeddingFromFile(image);
      final localReference =
          await LocalFaceAuthService.instance.referenceImage(userId);
      final hasLocalReference = localReference != null;

      if (hasLocalReference) {
        final referenceEmbedding =
            await _referenceEmbedding(userId, localReference);
        if (referenceEmbedding == null || referenceEmbedding.isEmpty) {
          throw StateError(
            'Foto acuan biometrik belum ditemukan. Silakan lakukan autentikasi awal ulang.',
          );
        }

        final match = FaceEmbeddingService.instance.compare(
          referenceEmbedding,
          candidateEmbedding,
        );
        if (!match.matched) {
          throw StateError(
            'Wajah tidak cocok dengan foto acuan. Jarak: ${match.distance.toStringAsFixed(3)} / batas ${match.threshold.toStringAsFixed(2)}.',
          );
        }

        if (!mounted) return;
        await successDialog(
          context,
          'Autentikasi Berhasil',
          'Wajah cocok. Status autentikasi sesi ini berhasil diperbarui.',
        );
        if (mounted) Navigator.pop(context, widget.user);
        return;
      }

      await LocalFaceAuthService.instance.saveReferenceImage(
        userId: userId,
        image: image,
        identityData: _identityData,
        embedding: candidateEmbedding,
      );
      if (!mounted) return;
      await successDialog(
        context,
        'Foto Acuan Disimpan',
        'Foto dan data biometrik wajah awal berhasil disimpan di perangkat ini. Autentikasi berikutnya akan dibandingkan secara lokal.',
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      captureHandled = false;
      if (mounted) {
        setState(() {
          capturedImage = null;
          progress = 0;
          instruction = 'Posisikan wajah Anda di dalam lingkaran.';
        });
        showMessage(context, _faceAuthError(error));
        await _startFaceStream();
      }
    } finally {
      if (mounted) setState(() => waiting = false);
    }
  }

  Future<void> _manualCapture() async {
    if (captureHandled || waiting) return;
    if (cameraController?.value.isInitialized != true) {
      showMessage(context, 'Kamera belum siap.');
      return;
    }

    captureHandled = true;
    setState(() {
      progress = 1;
      instruction = 'Mengambil gambar dari kamera...';
    });

    try {
      await _stopFaceStream();
      final image = await takePicture();
      if (image == null) {
        throw Exception('Gagal mengambil gambar dari kamera.');
      }

      if (!mounted) return;
      setState(() {
        capturedImage = image;
        progress = 1;
        instruction = 'Gambar berhasil diambil. Menyimpan...';
      });
      await _saveCapturedImage(image);
    } catch (error) {
      captureHandled = false;
      if (mounted) {
        setState(() {
          progress = 0;
          instruction =
              'Gagal mengambil gambar. Tekan Kirim untuk mencoba lagi.';
        });
        showMessage(context, _faceAuthError(error));
        await _startFaceStream();
      }
    }
  }

  @override
  void dispose() {
    for (final item in [name, employeeNumber, address, phone]) {
      item.dispose();
    }
    _stopFaceStream();
    disposeCamera();
    faceRepository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 38),
        child: Column(
          children: [
            _TopBar(canBack: !widget.verificationOnly),
            Expanded(
              child: step == 1
                  ? _IdentityStep(
                      name: name,
                      employeeNumber: employeeNumber,
                      status: status,
                      address: address,
                      phone: phone,
                      onStatusChanged: (value) =>
                          setState(() => status = value),
                      onSubmit: _startCameraStep,
                      waiting: waiting,
                    )
                  : _CameraStep(
                      controller: cameraController,
                      capturedImage: capturedImage,
                      instruction: instruction,
                      progress: progress,
                      verificationOnly: widget.verificationOnly,
                      waiting: waiting,
                      cameraInitializing: cameraInitializing,
                      onManualCapture: _manualCapture,
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.canBack});

  final bool canBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 30,
            height: 30,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: canBack ? alpenBlue : const Color(0xFFB7C6E3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: canBack ? () => Navigator.maybePop(context) : null,
              ),
            ),
          ),
        ),
        const Text(
          'Autentikasi',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({
    required this.name,
    required this.employeeNumber,
    required this.status,
    required this.address,
    required this.phone,
    required this.onStatusChanged,
    required this.onSubmit,
    required this.waiting,
  });

  final TextEditingController name;
  final TextEditingController employeeNumber;
  final String status;
  final TextEditingController address;
  final TextEditingController phone;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onSubmit;
  final bool waiting;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 36),
        const Center(child: _StepIndicator(active: 1)),
        const SizedBox(height: 34),
        const Text(
          'Sebelum memulai autentikasi, silahkan isi data diri',
          style: TextStyle(color: Color(0xFF777777), fontSize: 14),
        ),
        const SizedBox(height: 22),
        AppField(
          label: 'Nama Lengkap',
          controller: name,
          hint: 'Masukkan Nama Lengkap Anda',
        ),
        AppField(
          label: 'Nomor Induk Pegawai',
          controller: employeeNumber,
          hint: 'Masukkan Nomor Induk Pegawai Anda',
          keyboard: TextInputType.number,
        ),
        _StatusChoice(value: status, onChanged: onStatusChanged),
        AppField(
          label: 'Alamat Lengkap',
          controller: address,
          hint: 'Masukkan Alamat Lengkap Anda',
        ),
        AppField(
          label: 'Nomor Handphone',
          controller: phone,
          hint: 'Masukkan Nomor Handphone Anda',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 60),
        PrimaryButton(label: 'Kirim', waiting: waiting, onTap: onSubmit),
      ],
    ),
  );
}

class _CameraStep extends StatelessWidget {
  const _CameraStep({
    required this.controller,
    required this.capturedImage,
    required this.instruction,
    required this.progress,
    required this.verificationOnly,
    required this.waiting,
    required this.cameraInitializing,
    required this.onManualCapture,
  });

  final CameraController? controller;
  final File? capturedImage;
  final String instruction;
  final double progress;
  final bool verificationOnly;
  final bool waiting;
  final bool cameraInitializing;
  final VoidCallback onManualCapture;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 30),
      const _StepIndicator(active: 2),
      const SizedBox(height: 26),
      _FaceCameraFrame(
        controller: controller,
        capturedImage: capturedImage,
        cameraInitializing: cameraInitializing,
      ),
      const SizedBox(height: 22),
      _ProgressBar(value: progress),
      const SizedBox(height: 26),
      Text(
        instruction,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF282828),
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Jika belum ada foto acuan, foto ini akan disimpan lokal. Jika sudah ada, wajah akan dibandingkan secara lokal.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF777777),
          fontSize: 13,
          height: 1.4,
        ),
      ),
      const Spacer(),
      PrimaryButton(label: 'Kirim', waiting: waiting, onTap: onManualCapture),
    ],
  );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _StepDot(number: 1, active: active == 1),
      Container(
        width: 42,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF777777), width: 1),
          ),
        ),
      ),
      _StepDot(number: 2, active: active == 2),
    ],
  );
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.active});

  final int number;
  final bool active;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 20,
    backgroundColor: active ? alpenBlue : const Color(0xFFE9EAEC),
    child: Text(
      '$number',
      style: TextStyle(color: active ? Colors.white : const Color(0xFF667085)),
    ),
  );
}

class _StatusChoice extends StatelessWidget {
  const _StatusChoice({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF282828),
            fontSize: 16,
          ),
        ),
        Container(
          width: 38,
          height: 2,
          margin: const EdgeInsets.only(top: 5, bottom: 6),
          color: alpenBlue,
        ),
        Row(
          children: ['Hidup', 'Meninggal']
              .map(
                (item) => SizedBox(
                  width: 120,
                  child: RadioListTile<String>(
                    value: item,
                    groupValue: value,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: alpenBlue,
                    title: Text(item, style: const TextStyle(fontSize: 14)),
                    onChanged: (choice) {
                      if (choice != null) onChanged(choice);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _FaceCameraFrame extends StatelessWidget {
  const _FaceCameraFrame({
    required this.controller,
    required this.capturedImage,
    required this.cameraInitializing,
  });

  final CameraController? controller;
  final File? capturedImage;
  final bool cameraInitializing;

  @override
  Widget build(BuildContext context) {
    final ready = controller?.value.isInitialized == true;

    return Container(
      width: 230,
      height: 230,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.redAccent, width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: capturedImage != null
            ? Image.file(capturedImage!, fit: BoxFit.cover)
            : ready
            ? _CameraPreviewCover(controller: controller!)
            : ColoredBox(
                color: const Color(0xFFF2F4F7),
                child: Center(
                  child: cameraInitializing
                      ? const CircularProgressIndicator(color: alpenBlue)
                      : const Icon(
                          Icons.person,
                          color: Color(0xFF98A2B3),
                          size: 92,
                        ),
                ),
              ),
      ),
    );
  }
}

class _CameraPreviewCover extends StatelessWidget {
  const _CameraPreviewCover({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: SizedBox(
      width: 220,
      height: 18,
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: const Color(0xFFE7E7E7),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
      ),
    ),
  );
}
