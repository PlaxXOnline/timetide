import 'package:flutter/widgets.dart';

import '../data/mock_data.dart';

/// A sidebar list of salon services that can be dragged onto the calendar.
///
/// Each service is displayed as a tappable card. In a full implementation,
/// these would integrate with [TideExternalDrag] for drag-into-calendar.
class ServiceDragList extends StatelessWidget {
  const ServiceDragList({
    super.key,
    this.onServiceTap,
  });

  /// Called when a service card is tapped (for non-drag booking flow).
  final void Function(SalonService service)? onServiceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(
          right: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Services',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: salonServices.length,
              separatorBuilder: (context, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final service = salonServices[index];
                return _ServiceCard(
                  service: service,
                  onTap: () => onServiceTap?.call(service),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onTap,
  });

  final SalonService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final durationText = service.duration.inMinutes >= 60
        ? '${service.duration.inHours}h ${service.duration.inMinutes % 60}min'
        : '${service.duration.inMinutes}min';

    return Semantics(
      button: true,
      label: '${service.name}, $durationText',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: service.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212121),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$durationText \u2022 \u20AC${service.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
