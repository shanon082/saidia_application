import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class WalletPage extends StatelessWidget {
  WalletPage({super.key});

  final FirestoreService _service = FirestoreService();

  Future<void> _showTopUpDialog(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Top Up Wallet'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount (UGX)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text.trim()) ?? 0;
                if (amount <= 0) return;
                Navigator.pop(context);

                try {
                  await _service.topUpWallet(amount: amount);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wallet topped up successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Top up failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Top Up'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _service.ensureWalletExists();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTopUpDialog(context),
        icon: const Icon(Icons.add_card),
        label: const Text('Top Up'),
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _service.getWalletStream(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final balance = (data?['balance'] as num?)?.toDouble() ?? 0;
              final currency = (data?['currency'] as String?) ?? 'UGX';

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.lightBlue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$currency ${balance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
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
              stream: _service.getWalletTransactionsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load transactions: ${snapshot.error}',
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No wallet transactions yet.'),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                    final currency = (data['currency'] as String?) ?? 'UGX';
                    final type = (data['type'] as String?) ?? 'credit';
                    final desc = (data['description'] as String?) ?? '';
                    final createdAt = data['createdAt'] as Timestamp?;

                    final isCredit = type == 'credit';
                    final sign = isCredit ? '+' : '-';
                    final color = isCredit ? Colors.green : Colors.red;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: color,
                        ),
                      ),
                      title: Text(
                        '$sign$currency ${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '$desc\n${createdAt == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())}',
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
