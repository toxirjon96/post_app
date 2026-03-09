import 'package:shared_preferences/shared_preferences.dart';

import '../repository/request_repository.dart';

base class Dependencies {
  Dependencies();

  late final SharedPreferences sharedPreferences;
  late final RequestRepository requestRepository;
}

final class MutableDependencies implements Dependencies {
  MutableDependencies({
    required this.sharedPreferences,
    required this.requestRepository,
  });

  @override
  SharedPreferences sharedPreferences;

  @override
  RequestRepository requestRepository;
}
