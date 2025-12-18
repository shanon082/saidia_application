import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saidia_app/screens/customers/bookingPage.dart';
import 'package:saidia_app/screens/customers/chatPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ServiceDetailPage extends StatelessWidget {
  final String providerId;
  final Map<String, dynamic> data;

  const ServiceDetailPage({super.key, required this.providerId, required this.data});

  Future<void> _launchPhone(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String category = data['serviceCategory'] ?? 'Service';
    final List<String> businessImages = (data['businessImages'] as List<dynamic>?)?.cast<String>() ?? [];
    final String profileImage = data['imageUrl'] ?? '';
    final String phone = data['phonenumber'] ?? 'Not provided';

    return Scaffold(
      appBar: AppBar(
        title: Text(data['specialization'] ?? 'Provider Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Header with Profile Image
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage.isEmpty
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['specialization'] ?? 'Service Provider',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          category,
                          style: const TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.yellow, size: 20),
                            const Text(' 4.8', style: TextStyle(color: Colors.white, fontSize: 16)),
                            const SizedBox(width: 16),
                            Text(
                              'KES ${data['hourlyRate'] ?? 'N/A'}/hr',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Business Images Carousel
            if (businessImages.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 220,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: businessImages.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),

            if (businessImages.isEmpty)
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('No business images available', style: TextStyle(fontSize: 16)),
                ),
              ),

            const SizedBox(height: 24),

            // Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(data['description'] ?? 'No description provided.', style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.timeline, 'Experience', '${data['experience'] ?? 'N/A'} years'),

                  _buildInfoRow(Icons.location_city, 'City', data['city'] ?? 'N/A'),

                  _buildInfoRow(Icons.location_on, 'Address', data['address'] ?? 'N/A'),

                  _buildInfoRow(Icons.access_time, 'Working Days', (data['workingDays'] as List?)?.join(', ') ?? 'N/A'),

                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchPhone(phone),
                    child: _buildInfoRow(Icons.phone, 'Phone', phone, color: Colors.green),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingPage(providerId: providerId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Book Service', style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(providerId: providerId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat),
                          label: const Text('Chat Now', style: TextStyle(fontSize: 18)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Related Providers Section
                  Text('Other Providers in $category', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('provider_applications')
                        .where('status', isEqualTo: 'approved')
                        .where('serviceCategory', isEqualTo: category)
                        .limit(5)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('No other providers in this category');
                      }

                      final related = snapshot.data!.docs.where((doc) => doc.id != providerId).toList();

                      if (related.isEmpty) {
                        return const Text('No other providers in this category');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: related.length,
                        itemBuilder: (context, index) {
                          final relData = related[index].data() as Map<String, dynamic>;
                          final relId = related[index].id;
                          final relImages = (relData['businessImages'] as List?)?.cast<String>() ?? [];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: relImages.isNotEmpty
                                  ? Image.network(relImages[0], width: 60, height: 60, fit: BoxFit.cover)
                                  : const Icon(Icons.handyman),
                              title: Text(relData['specialization'] ?? 'Provider'),
                              subtitle: Text('KES ${relData['hourlyRate'] ?? 'N/A'}/hr'),
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceDetailPage(providerId: relId, data: relData),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: color))),
        ],
      ),
    );
  }
}