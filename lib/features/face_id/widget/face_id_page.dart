import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../pages/home_page/home_page.dart';
import '../bloc/face_id_bloc.dart';
import 'face_camera_view.dart';
import 'liveness_overlay.dart';

class FaceIdPage extends StatelessWidget {
  const FaceIdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FaceIdBloc(),
      child: const _FaceIdView(),
    );
  }
}

class _FaceIdView extends StatefulWidget {
  const _FaceIdView();

  @override
  State<_FaceIdView> createState() => _FaceIdViewState();
}

class _FaceIdViewState extends State<_FaceIdView> {
  final _cameraKey = GlobalKey<FaceCameraViewState>();
  bool _isCapturing = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: BlocListener<FaceIdBloc, FaceIdState>(
        listener: (context, state) {
          if (state is FaceIdDone) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, animation, _) => const HomePage(),
                transitionsBuilder: (_, animation, _, child) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              FaceCameraView(key: _cameraKey),
              LivenessOverlay(onSelfiePressed: _onSelfiePressed),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSelfiePressed() async {
    if (_isCapturing) return;
    _isCapturing = true;
    final path = await _cameraKey.currentState?.captureImage();
    if (!mounted) return;
    if (path != null) {
      context.read<FaceIdBloc>().add(FaceIdSelfieCapture(imagePath: path));
    }
    _isCapturing = false;
  }
}