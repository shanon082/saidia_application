import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:saidia_app/services/firestore_services.dart';

class WithdrawalManagementPage extends StatefulWidget {
  const WithdrawalManagementPage({super.key});

  @override
  State<WithdrawalManagementPage> createState() =>
      _WithdrawalManagementPageState();
}

class _WithdrawalManagementPageState extends State<WithdrawalManagementPage> {
  final _service = FirestoreService();
  final _noteController = TextEditingController();
  String? _selectedWithdrawalId;
  String? _selectedStatus;

  bool _isProcessing = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _getWithdrawals() {
    return _service.getWithdrawalRequestsStream();
  }

  Future<void> _processWithdrawal(String withdrawalId, String status) async {
    setState(() {
      _isProcessing = true;
      _selectedWithdrawalId = withdrawalId;
      _selectedStatus = status;
    });

    try {
      await _service.processWithdrawalAsAdmin(
        withdrawalId: withdrawalId,
        status: status,
        adminNote: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal $status successfully'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _noteController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
        _selectedWithdrawalId = null;
        _selectedStatus = null;
      });
    }
  }

  void _showProcessDialog(String withdrawalId, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Process Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to $status this withdrawal request?'),
            SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Admin Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processWithdrawal(withdrawalId, status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            ),
            child: Text(status == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Withdrawal Requests'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _getWithdrawals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No withdrawal requests',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final withdrawals = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: withdrawals.length,
            itemBuilder: (context, index) {
              final withdrawal = withdrawals[index].data();
              final status = withdrawal['status'] ?? 'pending';
              final amount = (withdrawal['amount'] as num?)?.toDouble() ?? 0.0;
              final method = withdrawal['method'] ?? 'unknown';

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'UGX ${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'pending'
                                  ? Colors.orange.shade100
                                  : status == 'approved'
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status == 'pending'
                                    ? Colors.orange.shade700
                                    : status == 'approved'
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Method: ${method == 'mobile_money' ? 'Mobile Money' : 'Bank Transfer'}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (withdrawal['mobileMoneyNumber'] != null)
                        Text(
                          'Number: ${withdrawal['mobileMoneyNumber']}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      if (withdrawal['bankName'] != null)
                        Text(
                          'Bank: ${withdrawal['bankName']}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      if (withdrawal['bankAccount'] != null)
                        Text(
                          'Account: ${withdrawal['bankAccount']}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      SizedBox(height: 8),
                      Text(
                        'Requested: ${_formatDate(withdrawal['createdAt'])}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (status == 'pending') ...[
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _showProcessDialog(
                                        withdrawals[index].id,
                                        'approved',
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: Text('Approve'),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isProcessing
                                    ? null
                                    : () => _showProcessDialog(
                                        withdrawals[index].id,
                                        'rejected',
                                      ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text('Reject'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      return DateFormat('MMM d, yyyy HH:mm').format(timestamp.toDate());
    }
    return 'N/A';
  }
}
