import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BookingsByCategoryChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? title;

  const BookingsByCategoryChart({
    super.key,
    required this.startDate,
    required this.endDate,
    this.title,
  });

  @override
  State<BookingsByCategoryChart> createState() => _BookingsByCategoryChartState();
}

class _BookingsByCategoryChartState extends State<BookingsByCategoryChart> {
  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(widget.endDate))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data?.docs ?? [];
        
        // Group bookings by service category
        final categoryMap = <String, int>{};
        
        for (var booking in bookings) {
          final data = booking.data() as Map<String, dynamic>;
          final serviceId = data['serviceId'] as String?;
          
          if (serviceId != null) {
            // Get service category
            FirebaseFirestore.instance.collection('services').doc(serviceId).get().then((serviceDoc) {
              if (serviceDoc.exists) {
                final serviceData = serviceDoc.data() as Map<String, dynamic>;
                final category = serviceData['category'] as String? ?? 'Unknown';
                
                setState(() {
                  categoryMap[category] = (categoryMap[category] ?? 0) + 1;
                });
              }
            });
          }
        }
        
        // For initial build, we'll show a loading state or default data
        if (categoryMap.isEmpty) {
          return _buildPieChart({}, 'No data available');
        }
        
        return _buildPieChart(categoryMap, '');
      },
    );
  }

  Widget _buildPieChart(Map<String, int> data, String emptyMessage) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final List<PieChartSectionData> sections = [];
    final total = data.values.fold(0, (sumValue, item) => sumValue + item);
    
    int index = 0;
    data.forEach((category, count) {
      final percentage = total > 0 ? (count / total) * 100 : 0;
      
      sections.add(
        PieChartSectionData(
          color: _colors[index % _colors.length],
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      
      index++;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: data.length,
            itemBuilder: (context, index) {
              final category = data.keys.elementAt(index);
              final count = data.values.elementAt(index);
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: _colors[index % _colors.length],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$category ($count)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class MonthlyRevenueChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? title;

  const MonthlyRevenueChart({
    super.key,
    required this.startDate,
    required this.endDate,
    this.title,
  });

  @override
  State<MonthlyRevenueChart> createState() => _MonthlyRevenueChartState();
}

class _MonthlyRevenueChartState extends State<MonthlyRevenueChart> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(widget.endDate))
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data?.docs ?? [];
        
        // Group by month and calculate revenue
        final monthlyRevenue = <String, double>{};
        
        for (var booking in bookings) {
          final data = booking.data() as Map<String, dynamic>;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
          
          if (createdAt != null) {
            final monthKey = DateFormat('yyyy-MM').format(createdAt);
            monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + price;
          }
        }
        
        return _buildBarChart(monthlyRevenue);
      },
    );
  }

  Widget _buildBarChart(Map<String, double> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No revenue data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final List<BarChartGroupData> barGroups = [];
    final List<String> months = data.keys.toList()..sort();
    final maxValue = data.values.fold(0.0, (maxValue, value) => value > maxValue ? value : maxValue);
    
    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final revenue = data[month] ?? 0.0;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: revenue,
              color: Colors.blue,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < months.length) {
                        return Text(
                          months[index].split('-')[1], // Just the month number
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 20,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true),
              maxY: maxValue * 1.2, // Add some padding at the top
            ),
          ),
        ),
        const SizedBox(height: 16),
        // X-axis labels
        SizedBox(
          height: 30,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final monthKey = months[index];
              final monthName = DateFormat('MMM yyyy').format(
                DateTime(int.parse(monthKey.split('-')[0]), int.parse(monthKey.split('-')[1]))
              );
              
              return SizedBox(
                width: 60,
                child: Text(
                  monthName,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class UserGrowthChart extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String? title;

  const UserGrowthChart({
    super.key,
    required this.startDate,
    required this.endDate,
    this.title,
  });

  @override
  State<UserGrowthChart> createState() => _UserGrowthChartState();
}

class _UserGrowthChartState extends State<UserGrowthChart> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', whereIn: ['customer', 'vendor'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];
        
        // Group by month and calculate cumulative growth
        final monthlyGrowth = <String, int>{};
        
        for (var user in users) {
          final data = user.data() as Map<String, dynamic>;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          
          if (createdAt != null && 
              createdAt.isAfter(widget.startDate) && 
              createdAt.isBefore(widget.endDate)) {
            final monthKey = DateFormat('yyyy-MM').format(createdAt);
            monthlyGrowth[monthKey] = (monthlyGrowth[monthKey] ?? 0) + 1;
          }
        }
        
        return _buildLineChart(monthlyGrowth);
      },
    );
  }

  Widget _buildLineChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No user growth data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final List<FlSpot> spots = [];
    final List<String> months = data.keys.toList()..sort();
    final maxValue = data.values.fold(0, (maxVal, value) => value > maxVal ? value : maxVal);
    
    // Calculate cumulative values
    int cumulative = 0;
    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      cumulative += data[month] ?? 0;
      spots.add(FlSpot(i.toDouble(), cumulative.toDouble()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.3)),
                  dotData: FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < months.length) {
                        return Text(
                          months[index].split('-')[1], // Just the month number
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 20,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              gridData: FlGridData(show: true),
              maxY: (cumulative * 1.2).toDouble(), // Add some padding at the top
            ),
          ),
        ),
        const SizedBox(height: 16),
        // X-axis labels
        SizedBox(
          height: 30,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final monthKey = months[index];
              final monthName = DateFormat('MMM yyyy').format(
                DateTime(int.parse(monthKey.split('-')[0]), int.parse(monthKey.split('-')[1]))
              );
              
              return SizedBox(
                width: 60,
                child: Text(
                  monthName,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}