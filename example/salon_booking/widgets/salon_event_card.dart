import 'package:flutter/widgets.dart';
import 'package:timetide/timetide.dart';

/// Custom event card for salon appointments.
///
/// Displays the service name, customer, duration, and price in a compact tile.
class SalonEventCard extends StatelessWidget {
  const SalonEventCard({
    super.key,
    required this.event,
  });

  final TideEvent event;

  @override
  Widget build(BuildContext context) {
    final customer = event.metadata?['customer'] as String? ?? '';
    final price = event.metadata?['price'] as double?;
    final duration = event.endTime.difference(event.startTime);
    final durationText = duration.inMinutes >= 60
        ? '${duration.inHours}h ${duration.inMinutes % 60}min'
        : '${duration.inMinutes}min';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: event.color ?? const Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.subject,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (customer.isNotEmpty)
            Text(
              customer,
              style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                durationText,
                style: const TextStyle(
                  color: Color(0x99FFFFFF),
                  fontSize: 10,
                ),
              ),
              if (price != null) ...[
                const SizedBox(width: 6),
                Text(
                  '\u20AC${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
