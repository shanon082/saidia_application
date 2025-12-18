import 'package:flutter/material.dart';
import 'package:saidia_app/services/firestore_services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class BecomeProviderPage extends StatefulWidget {
  const BecomeProviderPage({Key? key}) : super(key: key);

  @override
  State<BecomeProviderPage> createState() => _BecomeProviderPageState();
}

class _BecomeProviderPageState extends State<BecomeProviderPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();

  String _serviceCategory = '';
  String _specialization = '';
  String _experience = '';
  String _description = '';
  String _phonenumber = '';
  String _imageUrl = '';
  String _city = '';
  String _address = '';
  String _hourlyRate = '';
  final List<String> _serviceAreas = [];
  final List<String> _workingDays = [];

  // New: Business images
  final List<File> _pickedBusinessImages = [];
  final int _maxBusinessImages = 3;

  // Placeholder for document URLs (add uploads if needed)
  String _idFront = '';
  String _idBack = '';
  String _certificate = '';

  bool _isLoading = false;

  final List<String> _categories = ['Plumbing', 'Electrical', 'Cleaning', 'Carpentry', 'Painting', 'Gardening', 'Moving', 'Repair', 'Installation', 'Other'];
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> _possibleAreas = ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret']; 

  Future<void> _pickBusinessImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && _pickedBusinessImages.length < _maxBusinessImages) {
      setState(() {
        _pickedBusinessImages.add(File(picked.path));
      });
    }
  }

  Future<List<String>> _uploadBusinessImages() async {
    List<String> urls = [];
    for (var file in _pickedBusinessImages) {
      final ref = FirebaseStorage.instance.ref().child('business_images/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_serviceAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one service area')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final businessImages = await _uploadBusinessImages();

      await _service.submitProviderApplication(
        serviceCategory: _serviceCategory,
        specialization: _specialization,
        experience: _experience,
        description: _description,
        phonenumber: _phonenumber,
        imageUrl: _imageUrl,
        city: _city,
        address: _address,
        hourlyRate: _hourlyRate,
        serviceAreas: _serviceAreas,
        workingDays: _workingDays,
        idFront: _idFront,
        idBack: _idBack,
        certificate: _certificate,
        businessImages: businessImages, // New
      );

      await _service.applyAsProvider();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted! Awaiting approval.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Service Provider'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Service Provider Application',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill in all details to apply as a service provider. Your application will be reviewed by admin.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // Service Category
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Service Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                validator: (v) => v == null ? 'Required' : null,
                onChanged: (v) => setState(() => _serviceCategory = v!),
                onSaved: (v) => _serviceCategory = v!,
              ),
              const SizedBox(height: 16),
              // Specialization
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  hintText: 'e.g., Pipe fitting, Wiring installation',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _specialization = v!,
              ),
              const SizedBox(height: 16),
              // Experience
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  hintText: 'e.g., 5',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _experience = v!,
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Service Description',
                  hintText: 'Describe your services in detail',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _description = v!,
              ),
              const SizedBox(height: 16),
              // Phone number
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _phonenumber = v!,
              ),
              const SizedBox(height: 16),
              // Profile Image URL (kept as is)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Profile Image URL',
                  hintText: 'Enter your profile image URL',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _imageUrl = v!,
              ),
              const SizedBox(height: 16),
              // New: Business Images Upload
              const Text(
                'Business Images (up to 3):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: _pickedBusinessImages.map((file) {
                  return SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.file(file, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: _pickedBusinessImages.length < _maxBusinessImages ? _pickBusinessImage : null,
                child: const Text('Add Business Image'),
              ),
              const SizedBox(height: 16),
              // City
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _city = v!,
              ),
              const SizedBox(height: 16),
              // Address
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _address = v!,
              ),
              const SizedBox(height: 16),
              // Hourly Rate
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (KES)',
                  hintText: 'e.g., 500',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                onSaved: (v) => _hourlyRate = v!,
              ),
              const SizedBox(height: 16),
              // New: Service Areas
              const Text(
                'Service Areas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: _possibleAreas.map((area) {
                  return FilterChip(
                    label: Text(area),
                    selected: _serviceAreas.contains(area),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _serviceAreas.add(area);
                        } else {
                          _serviceAreas.remove(area);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Working Days
              const Text(
                'Working Days:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: _days.map((day) {
                  return FilterChip(
                    label: Text(day),
                    selected: _workingDays.contains(day),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _workingDays.add(day);
                        } else {
                          _workingDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // ID Front (placeholder)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'ID Front URL',
                  hintText: 'Enter ID front image URL',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _idFront = v ?? '',
              ),
              const SizedBox(height: 16),
              // ID Back (placeholder)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'ID Back URL',
                  hintText: 'Enter ID back image URL',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _idBack = v ?? '',
              ),
              const SizedBox(height: 16),
              // Certificate (placeholder)
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Certificate URL',
                  hintText: 'Enter certificate image URL',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _certificate = v ?? '',
              ),
              const SizedBox(height: 24),
              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Application',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Note
              const Text(
                'Note: Your application will be reviewed within 24-48 hours. '
                'You will be notified once approved.',
                style: TextStyle(
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}