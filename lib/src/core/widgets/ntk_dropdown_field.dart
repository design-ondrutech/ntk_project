import 'package:flutter/material.dart';
import 'package:ntk_project/src/core/theme/app_theme.dart';

class NTKDropdownField<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? selectedValue;
  final String hintText;
  final Function(T?) onChanged;
  final String Function(T) itemLabel;

  const NTKDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValue,
    required this.hintText,
    required this.onChanged,
    required this.itemLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.contains(selectedValue) ? selectedValue : null,
              isExpanded: true,
              hint: Text(
                hintText,
                style: TextStyle(color: NTKColors.textTertiary, fontSize: 14),
              ),
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
