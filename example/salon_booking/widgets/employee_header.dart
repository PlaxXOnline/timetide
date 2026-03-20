import 'package:flutter/widgets.dart';
import 'package:timetide/src/core/models/resource.dart';
import 'package:timetide/src/widgets/resource_header/resource_load_indicator.dart';

/// Custom resource header for salon employees.
///
/// Shows the employee's avatar (or initials), name, role, and a load indicator.
class EmployeeHeader extends StatelessWidget {
  const EmployeeHeader({
    super.key,
    required this.resource,
    this.appointmentCount = 0,
  });

  final TideResource resource;
  final int appointmentCount;

  @override
  Widget build(BuildContext context) {
    final role = resource.metadata?['role'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Avatar circle with initials
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: resource.color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(resource.displayName),
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      resource.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (role.isNotEmpty)
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF757575),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TideResourceLoadIndicator(
            mode: TideLoadDisplayMode.eventCount,
            eventCount: appointmentCount,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
