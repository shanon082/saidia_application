import 'package:flutter/material.dart';
import 'package:saidia_app/services/firestore_services.dart';

class ProviderEditProfilePage extends StatefulWidget {
  const ProviderEditProfilePage({super.key});

  @override
  State<ProviderEditProfilePage> createState() => _ProviderEditProfilePageState();
}

class _ProviderEditProfilePageState extends State<ProviderEditProfilePage> {
  final FirestoreService _service = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _service.getCurrentUserData();
      final provider = await _service.getProviderApplicationData();
      if (!mounted) return;
      _nameController.text = user?['name']?.toString() ?? '';
      _phoneController.text =
          provider?['phonenumber']?.toString() ?? user?['phone']?.toString() ?? '';
      _specializationController.text = provider?['specialization']?.toString() ?? '';
      _descriptionController.text = provider?['description']?.toString() ?? '';
      _cityController.text = provider?['city']?.toString() ?? '';
      _addressController.text = provider?['address']?.toString() ?? '';
      _hourlyRateController.text = provider?['hourlyRate']?.toString() ?? '';
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.updateProviderProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        specialization: _specializationController.text,
        description: _descriptionController.text,
        city: _cityController.text,
        address: _addressController.text,
        hourlyRate: _hourlyRateController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return '$label is required';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Provider Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(controller: _nameController, label: 'Name'),
                    _field(
                      controller: _phoneController,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                    ),
                    _field(
                      controller: _specializationController,
                      label: 'Specialization',
                    ),
                    _field(
                      controller: _hourlyRateController,
                      label: 'Hourly Rate (UGX)',
                      keyboardType: TextInputType.number,
                    ),
                    _field(controller: _cityController, label: 'City'),
                    _field(controller: _addressController, label: 'Address'),
                    _field(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

