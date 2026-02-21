import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class PaymentsHistoryPage extends StatelessWidget {
  PaymentsHistoryPage({super.key});

  final FirestoreService _service = FirestoreService();

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getPaymentsHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load payments: ${snapshot.error}'),
            );
          }

          final docs = [...(snapshot.data?.docs ?? [])];
          docs.sort((a, b) {
            final aTs = a.data()['createdAt'] as Timestamp?;
            final bTs = b.data()['createdAt'] as Timestamp?;
            final aMs = aTs?.millisecondsSinceEpoch ?? 0;
            final bMs = bTs?.millisecondsSinceEpoch ?? 0;
            return bMs.compareTo(aMs);
          });
          if (docs.isEmpty) {
            return const Center(child: Text('No payments yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final amount = (data['amount'] as num?)?.toDouble() ?? 0;
              final currency = (data['currency'] as String?) ?? 'UGX';
              final type = (data['type'] as String?) ?? 'payment';
              final status = (data['status'] as String?) ?? 'pending';
              final method = (data['method'] as String?) ?? 'unknown';
              final createdAt = data['createdAt'] as Timestamp?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(status).withOpacity(0.12),
                  child: Icon(Icons.payments, color: _statusColor(status)),
                ),
                title: Text(
                  '$currency ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${type.replaceAll('_', ' ')} via $method\n${createdAt == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())}',
                ),
                trailing: Container(
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
