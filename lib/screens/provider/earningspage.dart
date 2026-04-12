import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class EarningsPage extends StatelessWidget {
  EarningsPage({super.key});

  final FirestoreService _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Wallet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _service.getWalletStream(),
            builder: (context, snapshot) {
              final balance =
                  (snapshot.data?.data()?['balance'] as num?)?.toDouble() ??
                  0.0;
              final currency =
                  snapshot.data?.data()?['currency']?.toString() ?? 'UGX';
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.teal.shade400],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Provider Wallet',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$currency ${NumberFormat('#,###').format(balance)}',
                      style: const TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getProviderPaymentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load earnings: ${snapshot.error}'),
                  );
                }

                final docs = [...(snapshot.data?.docs ?? [])];
                docs.sort((a, b) {
                  final aTs = a.data()['createdAt'] as Timestamp?;
                  final bTs = b.data()['createdAt'] as Timestamp?;
                  return (bTs?.millisecondsSinceEpoch ?? 0).compareTo(
                    aTs?.millisecondsSinceEpoch ?? 0,
                  );
                });

                final earnings = docs
                    .where((d) => d.data()['type'] == 'booking_earning')
                    .toList();

                if (earnings.isEmpty) {
                  return const Center(child: Text('No earnings yet'));
                }

                return ListView.separated(
                  itemCount: earnings.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = earnings[index].data();
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                    final currency = data['currency']?.toString() ?? 'UGX';
                    final bookingId = data['bookingId']?.toString() ?? '-';
                    final date = (data['createdAt'] as Timestamp?)?.toDate();
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.green.shade700,
                        ),
                      ),
                      title: Text(
                        '$currency ${NumberFormat('#,###').format(amount)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Booking: $bookingId\n${date == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(date)}',
                      ),
                      isThreeLine: true,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
