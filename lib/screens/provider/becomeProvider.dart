import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
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

  String _serviceCategory = '';
  String _specialization = '';
  String _experience = '';
  String _description = '';
  String _phonenumber = '';
  String _city = '';
  String _address = '';
  String _hourlyRate = '';

  final List<String> _serviceAreas = [];
  final List<String> _workingDays = [];

  List<File>? _businessImages;
  final int _maxBusinessImages = 3;

  File? _profileImage;
  File? _idFrontImage;
  File? _idBackImage;
  File? _certificateImage;

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
    'Other',
  ];

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final List<String> _possibleAreas = [
    'Nairobi',
    'Mombasa',
    'Kisumu',
    'Nakuru',
    'Eldoret',
  ];

  List<File> get _safeBusinessImages => _businessImages ??= <File>[];

  Future<File?> _pickImageFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1400,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<void> _pickProfileImage() async {
    final image = await _pickImageFromGallery();
    if (image == null) return;
    setState(() => _profileImage = image);
  }

  Future<void> _pickIdFrontImage() async {
    final image = await _pickImageFromGallery();
    if (image == null) return;
    setState(() => _idFrontImage = image);
  }

  Future<void> _pickIdBackImage() async {
    final image = await _pickImageFromGallery();
    if (image == null) return;
    setState(() => _idBackImage = image);
  }

  Future<void> _pickCertificateImage() async {
    final image = await _pickImageFromGallery();
    if (image == null) return;
    setState(() => _certificateImage = image);
  }

  Future<void> _pickBusinessImage() async {
    if (_safeBusinessImages.length >= _maxBusinessImages) return;
    final image = await _pickImageFromGallery();
    if (image == null) return;
    setState(() => _safeBusinessImages.add(image));
  }

  Future<String> _uploadSingleImage({
    required File file,
    required String folder,
  }) async {
    final path =
        '$folder/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('\\').last}';
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<List<String>> _uploadBusinessImages() async {
    final urls = <String>[];
    for (final file in _safeBusinessImages) {
      final url = await _uploadSingleImage(
        file: file,
        folder: 'provider_documents/business_images',
      );
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_serviceAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service area.'),
        ),
      );
      return;
    }

    if (_workingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one working day.'),
        ),
      );
      return;
    }

    if (_profileImage == null ||
        _idFrontImage == null ||
        _idBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile image, ID front, and ID back are required.'),
        ),
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
        specialization: _specialization,
        experience: _experience,
        description: _description,
        phonenumber: _phonenumber,
        imageUrl: profileImageUrl,
        city: _city,
        address: _address,
        hourlyRate: _hourlyRate,
        serviceAreas: _serviceAreas,
        workingDays: _workingDays,
        idFront: idFrontUrl,
        idBack: idBackUrl,
        certificate: certificateUrl,
        businessImages: businessImages,
      );

      await _service.applyAsProvider();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Application submitted successfully. Awaiting admin approval.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _imageTile({
    required String label,
    required File? file,
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
              child: Image.file(
                file,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(title: const Text('Become a Provider'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete your profile and upload your documents. Approval usually takes 24-48 hours.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            _sectionCard(
              title: 'Service Information',
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Service Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  validator: (v) => v == null ? 'Required' : null,
                  onChanged: (v) => setState(() => _serviceCategory = v ?? ''),
                  onSaved: (v) => _serviceCategory = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Specialization',
                    hintText: 'e.g. Pipe installation, House wiring',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onSaved: (v) => _specialization = v!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    hintText: 'e.g. 5',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onSaved: (v) => _experience = v!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Service Description',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onSaved: (v) => _description = v!.trim(),
                ),
              ],
            ),
            _sectionCard(
              title: 'Contact & Pricing',
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onSaved: (v) => _phonenumber = v!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onSaved: (v) => _city = v!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Full Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onSaved: (v) => _address = v!.trim(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Hourly Rate (UGX)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  onSaved: (v) => _hourlyRate = v!.trim(),
                ),
              ],
            ),
            _sectionCard(
              title: 'Coverage & Availability',
              children: [
                const Text(
                  'Service Areas',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _possibleAreas.map((area) {
                    final selected = _serviceAreas.contains(area);
                    return FilterChip(
                      label: Text(area),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _serviceAreas.add(area);
                          } else {
                            _serviceAreas.remove(area);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Working Days',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _days.map((day) {
                    final selected = _workingDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _workingDays.add(day);
                          } else {
                            _workingDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            _sectionCard(
              title: 'Upload Images & Documents',
              subtitle:
                  'Profile image + ID front/back are required. Certificate is optional.',
              children: [
                _imageTile(
                  label: 'Profile Image',
                  file: _profileImage,
                  onPick: _pickProfileImage,
                ),
                _imageTile(
                  label: 'ID Front',
                  file: _idFrontImage,
                  onPick: _pickIdFrontImage,
                ),
                _imageTile(
                  label: 'ID Back',
                  file: _idBackImage,
                  onPick: _pickIdBackImage,
                ),
                _imageTile(
                  label: 'Certificate',
                  file: _certificateImage,
                  onPick: _pickCertificateImage,
                  optional: true,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Business Images (up to 3)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      onPressed: _safeBusinessImages.length < _maxBusinessImages
                          ? _pickBusinessImage
                          : null,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_safeBusinessImages.isEmpty)
                  Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No business images selected',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(_safeBusinessImages.length, (
                      index,
                    ) {
                      final file = _safeBusinessImages[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              file,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: InkWell(
                              onTap: () => setState(
                                () => _safeBusinessImages.removeAt(index),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitApplication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Application',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Your request is reviewed by admin within 24-48 hours. We will notify you once approved.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
