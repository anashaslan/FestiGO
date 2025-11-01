import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// ============================================================================
// BookingsByCategoryChart - FIXED VERSION with FutureBuilder
// ============================================================================
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
  State<BookingsByCategoryChart> createState() =>
      _BookingsByCategoryChartState();
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
    return FutureBuilder<Map<String, int>>(
      future: _fetchCategoryData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final categoryMap = snapshot.data ?? {};

        if (categoryMap.isEmpty) {
          return _buildPieChart({}, 'No data available');
        }

        return _buildPieChart(categoryMap, '');
      },
    );
  }

  /// Fetches all bookings and processes them into category counts
  Future<Map<String, int>> _fetchCategoryData() async {
    try {
      // Step 1: Fetch all bookings in date range
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(widget.startDate))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(widget.endDate))
          .get();

      if (bookingsSnapshot.docs.isEmpty) {
        return {};
      }

      // Step 2: Collect unique service IDs
      final serviceIds = <String>{};
      for (var booking in bookingsSnapshot.docs) {
        final data = booking.data();
        final serviceId = data['serviceId'] as String?;
        if (serviceId != null) {
          serviceIds.add(serviceId);
        }
      }

      if (serviceIds.isEmpty) {
        return {};
      }

      // Step 3: Batch fetch all services using Future.wait for efficiency
      final serviceFutures = serviceIds.map((serviceId) =>
          FirebaseFirestore.instance
              .collection('services')
              .doc(serviceId)
              .get());
      final serviceDocs = await Future.wait(serviceFutures);

      // Step 4: Create service ID to category mapping
      final Map<String, String> serviceToCategory = {};
      for (var serviceDoc in serviceDocs) {
        if (serviceDoc.exists) {
          final serviceData = serviceDoc.data() as Map<String, dynamic>;
          final category = serviceData['category'] as String? ?? 'Unknown';
          serviceToCategory[serviceDoc.id] = category;
        }
      }

      // Step 5: Count bookings by category
      final Map<String, int> categoryMap = {};
      for (var booking in bookingsSnapshot.docs) {
        final data = booking.data();
        final serviceId = data['serviceId'] as String?;
        if (serviceId != null && serviceToCategory.containsKey(serviceId)) {
          final category = serviceToCategory[serviceId]!;
          categoryMap[category] = (categoryMap[category] ?? 0) + 1;
        }
      }

      return categoryMap;
    } catch (e) {
      print('Error fetching category  $e');
      return {};
    }
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
    final total = data.values.fold(0, (sum, item) => sum + item);
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
        // Legend - Changed to vertical layout with wrapping
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: data.entries.map((entry) {
            final index = data.keys.toList().indexOf(entry.key);
            final category = entry.key;
            final count = entry.value;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _colors[index % _colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$category ($count)',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// MonthlyRevenueChart - Works correctly, keeping as-is with StreamBuilder
// ============================================================================
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
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(widget.startDate))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(widget.endDate))
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
    final maxValue = data.values
        .fold(0.0, (maxValue, value) => value > maxValue ? value : maxValue);

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
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              final monthName = DateFormat('MMM yyyy').format(DateTime(
                  int.parse(monthKey.split('-')[0]),
                  int.parse(monthKey.split('-')[1])));
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

// ============================================================================
// UserGrowthChart - Works correctly, keeping as-is with StreamBuilder
// ============================================================================
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
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['customer', 'vendor']).snapshots(),
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
                  belowBarData: BarAreaData(
                      show: true, color: Colors.green.withValues(alpha: 0.3)),
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
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              gridData: FlGridData(show: true),
              maxY:
                  (cumulative * 1.2).toDouble(), // Add some padding at the top
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
              final monthName = DateFormat('MMM yyyy').format(DateTime(
                  int.parse(monthKey.split('-')[0]),
                  int.parse(monthKey.split('-')[1])));
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
