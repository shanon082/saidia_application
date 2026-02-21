import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:saidia_app/screens/customers/serviceDetails.dart';
import 'package:saidia_app/services/firestore_services.dart';

class SavedServicesPage extends StatelessWidget {
  SavedServicesPage({super.key});

  final FirestoreService _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Services'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getSavedServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load saved services: ${snapshot.error}'),
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
            return const Center(child: Text('No saved services yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final providerId = (data['providerId'] as String?) ?? '';
              final providerData = Map<String, dynamic>.from(
                data['providerData'] as Map? ?? {},
              );
              final title =
                  (providerData['specialization'] as String?) ??
                  'Service Provider';
              final category =
                  (providerData['serviceCategory'] as String?) ?? 'Service';
              final rate = providerData['hourlyRate']?.toString() ?? 'N/A';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(Icons.handyman, color: Colors.blue.shade700),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('$category\nUGX $rate / hr'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _service.unsaveService(providerId),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceDetailPage(
                        providerId: providerId,
                        data: providerData,
                      ),
                    ),
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
