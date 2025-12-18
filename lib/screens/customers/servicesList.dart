import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saidia_app/screens/customers/serviceDetails.dart';

class ServicesListPage extends StatelessWidget {
  final String? categoryFilter;

  const ServicesListPage({super.key, this.categoryFilter});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('provider_applications')
        .where('status', isEqualTo: 'approved');

    if (categoryFilter != null) {
      query = query.where('serviceCategory', isEqualTo: categoryFilter);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryFilter ?? 'All Services'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                categoryFilter != null
                    ? 'No $categoryFilter providers available yet'
                    : 'No services available',
              ),
            );
          }

          final providers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final data = providers[index].data() as Map<String, dynamic>;
              final providerId = providers[index].id;
              final businessImages = (data['businessImages'] as List?)?.cast<String>() ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: businessImages.isNotEmpty
                      ? Image.network(businessImages[0], width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.handyman, size: 50),
                  title: Text(data['specialization'] ?? 'Service Provider'),
                  subtitle: Text('${data['serviceCategory']} • KES ${data['hourlyRate']}/hr'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailPage(providerId: providerId, data: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}