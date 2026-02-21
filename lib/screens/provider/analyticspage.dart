import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'package:intl/intl.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedTimeRange = 'This Month';
  final List<String> _timeRanges = ['Today', 'This Week', 'This Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Time Range Selector
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
                children: _timeRanges.map((range) {
                  final isSelected = _selectedTimeRange == range;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimeRange = range;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        range,
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

            // Performance Metrics
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _metricCard(
                  'Bookings',
                  '24',
                  Icons.book_online,
                  Colors.blue,
                  '+12% from last month',
                ),
                _metricCard(
                  'Revenue',
                  'UGX 45,200',
                  Icons.attach_money,
                  Colors.green,
                  '+18% from last month',
                ),
                _metricCard(
                  'Response Time',
                  '2.4 hrs',
                  Icons.access_time,
                  Colors.orange,
                  '-0.5 hrs from last month',
                ),
                _metricCard(
                  'Rating',
                  '4.8',
                  Icons.star,
                  Colors.amber,
                  '+0.2 from last month',
                ),
              ],
            ),
            SizedBox(height: 24),

            // Revenue Chart
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
                    'Revenue Trend',
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
                  //     primaryYAxis: NumericAxis(
                  //       numberFormat: NumberFormat.compactCurrency(
                  //         symbol: 'UGX ',
                  //         decimalDigits: 0,
                  //       ),
                  //     ),
                  //     series: <ChartSeries>[
                  //       LineSeries<ChartData, String>(
                  //         dataSource: [
                  //           ChartData('Mon', 12000),
                  //           ChartData('Tue', 15000),
                  //           ChartData('Wed', 18000),
                  //           ChartData('Thu', 22000),
                  //           ChartData('Fri', 25000),
                  //           ChartData('Sat', 28000),
                  //           ChartData('Sun', 20000),
                  //         ],
                  //         xValueMapper: (ChartData data, _) => data.month,
                  //         yValueMapper: (ChartData data, _) => data.value,
                  //         color: Colors.green,
                  //         markerSettings: MarkerSettings(isVisible: true),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Service Distribution
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
                    'Service Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Container(
                  //   height: 200,
                  //   child: SfCircularChart(
                  //     series: <CircularSeries>[
                  //       DoughnutSeries<ServiceData, String>(
                  //         dataSource: [
                  //           ServiceData('Plumbing', 35, Colors.blue),
                  //           ServiceData('Electrical', 25, Colors.green),
                  //           ServiceData('Cleaning', 20, Colors.orange),
                  //           ServiceData('Carpentry', 15, Colors.purple),
                  //           ServiceData('Others', 5, Colors.grey),
                  //         ],
                  //         xValueMapper: (ServiceData data, _) => data.service,
                  //         yValueMapper: (ServiceData data, _) => data.percentage,
                  //         pointColorMapper: (ServiceData data, _) => data.color,
                  //         dataLabelSettings: DataLabelSettings(isVisible: true),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Customer Insights
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
                    'Customer Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  SizedBox(height: 16),
                  _insightItem('Repeat Customers', '65%', Colors.green),
                  _insightItem('New Customers', '35%', Colors.blue),
                  _insightItem('Customer Satisfaction', '94%', Colors.amber),
                  _insightItem('Response Rate', '88%', Colors.purple),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, String change) {
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
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                change.startsWith('+') ? '📈' : change.startsWith('-') ? '📉' : '➡️',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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
          SizedBox(height: 8),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: change.startsWith('+') ? Colors.green : 
                     change.startsWith('-') ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightItem(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceData {
  final String service;
  final int percentage;
  final Color color;

  ServiceData(this.service, this.percentage, this.color);
}