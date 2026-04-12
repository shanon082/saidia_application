import 'dart:io';

void main() {
  final file = File('lib/screens/customers/withdrawalRequestPage.dart');
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();

  content = content.replaceAll(
    """        final snap = await FirebaseFirestore.instance
            .collection('wallets')
            .doc(user.uid)
            .get();
        if (snap.exists) {
          setState(() {
            _walletBalance = (snap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
            _isLoading = false;
          });
        }""",
    """        final snap = await Supabase.instance.client.from('wallets').select('balance').eq('userId', user.uid).maybeSingle();
        if (snap != null) {
          setState(() {
            _walletBalance = (snap['balance'] as num?)?.toDouble() ?? 0.0;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }"""
  );

  content = content.replaceAll(
    """      await FirebaseFirestore.instance.collection('withdrawal_requests').add({
        'userId': user.uid,
        'amount': amount,
        'currency': 'UGX',
        'method': _selectedMethod,
        'mobileMoneyNumber': _selectedMethod == 'mobile_money' ? _mobileMoneyController.text.trim() : null,
        'bankAccount': _selectedMethod == 'bank_transfer' ? _bankAccountController.text.trim() : null,
        'bankName': _selectedMethod == 'bank_transfer' ? _bankNameController.text.trim() : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });""",
    """      await FirestoreService.instance.requestWithdrawal(
        amount: amount,
        method: _selectedMethod,
        mobileMoneyNumber: _selectedMethod == 'mobile_money' ? _mobileMoneyController.text.trim() : null,
        bankAccount: _selectedMethod == 'bank_transfer' ? _bankAccountController.text.trim() : null,
        bankName: _selectedMethod == 'bank_transfer' ? _bankNameController.text.trim() : null,
      );"""
  );

  file.writeAsStringSync(content);
}
