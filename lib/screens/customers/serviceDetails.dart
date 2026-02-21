import 'package:flutter/material.dart';
import 'package:saidia_app/screens/customers/bookingPage.dart';
import 'package:saidia_app/screens/customers/chatPage.dart';
import 'package:saidia_app/services/firestore_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';

class ServiceDetailPage extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic> data;

  const ServiceDetailPage({
    super.key,
    required this.providerId,
    required this.data,
  });

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final FirestoreService _service = FirestoreService();
  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final saved = await _service.isServiceSaved(widget.providerId);
    if (mounted) {
      setState(() => _isSaved = saved);
    }
  }

  Future<void> _toggleSaved() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (_isSaved) {
        await _service.unsaveService(widget.providerId);
      } else {
        await _service.saveService(
          providerId: widget.providerId,
          providerData: widget.data,
        );
      }

      if (mounted) {
        setState(() => _isSaved = !_isSaved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSaved ? 'Service saved' : 'Service removed from saved',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String category = widget.data['serviceCategory'] ?? 'Service';
    final List<String> businessImages =
        (widget.data['businessImages'] as List<dynamic>?)?.cast<String>() ?? [];
    final String profileImage = widget.data['imageUrl'] ?? '';
    final String phone = widget.data['phonenumber'] ?? 'Not provided';
    final double rating = (widget.data['rating'] as num?)?.toDouble() ?? 4.8;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
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
                      child: const Icon(
                        Icons.handyman,
                        size: 100,
                        color: Colors.blue,
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bookmark,
                    color: _isSaved
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                  ),
                ),
                onPressed: _toggleSaved,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                ? const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.data['specialization'] ??
                                      'Service Provider',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                                    const SizedBox(width: 8),
                                    Text(
                                      '$rating (${widget.data['reviewCount'] ?? 0} reviews)',
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
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            const SizedBox(height: 4),
                            Text(
                              'UGX ${widget.data['hourlyRate'] ?? 'N/A'}/hr',
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
                                builder: (_) => BookingPage(
                                  providerId: widget.providerId,
                                  providerName: widget.data['specialization']
                                      ?.toString(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today, size: 20),
                          label: const Text('Book Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'About Service',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.data['description'] ?? 'No description provided.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                    children: [
                      _buildDetailItem(
                        icon: Icons.timeline,
                        label: 'Experience',
                        value: '${widget.data['experience'] ?? 'N/A'} years',
                      ),
                      _buildDetailItem(
                        icon: Icons.location_city,
                        label: 'City',
                        value: widget.data['city'] ?? 'N/A',
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
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  providerId: widget.providerId,
                                  providerName: widget.data['specialization']
                                      ?.toString(),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Chat Now'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchPhone(phone),
                          icon: const Icon(Icons.call),
                          label: const Text('Call Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
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
