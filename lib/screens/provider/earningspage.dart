import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String _selectedPeriod = 'Monthly';
  final List<String> _periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  
  List<ChartData> _earningsData = [];
  List<Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Mock data - Replace with actual Firestore data
    _earningsData = [
      ChartData('Jan', 25000),
      ChartData('Feb', 32000),
      ChartData('Mar', 28000),
      ChartData('Apr', 45000),
      ChartData('May', 38000),
      ChartData('Jun', 52000),
    ];

    _transactions = [
      Transaction(
        id: '1',
        customer: 'John Doe',
        service: 'Plumbing Repair',
        amount: 15000,
        date: DateTime.now().subtract(Duration(days: 2)),
        status: 'completed',
      ),
      Transaction(
        id: '2',
        customer: 'Jane Smith',
        service: 'Electrical Installation',
        amount: 25000,
        date: DateTime.now().subtract(Duration(days: 5)),
        status: 'completed',
      ),
      Transaction(
        id: '3',
        customer: 'Mike Johnson',
        service: 'AC Maintenance',
        amount: 12000,
        date: DateTime.now().subtract(Duration(days: 7)),
        status: 'pending',
      ),
      Transaction(
        id: '4',
        customer: 'Sarah Wilson',
        service: 'Painting Service',
        amount: 35000,
        date: DateTime.now().subtract(Duration(days: 10)),
        status: 'completed',
      ),
      Transaction(
        id: '5',
        customer: 'Robert Brown',
        service: 'Carpentry Work',
        amount: 28000,
        date: DateTime.now().subtract(Duration(days: 12)),
        status: 'completed',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final totalEarnings = _earningsData.fold(0, (sum, item) => sum + item.value);
    final completedEarnings = _transactions
        .where((t) => t.status == 'completed')
        .fold(0, (sum, t) => sum + t.amount);
    final pendingEarnings = _transactions
        .where((t) => t.status == 'pending')
        .fold(0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Earnings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Earnings',
                    'UGX ${NumberFormat('#,###').format(totalEarnings)}',
                    Icons.attach_money,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Available',
                    'UGX ${NumberFormat('#,###').format(completedEarnings)}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Pending',
                    'UGX ${NumberFormat('#,###').format(pendingEarnings)}',
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Services',
                    '${_transactions.length}',
                    Icons.handyman,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Period Selector
            Container(
              padding: EdgeInsets.all(12),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _periods.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        period,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 24),

            // Chart
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Container(
                  //   height: 200,
                  //   child: SfCartesianChart(
                  //     primaryXAxis: CategoryAxis(),
                  //     series: <ChartSeries<ChartData, String>>[
                  //       ColumnSeries<ChartData, String>(
                  //         dataSource: _earningsData,
                  //         xValueMapper: (ChartData data, _) => data.month,
                  //         yValueMapper: (ChartData data, _) => data.value,
                  //         color: Colors.blue.shade700,
                  //         borderRadius: BorderRadius.circular(4),
                  //       )
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all transactions
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ..._transactions.take(3).map((transaction) => _buildTransactionCard(transaction)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: transaction.status == 'completed' 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              transaction.status == 'completed' ? Icons.check_circle : Icons.pending,
              color: transaction.status == 'completed' ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.service,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  transaction.customer,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'UGX ${NumberFormat('#,###').format(transaction.amount)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: transaction.status == 'completed'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transaction.status,
                  style: TextStyle(
                    color: transaction.status == 'completed' ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String month;
  final int value;

  ChartData(this.month, this.value);
}

class Transaction {
  final String id;
  final String customer;
  final String service;
  final int amount;
  final DateTime date;
  final String status;

  Transaction({
    required this.id,
    required this.customer,
    required this.service,
    required this.amount,
    required this.date,
    required this.status,
  });
}