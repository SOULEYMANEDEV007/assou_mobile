// 2. Widget Label + Radio Buttons
import 'package:flutter/material.dart';

class CustomRadioGroup extends StatelessWidget {
  final String label;
  final List<RadioOption> options;
  final bool? selectedValue;
  final void Function(bool?) onChanged;

  const CustomRadioGroup({
    Key? key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...options.map((option) {
              return InkWell(
                onTap: () => onChanged(option.value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: option.value,
                        groupValue: selectedValue,
                        onChanged: onChanged,
                        activeColor: const Color(0xFF4A90E2),
                      ),
                      Text(
                        option.label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        )
      ],
    );
  }
}

class RadioOption {
  final String label;
  final bool value;

  RadioOption({required this.label, required this.value});
}
