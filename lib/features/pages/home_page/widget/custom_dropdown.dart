import 'package:flutter/material.dart';

import '../../../../common/util/custom_enum/custom_state_type_enum.dart';

class CustomDropdown extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  final CustomStateTypeEnum selectedValue;
  final void Function(CustomStateTypeEnum? value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonFormField<CustomStateTypeEnum>(
          initialValue: selectedValue,
          hint: const Text(
            'State turini tanlang',
            style: TextStyle(color: Colors.grey),
          ),
          decoration: const InputDecoration(border: InputBorder.none),
          items: CustomStateTypeEnum.values.map((item) {
            return DropdownMenuItem<CustomStateTypeEnum>(
              value: item,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }
}
