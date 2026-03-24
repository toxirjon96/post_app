import 'package:flutter/material.dart';

import '../../../common/util/custom_enum/custom_state_type_enum.dart';
import '../../../common/widget/app_dropdown.dart';
import '../../../common/widget/scaffold_key_scope.dart';
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
    _stateTypeNotifier =
        ValueNotifier(CustomStateTypeEnum.flutterRiverPod);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _stateTypeNotifier,
      builder: (stateContext, stateValue, _) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () =>
                  ScaffoldKeyScope.of(context).currentState?.openDrawer(),
            ),
            title: Text('Posts · ${stateValue.name}'),
            centerTitle: true,
          ),
          body: Builder(builder: (context) {
            final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
            final hPad = isTablet ? 20.0 : 16.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, isTablet ? 16 : 12, hPad, 4),
                child: AppDropdown<CustomStateTypeEnum>(
                  items: CustomStateTypeEnum.values,
                  value: stateValue,
                  hint: 'Select state manager',
                  label: 'State Manager',
                  prefixIcon: Icons.layers_outlined,
                  displayBuilder: (e) => e.name,
                  onChanged: (value) {
                    if (value != null) {
                      _stateTypeNotifier.value = value;
                    }
                  },
                  clearable: false,
                ),
              ),
              Expanded(
                child: switch (stateValue) {
                  CustomStateTypeEnum.flutterRiverPod =>
                    const PostRiverpodVisualizer(),
                  CustomStateTypeEnum.flutterBloc =>
                    const PostBlocVisualizer(),
                },
              ),
            ],
          );
        }),
      );
      },
    );
  }
}