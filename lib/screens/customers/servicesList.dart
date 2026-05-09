import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import 'package:saidia_app/screens/customers/serviceDetails.dart';
import 'package:saidia_app/screens/customers/notificationpage.dart';

class ServicesListPage extends StatefulWidget {
  final String? categoryFilter;

  const ServicesListPage({super.key, this.categoryFilter});

  @override
  State<ServicesListPage> createState() => _ServicesListPageState();
}

class _ServicesListPageState extends State<ServicesListPage> {
  String _searchQuery = '';
  String _sortBy = 'rating';

  double _toDouble(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<Map<String, String>> _fetchProviderNames(
    List<Map<String, dynamic>> providers,
  ) async {
    final ids = providers
        .map((p) => p['userId']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    if (ids.isEmpty) return {};

    final rows = await Supabase.instance.client
        .from('users')
        .select('id, username')
        .inFilter('id', ids);

    final map = <String, String>{};
    for (final row in rows) {
      final id = row['id']?.toString();
      final username = row['username']?.toString().trim();
      if (id != null &&
          id.isNotEmpty &&
          username != null &&
          username.isNotEmpty) {
        map[id] = username;
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryFilter ?? 'All Services'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchFilterSection(),
          
          // Services List
          Expanded(
            child: _buildServicesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search services...',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 12),
          
          // Filter Options
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sort, size: 18, color: Colors.blue.shade700),
                          SizedBox(width: 6),
                          Text(
                            _sortBy == 'rating' ? 'Top Rated' : 'Price: Low to High',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
                        onSelected: (value) {
                          setState(() {
                            _sortBy = value;
                          });
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'rating',
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Text('Top Rated'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'price',
                            child: Row(
                              children: [
                                Icon(Icons.attach_money, color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Text('Price: Low to High'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 18, color: Colors.grey.shade700),
                    SizedBox(width: 6),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: () {
        var query = Supabase.instance.client
            .from('provider_applications')
            .select()
            .eq('status', 'approved');

        if (widget.categoryFilter != null) {
          query = query.eq('serviceCategory', widget.categoryFilter!);
        }
        return query.asStream();
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.blue.shade700,
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading services',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.handyman_outlined, size: 80, color: Colors.grey.shade400),
                SizedBox(height: 16),
                Text(
                  widget.categoryFilter != null
                      ? 'No ${widget.categoryFilter} services available'
                      : 'No services available yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                SizedBox(height: 8),
                Text(
                  'Check back later for new providers',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> providers = snapshot.data!;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          providers = providers.where((data) {
            final specialization = (data['specialization'] ?? '').toLowerCase();
            final description = (data['description'] ?? '').toLowerCase();
            final category = (data['serviceCategory'] ?? '').toLowerCase();
            final searchLower = _searchQuery.toLowerCase();
            return specialization.contains(searchLower) ||
                description.contains(searchLower) ||
                category.contains(searchLower);
          }).toList();
        }

        // Apply sorting
        providers.sort((a, b) {
          if (_sortBy == 'rating') {
            final aRating = _toDouble(a['rating']);
            final bRating = _toDouble(b['rating']);
            return bRating.compareTo(aRating);
          } else {
            final aPrice = _toDouble(a['hourlyRate']);
            final bPrice = _toDouble(b['hourlyRate']);
            return aPrice.compareTo(bPrice);
          }
        });

        return FutureBuilder<Map<String, String>>(
          future: _fetchProviderNames(providers),
          builder: (context, namesSnapshot) {
            final names = namesSnapshot.data ?? {};
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final data = providers[index];
                final providerId = data['userId']?.toString() ?? '';
                final businessImages = (data['businessImages'] as List?)?.cast<String>() ?? [];
                final profileImage = data['imageUrl'] ?? '';
                final rating = _toDouble(data['rating']);
                final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
                final providerName = names[providerId] ?? 'Service Provider';
                final specialization = data['specialization']?.toString() ?? 'General Service';
                final dataWithName = {...data, 'providerName': providerName};

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceDetailPage(
                          providerId: providerId,
                          data: dataWithName,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Service Image
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        image: businessImages.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(businessImages[0]),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: businessImages.isEmpty ? Colors.blue.shade50 : null,
                      ),
                      child: businessImages.isEmpty
                          ? Center(
                              child: Icon(
                                Icons.handyman,
                                size: 60,
                                color: Colors.blue.shade300,
                              ),
                            )
                          : null,
                    ),
                    
                    // Service Details
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Profile Image
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: profileImage.isNotEmpty
                                    ? NetworkImage(profileImage)
                                    : null,
                                backgroundColor: Colors.grey.shade200,
                                child: profileImage.isEmpty
                                    ? Icon(Icons.person, color: Colors.grey.shade600)
                                    : null,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      providerName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      '$specialization - ${data['serviceCategory'] ?? 'General Service'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          
                          // Rating and Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '($reviewCount reviews)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'UGX ${data['hourlyRate'] ?? '0'}/hr',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 8),
                          
                          // Service Description
                          Text(
                            data['description'] ?? 'No description available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          SizedBox(height: 12),
                          
                          // Additional Info
                          Wrap(
                            spacing: 8,
                            children: [
                              if (data['experience'] != null)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.timeline, size: 14, color: Colors.grey.shade600),
                                      SizedBox(width: 4),
                                      Text(
                                        '${data['experience']} years',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              if (data['city'] != null)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                                      SizedBox(width: 4),
                                      Text(
                                        data['city'],
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                    ],
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
                );
              },
            );
          },
        );
      },
    );
  }
}
