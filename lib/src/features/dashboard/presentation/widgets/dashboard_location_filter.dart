import 'package:flutter/material.dart';
import 'package:ntk_project/src/features/users/data/models/user_location_assignment.dart';

class DashboardLocationFilter extends StatelessWidget {
  final List<UserLocationAssignment> assignments;
  final int? selectedLocationId;
  final ValueChanged<int?> onLocationChanged;

  final bool isDarkTheme;

  const DashboardLocationFilter({
    Key? key,
    required this.assignments,
    required this.selectedLocationId,
    required this.onLocationChanged,
    this.isDarkTheme = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          dropdownColor: isDarkTheme ? const Color(0xFF004D2A) : Colors.white,
          value: selectedLocationId,
          iconEnabledColor: isDarkTheme ? Colors.white : Colors.black,
          items: { for (var a in assignments) if (a.location != null) a.location!.id: a.location! }.values.map((loc) {
            return DropdownMenuItem<int?>(
              value: loc.id,
              child: Text(
                "${loc.name} (${loc.type})",
                style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black87),
              ),
            );
          }).toList(),
          onChanged: onLocationChanged,
        ),
      ),
    );
  }
}
