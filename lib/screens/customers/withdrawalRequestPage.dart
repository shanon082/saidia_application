import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saidia_app/services/firestore_services.dart';
import 'package:flutter/material.dart';



class WithdrawalRequestPage extends StatefulWidget {
  const WithdrawalRequestPage({super.key});

  @override
  State<WithdrawalRequestPage> createState() => _WithdrawalRequestPageState();
}

class _WithdrawalRequestPageState extends State<WithdrawalRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _mobileMoneyController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();
  
  String _selectedMethod = 'mobile_money';
  bool _isLoading = true;
  double _walletBalance = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final user = FirestoreService.instance.currentUser;
      if (user != null) {
        final snap = await Supabase.instance.client.from('wallets').select('balance').eq('userId', user.id).maybeSingle();
        if (snap != null) {
          setState(() {
            _walletBalance = (snap['balance'] as num?)?.toDouble() ?? 0.0;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    try {
      final user = FirestoreService.instance.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final amount = double.parse(_amountController.text.trim());
      
      if (amount > _walletBalance) {
        throw Exception('Insufficient balance');
      }

      await FirestoreService.instance.requestWithdrawal(
        amount: amount,
        method: _selectedMethod,
        mobileMoneyNumber: _selectedMethod == 'mobile_money' ? _mobileMoneyController.text.trim() : null,
        bankAccount: _selectedMethod == 'bank_transfer' ? _bankAccountController.text.trim() : null,
        bankName: _selectedMethod == 'bank_transfer' ? _bankNameController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal request submitted. Awaiting admin approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Withdrawal'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade700, Colors.green.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'UGX ${_walletBalance.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    Text(
                      'Withdrawal Method',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text('Mobile Money'),
                            value: 'mobile_money',
                            groupValue: _selectedMethod,
                            onChanged: (v) => setState(() => _selectedMethod = v!),
                          ),
                          RadioListTile<String>(
                            title: Text('Bank Transfer'),
                            value: 'bank_transfer',
                            groupValue: _selectedMethod,
                            onChanged: (v) => setState(() => _selectedMethod = v!),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (UGX)',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter amount';
                        }
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return 'Please enter valid amount';
                        }
                        if (amount > _walletBalance) {
                          return 'Insufficient balance';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    if (_selectedMethod == 'mobile_money') ...[
                      TextFormField(
                        controller: _mobileMoneyController,
                        decoration: InputDecoration(
                          labelText: 'Mobile Money Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (_selectedMethod == 'mobile_money' && 
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter mobile money number';
                          }
                          return null;
                        },
                      ),
                    ],
                    
                    if (_selectedMethod == 'bank_transfer') ...[
                      TextFormField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          labelText: 'Bank Name',
                          prefixIcon: Icon(Icons.account_balance),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (_selectedMethod == 'bank_transfer' && 
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter bank name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _bankAccountController,
                        decoration: InputDecoration(
                          labelText: 'Account Number',
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (_selectedMethod == 'bank_transfer' && 
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter account number';
                          }
                          return null;
                        },
                      ),
                    ],
                    
                    SizedBox(height: 32),
                    
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber.shade700),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Withdrawal requests require admin approval before processing.',
                              style: TextStyle(color: Colors.amber.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitWithdrawal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit Request',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}