enum CustomStateTypeEnum {
  flutterRiverPod(name: 'Flutter Riverpod', type: 'flutter_river_pod'),
  flutterBloc(name: 'Flutter Bloc', type: 'flutter_bloc');

  const CustomStateTypeEnum({required this.name, required this.type});

  final String name;
  final String type;
}
