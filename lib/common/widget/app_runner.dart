import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/api_config.dart';
import '../dependency/dependencies.dart';
import '../service/request_service.dart';
import 'app.dart';

final class AppRunner {
  Future<void> initializeAndRun() async {
    WidgetsFlutterBinding.ensureInitialized();

    final sharedPreferences = await SharedPreferences.getInstance();
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/json', 'User-Agent': 'FlutterApp'},
      ),
    );

    final requestRepository = RequestServiceImpl(dio);

    final Dependencies dependencies = MutableDependencies(
      sharedPreferences: sharedPreferences,
      requestRepository: requestRepository,
    );

    App(dependencies: dependencies).run();
  }
}
