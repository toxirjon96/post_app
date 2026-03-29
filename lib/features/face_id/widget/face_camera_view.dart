import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/face_id_bloc.dart';

class FaceCameraView extends StatefulWidget {
  const FaceCameraView({super.key});

  @override
  State<FaceCameraView> createState() => FaceCameraViewState();
}

class FaceCameraViewState extends State<FaceCameraView> {
  CameraController? _controller;
  CameraDescription? _camera;
  bool _isProcessing = false;
  bool _isInitialized = false;
  int _lastRotationDegrees = 0;

  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.stopImageStream().catchError((_) {});
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    final bloc = context.read<FaceIdBloc>();
    if (!status.isGranted) {
      bloc.add(const FaceIdPermissionResult(granted: false));
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      bloc.add(const FaceIdPermissionResult(granted: false));
      return;
    }

    _camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      _camera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    if (!mounted) return;

    setState(() => _isInitialized = true);
    bloc.add(const FaceIdPermissionResult(granted: true));
    await _controller!.startImageStream(_processFrame);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;
      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;
      context.read<FaceIdBloc>().add(
            FaceIdFaceUpdated(
              face: faces.isNotEmpty ? faces.first : null,
              imageSize: Size(image.width.toDouble(), image.height.toDouble()),
              imageRotationDegrees: _lastRotationDegrees,
            ),
          );
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _camera;
    final controller = _controller;
    if (camera == null || controller == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var compensation = _orientations[controller.value.deviceOrientation] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        compensation = (sensorOrientation + compensation) % 360;
      } else {
        compensation = (sensorOrientation - compensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }

    if (rotation == null) return null;
    _lastRotationDegrees = rotation.rawValue;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<String?> captureImage() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      final file = await controller.takePicture();
      return file.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_isInitialized || controller == null) {
      return const ColoredBox(color: Colors.black);
    }

    // Stop stream only when completely done (navigating away)
    return BlocListener<FaceIdBloc, FaceIdState>(
      listener: (context, state) {
        if (state is FaceIdDone) {
          controller.stopImageStream().catchError((_) {});
        }
      },
      // OrientationBuilder triggers a rebuild whenever the device rotates,
      // so the preview dimensions are always correct for the current orientation.
      child: OrientationBuilder(
        builder: (context, orientation) {
          final previewSize = controller.value.previewSize!;
          // The camera sensor delivers frames in its native landscape layout.
          // CameraPreview internally rotates them to match the device orientation.
          //
          // Portrait  → the displayed frame is taller than wide, so we swap the
          //             previewSize dimensions to describe the rotated shape.
          // Landscape → the displayed frame keeps the sensor's native landscape
          //             aspect ratio; no swap is needed.
          final isLandscape = orientation == Orientation.landscape;
          final displayW = isLandscape ? previewSize.width  : previewSize.height;
          final displayH = isLandscape ? previewSize.height : previewSize.width;

          return SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: displayW,
                height: displayH,
                child: CameraPreview(controller),
              ),
            ),
          );
        },
      ),
    );
  }
}