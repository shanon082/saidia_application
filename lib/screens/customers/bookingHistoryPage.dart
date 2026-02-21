import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class BookingHistoryPage extends StatelessWidget {
  BookingHistoryPage({super.key});

  final FirestoreService _service = FirestoreService();

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getCustomerBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load bookings: ${snapshot.error}'),
            );
          }

          final bookings = [...(snapshot.data?.docs ?? [])];
          bookings.sort((a, b) {
            final aTs = a.data()['createdAt'] as Timestamp?;
            final bTs = b.data()['createdAt'] as Timestamp?;
            final aMs = aTs?.millisecondsSinceEpoch ?? 0;
            final bMs = bTs?.millisecondsSinceEpoch ?? 0;
            return bMs.compareTo(aMs);
          });
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings yet.'));
          }

          return ListView.separated(
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = bookings[index].data();
              final serviceType = (data['serviceType'] as String?) ?? 'Service';
              final details = (data['details'] as String?) ?? '';
              final date = (data['date'] as String?) ?? '';
              final time = (data['time'] as String?) ?? '';
              final status = (data['status'] as String?) ?? 'pending';
              final amount = (data['estimatedAmount'] as num?)?.toDouble() ?? 0;
              final createdAt = data['createdAt'] as Timestamp?;

              return ListTile(
                title: Text(
                  serviceType,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '$details\n$date $time\nCreated: ${createdAt == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())}',
                ),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('UGX ${amount.toStringAsFixed(0)}'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
