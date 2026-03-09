import 'package:flutter/material.dart';

import '../../../common/util/custom_enum/custom_state_type_enum.dart';
import 'widget/custom_dropdown.dart';
import 'widget/post_bloc_visualizer.dart';
import 'widget/post_riverpod_visualizer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ValueNotifier<CustomStateTypeEnum> _stateTypeNotifier;

  @override
  void initState() {
    _stateTypeNotifier = ValueNotifier(CustomStateTypeEnum.flutterRiverPod);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _stateTypeNotifier,
      builder: (stateContext, stateValue, stateChild) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Posts ${stateValue.name} orqali'),
            centerTitle: true,
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                child: CustomDropdown(
                  selectedValue: stateValue,
                  onChanged: (value) {
                    if (value != null) {
                      _stateTypeNotifier.value = value;
                    }
                  },
                ),
              ),
              Expanded(
                child: switch (stateValue) {
                  CustomStateTypeEnum.flutterRiverPod =>
                    PostRiverpodVisualizer(),
                  CustomStateTypeEnum.flutterBloc => PostBlocVisualizer(),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
