import 'dart:io';

void main() {
  final file = File('lib/services/firestore_services.dart');
  if (!file.existsSync()) return;
  var content = file.readAsStringSync();

  final addMethods = '''
  Future<void> requestWithdrawal({
    required double amount,
    required String method,
    String? mobileMoneyNumber,
    String? bankName,
    String? bankAccount,
  }) async {
    if (currentUid == null) throw Exception('Not authenticated');
    
    // Insert to withdrawal_requests
    await _supabase.from('withdrawal_requests').insert({
      'userId': currentUid,
      'amount': amount,
      'method': method,
      'mobileMoneyNumber': mobileMoneyNumber,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'status': 'pending',
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getWithdrawalRequestsStream() {
    return _supabase.from('withdrawal_requests')
        .stream(primaryKey: ['id'])
        .order('createdAt', ascending: false)
        .map(_toQuerySnapshot);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMyWithdrawalsStream() {
    if (currentUid == null) return const Stream.empty();
    return _supabase.from('withdrawal_requests')
        .stream(primaryKey: ['id'])
        .eq('userId', currentUid!)
        .order('createdAt', ascending: false)
        .map(_toQuerySnapshot);
  }

  Future<void> processWithdrawalAsAdmin({
    required String withdrawalId,
    required String status,
    String? adminNote,
  }) async {
    if (!await isUserAdmin()) throw Exception('Unauthorized');
    
    final req = await _supabase.from('withdrawal_requests').select().eq('id', withdrawalId).maybeSingle();
    if (req == null) throw Exception('Not found');
    if (req['status'] != 'pending') throw Exception('Already processed');
    
    await _supabase.from('withdrawal_requests').update({
      'status': status,
      'adminNote': adminNote,
      'updatedAt': FieldValue.serverTimestamp()
    }).eq('id', withdrawalId);
    
    if (status == 'approved') {
       // Deduct permanently from wallet
       final userId = req['userId'];
       final amount = (req['amount'] as num).toDouble();
       final wallet = await _supabase.from('wallets').select('balance').eq('userId', userId).maybeSingle();
       if (wallet != null) {
          final newBal = (wallet['balance'] as num).toDouble() - amount;
          await _supabase.from('wallets').update({'balance': newBal}).eq('userId', userId);
          
          await _supabase.from('wallet_transactions').insert({
            'userId': userId,
            'type': 'debit',
            'amount': amount,
            'method': req['method'],
            'description': 'Withdrawal approved',
          });
       }
    }
  }
}
''';

  content = content.replaceAll(RegExp(r"}[^}]*$"), addMethods);
  file.writeAsStringSync(content);
}
