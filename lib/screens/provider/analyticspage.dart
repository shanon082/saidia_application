import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class AnalyticsPage extends StatelessWidget {
  AnalyticsPage({super.key});

  final FirestoreService _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getProviderBookingsStream(),
        builder: (context, bookingSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.getProviderReviewsStream(),
            builder: (context, reviewSnap) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _service.getProviderPaymentsStream(),
                builder: (context, paySnap) {
                  if (bookingSnap.connectionState == ConnectionState.waiting ||
                      reviewSnap.connectionState == ConnectionState.waiting ||
                      paySnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookings = bookingSnap.data?.docs ?? [];
                  final reviews = reviewSnap.data?.docs ?? [];
                  final payments = paySnap.data?.docs ?? [];

                  final confirmed = bookings
                      .where((b) => b.data()['status'] == 'confirmed')
                      .length;
                  final pending = bookings
                      .where((b) => b.data()['status'] == 'pending')
                      .length;

                  final ratingValues = reviews
                      .map((r) => (r.data()['rating'] as num?)?.toDouble() ?? 0)
                      .where((v) => v > 0)
                      .toList();
                  final avgRating = ratingValues.isEmpty
                      ? 0.0
                      : ratingValues.reduce((a, b) => a + b) /
                            ratingValues.length;

                  final revenue = payments
                      .where((p) => p.data()['type'] == 'booking_earning')
                      .fold<double>(
                        0,
                        (total, p) =>
                            total +
                            ((p.data()['amount'] as num?)?.toDouble() ?? 0),
                      );

                  Widget metric(
                    String label,
                    String value,
                    IconData icon,
                    Color color,
                  ) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(icon, color: color),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      metric(
                        'Total Bookings',
                        '${bookings.length}',
                        Icons.book_online,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      metric(
                        'Confirmed',
                        '$confirmed',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      metric(
                        'Pending',
                        '$pending',
                        Icons.schedule,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      metric(
                        'Average Rating',
                        avgRating.toStringAsFixed(1),
                        Icons.star,
                        Colors.amber,
                      ),
                      const SizedBox(height: 12),
                      metric(
                        'Revenue',
                        'UGX ${NumberFormat('#,###').format(revenue)}',
                        Icons.payments,
                        Colors.teal,
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
