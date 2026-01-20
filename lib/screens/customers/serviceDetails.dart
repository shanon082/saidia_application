import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saidia_app/screens/customers/bookingPage.dart';
import 'package:saidia_app/screens/customers/chatPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';

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
    final double rating = 4.8; // You can fetch this from reviews

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: businessImages.isNotEmpty
                  ? CarouselSlider(
                      options: CarouselOptions(
                        height: 250,
                        autoPlay: true,
                        viewportFraction: 1.0,
                      ),
                      items: businessImages.map((url) {
                        return Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : Container(
                      color: Colors.blue.shade100,
                      child: Icon(Icons.handyman, size: 100, color: Colors.blue),
                    ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share, color: Colors.blue.shade700),
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bookmark_border, color: Colors.blue.shade700),
                ),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: profileImage.isNotEmpty
                                ? NetworkImage(profileImage)
                                : null,
                            child: profileImage.isEmpty
                                ? Icon(Icons.person, size: 40, color: Colors.grey)
                                : null,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['specialization'] ?? 'Service Provider',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    SmoothStarRating(
                                      rating: rating,
                                      size: 20,
                                      filledIconData: Icons.star,
                                      halfFilledIconData: Icons.star_half,
                                      defaultIconData: Icons.star_border,
                                      color: Colors.amber,
                                      borderColor: Colors.amber,
                                      starCount: 5,
                                      allowHalfRating: true,
                                      spacing: 2.0,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '$rating (128 reviews)',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Price & Action Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Starting from',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'UGX ${data['hourlyRate'] ?? 'N/A'}/hr',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingPage(providerId: providerId),
                              ),
                            );
                          },
                          icon: Icon(Icons.calendar_today, size: 20),
                          label: Text('Book Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // About Section
                  Text(
                    'About Service',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    data['description'] ?? 'No description provided.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Details Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                    children: [
                      _buildDetailItem(
                        icon: Icons.timeline,
                        label: 'Experience',
                        value: '${data['experience'] ?? 'N/A'} years',
                      ),
                      _buildDetailItem(
                        icon: Icons.location_city,
                        label: 'City',
                        value: data['city'] ?? 'N/A',
                      ),
                      _buildDetailItem(
                        icon: Icons.access_time,
                        label: 'Availability',
                        value: 'Mon - Fri',
                      ),
                      InkWell(
                        onTap: () => _launchPhone(phone),
                        child: _buildDetailItem(
                          icon: Icons.phone,
                          label: 'Contact',
                          value: phone,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(providerId: providerId),
                              ),
                            );
                          },
                          icon: Icon(Icons.chat_outlined),
                          label: Text('Chat Now'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.blue.shade700),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchPhone(phone),
                          icon: Icon(Icons.call),
                          label: Text('Call Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue.shade700, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}