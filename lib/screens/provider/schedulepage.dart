import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';
import 'package:table_calendar/table_calendar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final FirestoreService _service = FirestoreService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getProviderBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final byDay = <DateTime, List<Map<String, dynamic>>>{};

          for (final doc in docs) {
            final data = doc.data();
            final dateText = data['date']?.toString();
            DateTime parsed;
            try {
              parsed = dateText == null || dateText.isEmpty
                  ? DateTime.now()
                  : DateTime.parse(dateText);
            } catch (_) {
              parsed = DateTime.now();
            }
            final key = _dateOnly(parsed);
            byDay.putIfAbsent(key, () => []).add({
              ...data,
              'bookingId': doc.id,
            });
          }

          final selectedEvents = byDay[_dateOnly(_selectedDay)] ?? [];

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) =>
                    setState(() => _calendarFormat = format),
                onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                eventLoader: (day) => byDay[_dateOnly(day)] ?? const [],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('EEEE, dd MMM yyyy').format(_selectedDay),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: selectedEvents.isEmpty
                    ? const Center(child: Text('No bookings for selected date'))
                    : ListView.builder(
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedEvents[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(
                                Icons.calendar_today,
                                color: Colors.blue.shade700,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              event['serviceType']?.toString() ?? 'Service',
                            ),
                            subtitle: Text(
                              '${event['time'] ?? '-'} • ${event['status'] ?? 'pending'}\n${event['details'] ?? ''}',
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
