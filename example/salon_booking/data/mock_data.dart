import 'dart:ui';

import 'package:timetide/timetide.dart';

/// Sample employees for the salon.
final List<TideResource> salonEmployees = [
  const TideResource(
    id: 'emp-lisa',
    displayName: 'Lisa M.',
    color: Color(0xFFE91E63),
    sortOrder: 0,
    metadata: {'role': 'Senior Stylist'},
  ),
  const TideResource(
    id: 'emp-max',
    displayName: 'Max K.',
    color: Color(0xFF2196F3),
    sortOrder: 1,
    metadata: {'role': 'Colorist'},
  ),
  const TideResource(
    id: 'emp-sarah',
    displayName: 'Sarah B.',
    color: Color(0xFF4CAF50),
    sortOrder: 2,
    metadata: {'role': 'Junior Stylist'},
  ),
];

/// Sample appointments for today.
List<TideEvent> buildSalonAppointments() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return [
    // Lisa's appointments
    TideEvent(
      id: 'apt-1',
      subject: 'Haircut & Blowdry',
      startTime: today.add(const Duration(hours: 9)),
      endTime: today.add(const Duration(hours: 9, minutes: 45)),
      color: const Color(0xFFE91E63),
      resourceIds: ['emp-lisa'],
      metadata: {
        'customer': 'Anna Weber',
        'service': 'Haircut & Blowdry',
        'price': 65.0,
      },
    ),
    TideEvent(
      id: 'apt-2',
      subject: 'Full Color',
      startTime: today.add(const Duration(hours: 10)),
      endTime: today.add(const Duration(hours: 12)),
      color: const Color(0xFFE91E63),
      resourceIds: ['emp-lisa'],
      metadata: {
        'customer': 'Maria Schmidt',
        'service': 'Full Color Treatment',
        'price': 120.0,
      },
    ),
    TideEvent(
      id: 'apt-3',
      subject: 'Balayage',
      startTime: today.add(const Duration(hours: 13)),
      endTime: today.add(const Duration(hours: 15, minutes: 30)),
      color: const Color(0xFFE91E63),
      resourceIds: ['emp-lisa'],
      metadata: {
        'customer': 'Sophie Müller',
        'service': 'Balayage',
        'price': 180.0,
      },
    ),

    // Max's appointments
    TideEvent(
      id: 'apt-4',
      subject: 'Highlights',
      startTime: today.add(const Duration(hours: 8, minutes: 30)),
      endTime: today.add(const Duration(hours: 10, minutes: 30)),
      color: const Color(0xFF2196F3),
      resourceIds: ['emp-max'],
      metadata: {
        'customer': 'Julia Fischer',
        'service': 'Highlights',
        'price': 95.0,
      },
    ),
    TideEvent(
      id: 'apt-5',
      subject: 'Color Correction',
      startTime: today.add(const Duration(hours: 11)),
      endTime: today.add(const Duration(hours: 14)),
      color: const Color(0xFF2196F3),
      resourceIds: ['emp-max'],
      metadata: {
        'customer': 'Lena Wagner',
        'service': 'Color Correction',
        'price': 220.0,
      },
    ),

    // Sarah's appointments
    TideEvent(
      id: 'apt-6',
      subject: 'Men\'s Cut',
      startTime: today.add(const Duration(hours: 9, minutes: 30)),
      endTime: today.add(const Duration(hours: 10)),
      color: const Color(0xFF4CAF50),
      resourceIds: ['emp-sarah'],
      metadata: {
        'customer': 'Tom Braun',
        'service': 'Men\'s Haircut',
        'price': 35.0,
      },
    ),
    TideEvent(
      id: 'apt-7',
      subject: 'Wash & Style',
      startTime: today.add(const Duration(hours: 10, minutes: 30)),
      endTime: today.add(const Duration(hours: 11, minutes: 15)),
      color: const Color(0xFF4CAF50),
      resourceIds: ['emp-sarah'],
      metadata: {
        'customer': 'Petra Hoffmann',
        'service': 'Wash & Style',
        'price': 45.0,
      },
    ),
    TideEvent(
      id: 'apt-8',
      subject: 'Kids Haircut',
      startTime: today.add(const Duration(hours: 14)),
      endTime: today.add(const Duration(hours: 14, minutes: 30)),
      color: const Color(0xFF4CAF50),
      resourceIds: ['emp-sarah'],
      metadata: {
        'customer': 'Emma Klein',
        'service': 'Kids Haircut',
        'price': 25.0,
      },
    ),
  ];
}

/// Available salon services for drag-in booking.
class SalonService {
  const SalonService({
    required this.name,
    required this.duration,
    required this.price,
    required this.color,
  });

  final String name;
  final Duration duration;
  final double price;
  final Color color;
}

const List<SalonService> salonServices = [
  SalonService(
    name: 'Haircut',
    duration: Duration(minutes: 30),
    price: 35.0,
    color: Color(0xFF795548),
  ),
  SalonService(
    name: 'Haircut & Blowdry',
    duration: Duration(minutes: 45),
    price: 65.0,
    color: Color(0xFFFF9800),
  ),
  SalonService(
    name: 'Full Color',
    duration: Duration(minutes: 120),
    price: 120.0,
    color: Color(0xFF9C27B0),
  ),
  SalonService(
    name: 'Highlights',
    duration: Duration(minutes: 90),
    price: 95.0,
    color: Color(0xFFFFEB3B),
  ),
  SalonService(
    name: 'Balayage',
    duration: Duration(minutes: 150),
    price: 180.0,
    color: Color(0xFFE91E63),
  ),
  SalonService(
    name: 'Wash & Style',
    duration: Duration(minutes: 45),
    price: 45.0,
    color: Color(0xFF00BCD4),
  ),
];
