import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saidia_app/services/firestore_services.dart';

class BecomeProviderPage extends StatefulWidget {
  const BecomeProviderPage({super.key});

  @override
  State<BecomeProviderPage> createState() => _BecomeProviderPageState();
}

class _BecomeProviderPageState extends State<BecomeProviderPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _picker = ImagePicker();

  // Controllers for text fields
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phonenumberController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _licensePlateController = TextEditingController();

  String _serviceCategory = '';
  String _vehicleType = '';

  final List<String> _serviceAreas = [];
  final List<String> _workingDays = [];

  List<XFile>? _businessImages;
  final int _maxBusinessImages = 3;

  XFile? _profileImage;
  XFile? _idFrontImage;
  XFile? _idBackImage;
  XFile? _certificateImage;

  bool _isLoading = false;

  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Carpentry',
    'Painting',
    'Gardening',
    'Moving',
    'Repair',
    'Installation',
    'Transportation',
    'Other',
  ];

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  final List<String> _possibleAreas = [
    'Kampala', 'Entebbe', 'Jinja', 'Mbarara', 'Gulu', 'Mbale',
    'Kasese', 'Lira', 'Masaka', 'Soroti', 'Arua', 'Fort Portal',
  ];

  List<XFile> get _safeBusinessImages => _businessImages ??= <XFile>[];

  Future<XFile?> _pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1400,
      );
    } catch (e) {
      print('Image pick error: $e');
      return null;
    }
  }

  Future<void> _pickProfileImage() async {
    final image = await _pickImageFromGallery();
    if (image != null) setState(() => _profileImage = image);
  }

  Future<void> _pickIdFrontImage() async {
    final image = await _pickImageFromGallery();
    if (image != null) setState(() => _idFrontImage = image);
  }

  Future<void> _pickIdBackImage() async {
    final image = await _pickImageFromGallery();
    if (image != null) setState(() => _idBackImage = image);
  }

  Future<void> _pickCertificateImage() async {
    final image = await _pickImageFromGallery();
    if (image != null) setState(() => _certificateImage = image);
  }

  Future<void> _pickBusinessImage() async {
    if (_safeBusinessImages.length >= _maxBusinessImages) return;
    final image = await _pickImageFromGallery();
    if (image != null) {
      setState(() => _safeBusinessImages.add(image));
    }
  }

  Future<String> _uploadSingleImage({
    required XFile file,
    required String folder,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '$folder/$fileName';
      final bytes = await file.readAsBytes();

      await Supabase.instance.client.storage
          .from('provider_documents')
          .uploadBinary(path, bytes);

      return Supabase.instance.client.storage
          .from('provider_documents')
          .getPublicUrl(path);
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  Future<List<String>> _uploadBusinessImages() async {
    final urls = <String>[];
    for (final file in _safeBusinessImages) {
      final url = await _uploadSingleImage(file: file, folder: 'provider_documents/business_images');
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_serviceAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service area.')),
      );
      return;
    }

    if (_workingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one working day.')),
      );
      return;
    }

    if (_profileImage == null || _idFrontImage == null || _idBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image, ID front, and ID back are required.')),
      );
      return;
    }

    if (_serviceCategory == 'Transportation' &&
        (_vehicleType.isEmpty || _licensePlateController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle type and license plate are required for transport services.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileImageUrl = await _uploadSingleImage(
        file: _profileImage!,
        folder: 'provider_documents/profile_images',
      );

      final idFrontUrl = await _uploadSingleImage(
        file: _idFrontImage!,
        folder: 'provider_documents/id_front',
      );

      final idBackUrl = await _uploadSingleImage(
        file: _idBackImage!,
        folder: 'provider_documents/id_back',
      );

      String certificateUrl = '';
      if (_certificateImage != null) {
        certificateUrl = await _uploadSingleImage(
          file: _certificateImage!,
          folder: 'provider_documents/certificates',
        );
      }

      final businessImages = await _uploadBusinessImages();

      await _service.submitProviderApplication(
        serviceCategory: _serviceCategory,
        specialization: _specializationController.text.trim(),
        experience: _experienceController.text.trim(),
        description: _descriptionController.text.trim(),
        phonenumber: _phonenumberController.text.trim(),
        imageUrl: profileImageUrl,
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        hourlyRate: _hourlyRateController.text.trim(),
        serviceAreas: List.from(_serviceAreas),
        workingDays: List.from(_workingDays),
        idFront: idFrontUrl,
        idBack: idBackUrl,
        certificate: certificateUrl,
        businessImages: businessImages,
        vehicleType: _vehicleType,
        licensePlate: _licensePlateController.text.trim(),
      );

      await _service.applyAsProvider();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully. Awaiting admin approval.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== UI Widgets ====================

  Widget _buildTransportSection() {
    return _sectionCard(
      title: 'Transport Details (Drivers & Boda Boda)',
      subtitle: 'Required for Transportation category',
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Vehicle Type',
            border: OutlineInputBorder(),
          ),
          items: ['Car', 'Boda Boda', 'Motorcycle', 'Truck']
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          onChanged: (v) => setState(() => _vehicleType = v ?? ''),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _licensePlateController,
          decoration: const InputDecoration(
            labelText: 'License Plate Number',
            hintText: 'e.g. UAB 123X',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _imageTile({
    required String label,
    required XFile? file,
    required VoidCallback onPick,
    bool optional = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  optional ? '$label (Optional)' : label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.image_outlined),
                label: Text(file == null ? 'Upload' : 'Change'),
              ),
            ],
          ),
          if (file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FutureBuilder<Uint8List>(
                future: file.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 140,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasData) {
                    return Image.memory(
                      snapshot.data!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(
                    height: 140,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('Failed to load image'),
                  );
                },
              ),
            )
          else
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'No file selected',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTransport = _serviceCategory == 'Transportation';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(title: const Text('Become a Provider'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start Earning With Your Skills',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete your profile and upload documents. Approval usually takes 24-48 hours.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Service Information
            _sectionCard(
              title: 'Service Information',
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Service Category', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onChanged: (v) => setState(() => _serviceCategory = v ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _specializationController,
                  decoration: const InputDecoration(labelText: 'Specialization', hintText: 'e.g. Pipe installation', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(labelText: 'Years of Experience', hintText: 'e.g. 5', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Service Description', border: OutlineInputBorder()),
                  minLines: 3,
                  maxLines: 5,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),

            if (isTransport) _buildTransportSection(),

            // Contact & Pricing
            _sectionCard(
              title: 'Contact & Pricing',
              children: [
                TextFormField(
                  controller: _phonenumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Full Address', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hourlyRateController,
                  decoration: InputDecoration(
                    labelText: isTransport ? 'Rate per KM (UGX)' : 'Hourly Rate (UGX)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),

            // Coverage & Availability
            _sectionCard(
              title: 'Coverage & Availability',
              children: [
                const Text('Service Areas', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _possibleAreas.map((area) {
                    final selected = _serviceAreas.contains(area);
                    return FilterChip(
                      label: Text(area),
                      selected: selected,
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
                const Text('Working Days', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _days.map((day) {
                    final selected = _workingDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: selected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) _workingDays.add(day);
                          else _workingDays.remove(day);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),

            // Upload Images
            _sectionCard(
              title: 'Upload Images & Documents',
              subtitle: 'Profile image + ID front/back are required. Certificate is optional.',
              children: [
                _imageTile(label: 'Profile Image', file: _profileImage, onPick: _pickProfileImage),
                _imageTile(label: 'ID Front', file: _idFrontImage, onPick: _pickIdFrontImage),
                _imageTile(label: 'ID Back', file: _idBackImage, onPick: _pickIdBackImage),
                _imageTile(label: 'Certificate', file: _certificateImage, onPick: _pickCertificateImage, optional: true),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Business Images (up to 3)', style: TextStyle(fontWeight: FontWeight.w600)),
                    TextButton.icon(
                      onPressed: _safeBusinessImages.length < _maxBusinessImages ? _pickBusinessImage : null,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_safeBusinessImages.isEmpty)
                  Container(
                    height: 90,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: const Text('No business images selected', style: TextStyle(color: Colors.grey)),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_safeBusinessImages.length, (index) {
                      final file = _safeBusinessImages[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FutureBuilder<Uint8List>(
                              future: file.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Container(width: 100, height: 100, color: Colors.grey.shade200, alignment: Alignment.center, child: const CircularProgressIndicator());
                                }
                                if (snapshot.hasData) {
                                  return Image.memory(snapshot.data!, width: 100, height: 100, fit: BoxFit.cover);
                                }
                                return Container(width: 100, height: 100, color: Colors.grey.shade200, alignment: Alignment.center, child: const Text('Error'));
                              },
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _safeBusinessImages.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Submit Application', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Your request is reviewed by admin within 24-48 hours. We will notify you once approved.',
              style: TextStyle(color: Color.fromARGB(255, 97, 97, 97), fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _specializationController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    _phonenumberController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _hourlyRateController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }
}