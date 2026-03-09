import 'package:flutter/material.dart';

import '../../dependency/scope/dependency_scope.dart';
import '../../repository/request_repository.dart';

extension on BuildContext {
  RequestRepository get requestRepository =>
      DependencyScope.of(this).requestRepository;
}
