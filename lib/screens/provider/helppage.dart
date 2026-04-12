import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saidia_app/services/firestore_services.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I update my service rates?',
      'answer': 'Go to Settings > Service Settings > Pricing to update your hourly rates and package prices.',
      'category': 'Account'
    },
    {
      'question': 'How do I accept a booking?',
      'answer': 'Navigate to the Bookings tab, select a pending booking, and tap "Confirm" to accept it.',
      'category': 'Bookings'
    },
    {
      'question': 'How do I communicate with customers?',
      'answer': 'Use the Messages tab to chat with customers. You can also call them directly from the booking details.',
      'category': 'Communication'
    },
    {
      'question': 'How do I get paid for my services?',
      'answer': 'Payments are processed automatically after service completion. You can track earnings in the Earnings section.',
      'category': 'Payments'
    },
    {
      'question': 'How do I update my availability?',
      'answer': 'Go to Settings > Service Settings > Working Hours to set your availability schedule.',
      'category': 'Schedule'
    },
    {
      'question': 'What should I do if I need to cancel a booking?',
      'answer': 'Inform the customer immediately and cancel from the booking details. Try to reschedule if possible.',
      'category': 'Bookings'
    },
    {
      'question': 'How do I improve my ratings?',
      'answer': 'Provide excellent service, communicate clearly, arrive on time, and ask satisfied customers for reviews.',
      'category': 'Reviews'
    },
    {
      'question': 'How do I update my profile information?',
      'answer': 'Go to Settings > Account Settings > Personal Information to update your details.',
      'category': 'Account'
    },
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {
      'title': 'Email Support',
      'subtitle': 'support@saidia.com',
      'icon': Icons.email,
      'color': Colors.blue,
    },
    {
      'title': 'Phone Support',
      'subtitle': '+254 700 000 000',
      'icon': Icons.phone,
      'color': Colors.green,
    },
    {
      'title': 'Live Chat',
      'subtitle': 'Available 24/7',
      'icon': Icons.chat,
      'color': Colors.orange,
    },
    {
      'title': 'FAQs',
      'subtitle': 'Frequently asked questions',
      'icon': Icons.help,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: EdgeInsets.all(20),
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
                  Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Get answers to your questions and find support resources',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for help...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.mic, color: Colors.blue.shade700),
                    onPressed: () {
                      // Voice search
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Quick Help Options
            Text(
              'Quick Help',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: _contactOptions.map((option) => _helpOptionCard(option)).toList(),
            ),
            SizedBox(height: 24),

            // Frequently Asked Questions
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            SizedBox(height: 16),
            ..._faqs.map((faq) => _faqCard(faq)).toList(),
            SizedBox(height: 24),

            // Still Need Help?
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 60,
                    color: Colors.blue.shade700,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Still need help?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Our support team is available 24/7 to assist you with any questions or issues.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Contact support
                      },
                      icon: Icon(Icons.message),
                      label: Text('Contact Support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
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
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _helpOptionCard(Map<String, dynamic> option) {
    return GestureDetector(
      onTap: () {
        // Handle option tap
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: option['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(option['icon'], color: option['color'], size: 24),
              ),
              SizedBox(height: 12),
              Text(
                option['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                option['subtitle'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqCard(Map<String, dynamic> faq) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade900,
          ),
        ),
        subtitle: Text(
          faq['category'],
          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
        ),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.help_outline, size: 20, color: Colors.blue.shade700),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              faq['answer'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}