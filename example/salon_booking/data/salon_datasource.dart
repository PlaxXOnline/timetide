import 'package:timetide/src/core/datasource_in_memory.dart';
import 'package:timetide/src/core/models/event.dart';

import 'mock_data.dart';

/// A datasource pre-loaded with salon employees and sample appointments.
///
/// Extends [TideInMemoryDatasource] for simplicity. A real salon app would
/// use a custom [TideDatasource] backed by a database.
class SalonDatasource extends TideInMemoryDatasource {
  SalonDatasource() {
    _loadInitialData();
  }

  void _loadInitialData() {
    // Add employees as resources.
    for (final employee in salonEmployees) {
      addResource(employee);
    }

    // Add today's appointments.
    addEvents(buildSalonAppointments());
  }

  /// Books a new appointment (convenience wrapper).
  void bookAppointment({
    required String id,
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    required String employeeId,
    String? customer,
    double? price,
  }) {
    final employee = salonEmployees.firstWhere((e) => e.id == employeeId);
    addEvent(TideEvent(
      id: id,
      subject: subject,
      startTime: startTime,
      endTime: endTime,
      color: employee.color,
      resourceIds: [employeeId],
      metadata: {
        'customer': customer,
        'price': price,
      },
    ));
  }

  /// Returns today's appointments for a specific employee.
  Future<List<TideEvent>> getEmployeeAppointments(String employeeId) async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final allEvents = await getEvents(dayStart, dayEnd);
    return allEvents
        .where((e) =>
            e.resourceIds != null && e.resourceIds!.contains(employeeId))
        .toList();
  }

  /// Returns today's revenue for a specific employee.
  Future<double> getEmployeeRevenue(String employeeId) async {
    final appointments = await getEmployeeAppointments(employeeId);
    return appointments.fold<double>(
      0,
      (sum, e) => sum + ((e.metadata?['price'] as double?) ?? 0),
    );
  }
}
