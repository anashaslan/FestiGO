import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class VendorAvailabilityCalendarScreen extends StatefulWidget {
  const VendorAvailabilityCalendarScreen({super.key});

  @override
  State<VendorAvailabilityCalendarScreen> createState() =>
      _VendorAvailabilityCalendarScreenState();
}

class _VendorAvailabilityCalendarScreenState
    extends State<VendorAvailabilityCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  // Store unavailable dates
  Map<DateTime, List<dynamic>> _unavailableDates = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadUnavailableDates();
  }

  Future<void> _loadUnavailableDates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vendor_availability')
          .doc(user.uid)
          .collection('unavailable_dates')
          .get();

      final unavailableDates = <DateTime, List<dynamic>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = doc.id;
        final year = int.parse(dateStr.substring(0, 4));
        final month = int.parse(dateStr.substring(4, 6));
        final day = int.parse(dateStr.substring(6, 8));
        final date = DateTime(year, month, day);

        unavailableDates[date] = data['reasons'] ?? [];
      }

      setState(() {
        _unavailableDates = unavailableDates;
      });
    } catch (e) {
      print('Error loading unavailable dates: $e');
    }
  }

  Future<void> _saveUnavailableDate(DateTime date, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final dateStr =
          '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      
      final docRef = FirebaseFirestore.instance
          .collection('vendor_availability')
          .doc(user.uid)
          .collection('unavailable_dates')
          .doc(dateStr);

      // Check if document exists
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // Add reason to existing reasons
        final data = docSnapshot.data() as Map<String, dynamic>;
        final reasons = List<String>.from(data['reasons'] ?? []);
        if (!reasons.contains(reason)) {
          reasons.add(reason);
        }
        
        await docRef.update({'reasons': reasons});
      } else {
        // Create new document
        await docRef.set({
          'date': date,
          'reasons': [reason],
        });
      }

      // Update local state
      setState(() {
        if (_unavailableDates.containsKey(date)) {
          if (!_unavailableDates[date]!.contains(reason)) {
            _unavailableDates[date]!.add(reason);
          }
        } else {
          _unavailableDates[date] = [reason];
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Date marked as unavailable')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving date: $e')),
        );
      }
    }
  }

  Future<void> _removeUnavailableDate(DateTime date, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final dateStr =
          '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      
      final docRef = FirebaseFirestore.instance
          .collection('vendor_availability')
          .doc(user.uid)
          .collection('unavailable_dates')
          .doc(dateStr);

      // Remove reason from existing reasons
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final reasons = List<String>.from(data['reasons'] ?? []);
        reasons.remove(reason);
        
        if (reasons.isEmpty) {
          // Delete document if no reasons left
          await docRef.delete();
        } else {
          // Update document with remaining reasons
          await docRef.update({'reasons': reasons});
        }
      }

      // Update local state
      setState(() {
        if (_unavailableDates.containsKey(date)) {
          _unavailableDates[date]!.remove(reason);
          if (_unavailableDates[date]!.isEmpty) {
            _unavailableDates.remove(date);
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Date availability updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating date: $e')),
        );
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _unavailableDates[day] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        // Reset range selection
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });
    }
  }

  void _onRangeSelected(
      DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
      // Use `CalendarStyle` to customize the day cells in the calendar
      outsideDaysVisible: true,
      defaultDecoration: const BoxDecoration(),
      weekendDecoration: const BoxDecoration(),
      selectedDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      todayDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      markerSize: 5,
      markersAnchor: 1.2,
      markerMargin: const EdgeInsets.symmetric(horizontal: 0.3),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.twoWeeks: '2 Weeks',
              CalendarFormat.week: 'Week',
            },
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUnavailableDateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _selectedDay != null
        ? _getEventsForDay(_selectedDay!)
        : _rangeStart != null && _rangeEnd != null
            ? _getEventsForRange(_rangeStart!, _rangeEnd!)
            : [];

    if (events.isEmpty) {
      return const Center(
        child: Text('No unavailable dates selected'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final reason = events[index] as String;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(reason),
            subtitle: _selectedDay != null
                ? Text(
                    '${_selectedDay!.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}')
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                if (_selectedDay != null) {
                  _removeUnavailableDate(_selectedDay!, reason);
                }
              },
            ),
          ),
        );
      },
    );
  }

  List<dynamic> _getEventsForRange(DateTime start, DateTime end) {
    final events = <dynamic>[];
    for (var date in _unavailableDates.keys) {
      if (date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)))) {
        events.addAll(_unavailableDates[date]!);
      }
    }
    return events;
  }

  void _showAddUnavailableDateDialog() {
    final reasonController = TextEditingController();
    final selectedDate = _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Date as Unavailable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Selected Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (e.g., Holiday, Maintenance)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                _saveUnavailableDate(selectedDate, reasonController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Availability Calendar'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tap a date to select it'),
              Text('• Tap the + button to mark a date as unavailable'),
              Text('• Long press a date to select a range'),
              Text('• Tap a marked date to see/edit reasons'),
              SizedBox(height: 16),
              Text(
                'Note:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                  'Customers will not be able to book your services on dates marked as unavailable.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}