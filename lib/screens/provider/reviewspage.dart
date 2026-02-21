import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class ReviewsPage extends StatelessWidget {
  ReviewsPage({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getProviderReviewsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load reviews: ${snapshot.error}'),
            );
          }

          final docs = [...(snapshot.data?.docs ?? [])];
          docs.sort((a, b) {
            final aTs = a.data()['timestamp'] as Timestamp?;
            final bTs = b.data()['timestamp'] as Timestamp?;
            return (bTs?.millisecondsSinceEpoch ?? 0).compareTo(
              aTs?.millisecondsSinceEpoch ?? 0,
            );
          });

          final ratings = docs
              .map((d) => (d.data()['rating'] as num?)?.toDouble() ?? 0)
              .where((r) => r > 0)
              .toList();
          final total = ratings.length;
          final avg = total == 0
              ? 0.0
              : ratings.reduce((a, b) => a + b) / total;

          if (docs.isEmpty) {
            return const Center(child: Text('No reviews yet'));
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text('$total reviews'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final customerId = data['customerId']?.toString();
                    final created = (data['timestamp'] as Timestamp?)?.toDate();
                    final rating = (data['rating'] as num?)?.toDouble() ?? 0;

                    return FutureBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      future: customerId == null
                          ? null
                          : _firestore
                                .collection('users')
                                .doc(customerId)
                                .get(),
                      builder: (context, userSnap) {
                        final customerName =
                            userSnap.data?.data()?['name']?.toString() ??
                            'Customer';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber.shade100,
                            child: const Icon(Icons.person),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${data['comment'] ?? ''}\n${created == null ? '-' : DateFormat('dd MMM yyyy').format(created)}',
                          ),
                          isThreeLine: true,
                        );
                      },
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
