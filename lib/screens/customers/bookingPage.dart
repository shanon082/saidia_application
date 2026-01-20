import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class BookingPage extends StatefulWidget {
  final String providerId;
  final String? providerName;

  const BookingPage({super.key, required this.providerId, this.providerName});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;
  String? _selectedServiceType = 'One-time Service';
  final List<String> _serviceTypes = [
    'One-time Service',
    'Weekly Service',
    'Monthly Maintenance',
    'Emergency Service',
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      await _service.createBooking(
        providerId: widget.providerId,
        date: _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : '',
        time: _selectedTime != null
            ? _selectedTime!.format(context)
            : '',
        details: _detailsController.text.trim(),
        serviceType: _selectedServiceType ?? 'One-time Service',
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Booking Submitted'),
              ],
            ),
            content: Text('Your booking request has been sent successfully! The provider will confirm shortly.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Service'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Info Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blue.shade100,
                      child: Icon(Icons.handyman, color: Colors.blue.shade700),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.providerName ?? 'Service Provider',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Book your service appointment',
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
              ),
              SizedBox(height: 24),

              // Service Type Selection
              Text(
                'Service Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _serviceTypes.map((type) {
                  final isSelected = _selectedServiceType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedServiceType = selected ? type : null;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Colors.blue.shade700,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24),

              // Date Selection
              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue.shade700),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
                              : 'Tap to select date',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate != null
                                ? Colors.grey.shade900
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Time Selection
              Text(
                'Select Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue.shade700),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Tap to select time',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedTime != null
                                ? Colors.grey.shade900
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Duration Selection
              Text(
                'Estimated Duration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.blue.shade700),
                    SizedBox(width: 12),
                    Text(
                      '2-3 hours',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '(estimated)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Additional Details
              Text(
                'Additional Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe what you need help with...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide service details';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),

              // Summary Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildSummaryItem('Service Type', _selectedServiceType ?? 'Not selected'),
                    _buildSummaryItem('Date', _selectedDate != null
                        ? DateFormat('MMM d, yyyy').format(_selectedDate!)
                        : 'Not selected'),
                    _buildSummaryItem('Time', _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Not selected'),
                    Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Estimated Cost',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          'UGX 2,500 - 3,500',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '* Final cost may vary based on actual service requirements',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Confirm Booking',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 16),

              // Terms Note
              Text(
                'By confirming, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }
}