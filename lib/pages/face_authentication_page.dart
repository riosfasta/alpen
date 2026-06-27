import 'dart:convert';
import 'dart:io';

import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/app_theme.dart';
import '../core/navigation.dart';
import '../services/mongo_service.dart';
import '../services/session_service.dart';
import '../widgets/alpen_mark.dart';
import '../widgets/app_widgets.dart';
import 'user_home_page.dart';

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

class _FaceAuthenticationPageState extends State<FaceAuthenticationPage> {
  FaceCameraController? controller;
  late final name = TextEditingController(text: _userValue('name', fallback: widget.user['name']));
  late final employeeNumber = TextEditingController(text: _userValue('employeeNumber', fallback: widget.user['username']));
  late final address = TextEditingController(text: _userValue('address'));
  late final phone = TextEditingController(text: _userValue('phone'));
  File? capturedImage;
  bool waiting = false;
  bool faceDetected = false;
  bool captureHandled = false;
  int step = 1;
  double progress = 0;
  String instruction = 'Posisikan wajah Anda di dalam lingkaran.';
  String status = 'Hidup';

  bool get hasFaceAuth {
    final faceAuth = widget.user['faceAuth'];
    return faceAuth is Map && faceAuth['enabled'] == true;
  }

  String _userValue(String key, {Object? fallback}) {
    final profile = widget.user['profile'];
    if (profile is Map && profile[key] != null) return profile[key].toString();
    return fallback?.toString() ?? '';
  }

  Map<String, dynamic> get _identityData => {
        'name': name.text.trim(),
        'employeeNumber': employeeNumber.text.trim(),
        'status': status,
        'address': address.text.trim(),
        'phone': phone.text.trim(),
      };

  @override
  void initState() {
    super.initState();
  }

  void _startCameraStep() {
    if ([name, employeeNumber, address, phone].any((item) => item.text.trim().isEmpty)) {
      showMessage(context, 'Lengkapi data diri terlebih dahulu.');
      return;
    }
    controller = FaceCameraController(
      autoCapture: true,
      ignoreFacePositioning: true,
      enableAudio: false,
      imageResolution: ImageResolution.medium,
      defaultCameraLens: CameraLens.front,
      performanceMode: FaceDetectorMode.fast,
      onFaceDetected: (face) {
        if (!mounted || faceDetected || captureHandled) return;
        setState(() {
          faceDetected = true;
          progress = 1;
          instruction = 'Wajah terdeteksi. Mengambil gambar...';
        });
      },
      onCapture: (image) {
        if (image == null || captureHandled) return;
        captureHandled = true;
        if (mounted) {
          setState(() {
            capturedImage = image;
            progress = 1;
            instruction = 'Gambar berhasil diambil. Menyimpan...';
          });
        }
        _saveCapturedImage(image);
      },
    );
    setState(() => step = 2);
  }

  Future<Map<String, dynamic>> _imageMetadata(File image) async {
    final bytes = await image.readAsBytes();
    final extension = image.path.split('.').last.toLowerCase();
    return {
      'name': image.path.split(Platform.pathSeparator).last,
      'path': image.path,
      'size': bytes.length,
      'extension': extension,
      'mimeType': extension == 'png' ? 'image/png' : 'image/jpeg',
      'contentBase64': base64Encode(bytes),
      'capturedAt': DateTime.now().toUtc(),
    };
  }

  Future<void> _saveCapturedImage(File image) async {
    setState(() => waiting = true);
    try {
      final imageData = await _imageMetadata(image);
      final userId = widget.user['_id'] as ObjectId;

      if (widget.verificationOnly || hasFaceAuth) {
        await MongoService.instance.recordFaceVerification(
          id: userId,
          identityData: _identityData,
          verificationImage: imageData,
        );
        final updatedUser = await MongoService.instance.findUserById(userId) ?? widget.user;
        await SessionService.saveUser(updatedUser);
        if (!mounted) return;
        if (widget.verificationOnly) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => UserHomePage(user: updatedUser)),
            (_) => false,
          );
        } else {
          Navigator.pop(context, updatedUser);
        }
        return;
      }

      await MongoService.instance.saveFaceAuthentication(
        id: userId,
        identityData: _identityData,
        referenceImage: imageData,
      );
      final updatedUser = await MongoService.instance.findUserById(userId) ?? widget.user;
      if (!mounted) return;
      await successDialog(
        context,
        'Autentikasi Berhasil',
        'Foto wajah awal berhasil disimpan ke MongoDB sebagai pembanding akun.',
      );
      if (mounted) Navigator.pop(context, updatedUser);
    } catch (error) {
      captureHandled = false;
      if (mounted) showMessage(context, friendlyError(error));
    } finally {
      if (mounted) setState(() => waiting = false);
    }
  }

  Future<void> _manualCapture() async {
    if (captureHandled || waiting) return;
    setState(() {
      progress = 1;
      instruction = faceDetected ? 'Mengambil gambar...' : 'Mengambil gambar dari kamera...';
    });
    controller?.captureImage();
  }

  @override
  void dispose() {
    for (final item in [name, employeeNumber, address, phone]) {
      item.dispose();
    }
    controller?.dispose();
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
                          onStatusChanged: (value) => setState(() => status = value),
                          onSubmit: _startCameraStep,
                          waiting: waiting,
                        )
                      : _CameraStep(
                          controller: controller!,
                          capturedImage: capturedImage,
                          instruction: instruction,
                          progress: progress,
                          verificationOnly: widget.verificationOnly,
                          waiting: waiting,
                          onFaceMessage: (message) {
                            if (!mounted || faceDetected || captureHandled) return;
                            if (message.trim().isEmpty) return;
                            setState(() => instruction = message);
                          },
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
                  decoration: const BoxDecoration(color: alpenBlue, shape: BoxShape.circle),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
            AppField(label: 'Nama Lengkap', controller: name, hint: 'Masukkan Nama Lengkap Anda'),
            AppField(
              label: 'Nomor Induk Pegawai',
              controller: employeeNumber,
              hint: 'Masukkan Nomor Induk Pegawai Anda',
              keyboard: TextInputType.number,
            ),
            _StatusChoice(value: status, onChanged: onStatusChanged),
            AppField(label: 'Alamat Lengkap', controller: address, hint: 'Masukkan Alamat Lengkap Anda'),
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
    required this.onFaceMessage,
    required this.onManualCapture,
  });

  final FaceCameraController controller;
  final File? capturedImage;
  final String instruction;
  final double progress;
  final bool verificationOnly;
  final bool waiting;
  final ValueChanged<String> onFaceMessage;
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
            onFaceMessage: onFaceMessage,
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
          Text(
            verificationOnly
                ? 'Foto akan otomatis diambil setelah wajah terdeteksi. Jika belum berjalan, tekan Kirim.'
                : 'Foto wajah awal akan otomatis disimpan setelah wajah terdeteksi. Jika belum berjalan, tekan Kirim.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 13, height: 1.4),
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
              border: Border(bottom: BorderSide(color: Color(0xFF777777), width: 1)),
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
            const Text('Status', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF282828), fontSize: 16)),
            Container(width: 38, height: 2, margin: const EdgeInsets.only(top: 5, bottom: 6), color: alpenBlue),
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
    required this.onFaceMessage,
  });

  final FaceCameraController controller;
  final File? capturedImage;
  final ValueChanged<String> onFaceMessage;

  @override
  Widget build(BuildContext context) => Container(
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
              : SmartFaceCamera(
                  controller: controller,
                  showControls: false,
                  showCaptureControl: false,
                  showCameraLensControl: false,
                  showFlashControl: false,
                  autoDisableCaptureControl: true,
                  indicatorShape: IndicatorShape.none,
                  messageBuilder: (context, face) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (face == null) {
                        onFaceMessage('Posisikan wajah Anda di dalam lingkaran.');
                      } else {
                        onFaceMessage('Wajah terdeteksi. Mengambil gambar...');
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
        ),
      );
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
