import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  String _statusFilter = 'all'; // 'all', 'pending', 'confirmed', 'rejected'
  String _sortBy = 'created';
  bool _sortAscending = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _statusFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'confirmed', child: Text('Confirmed')),
                        DropdownMenuItem(
                            value: 'rejected', child: Text('Rejected')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value!;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _sortBy,
                      items: const [
                        DropdownMenuItem(
                            value: 'created', child: Text('Sort by Created')),
                        DropdownMenuItem(
                            value: 'service', child: Text('Sort by Service')),
                        DropdownMenuItem(
                            value: 'customer', child: Text('Sort by Customer')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      ),
                      onPressed: () {
                        setState(() {
                          _sortAscending = !_sortAscending;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _selectDate(context, isStart: true),
                      child: Text(
                          'Start: ${_startDate != null ? DateFormat('MM/dd/yyyy').format(_startDate!) : 'Select'}'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _selectDate(context, isStart: false),
                      child: Text(
                          'End: ${_endDate != null ? DateFormat('MM/dd/yyyy').format(_endDate!) : 'Select'}'),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bookings list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getBookingStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var bookings = snapshot.data?.docs ?? [];

                // ====== CLIENT-SIDE DATE RANGE FILTERING ======
                if (_startDate != null || _endDate != null) {
                  bookings = bookings.where((booking) {
                    final data = booking.data() as Map<String, dynamic>;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    
                    if (createdAt == null) return false;
                    
                    if (_startDate != null && createdAt.isBefore(_startDate!)) {
                      return false;
                    }
                    
                    if (_endDate != null) {
                      final endOfDay = DateTime(
                        _endDate!.year, 
                        _endDate!.month, 
                        _endDate!.day, 
                        23, 59, 59
                      );
                      if (createdAt.isAfter(endOfDay)) {
                        return false;
                      }
                    }
                    
                    return true;
                  }).toList();
                }

                // ====== CLIENT-SIDE SORTING ======
                bookings.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  
                  int comparison = 0;
                  
                  switch (_sortBy) {
                    case 'service':
                      final aService = aData['serviceName'] ?? '';
                      final bService = bData['serviceName'] ?? '';
                      comparison = aService.toString().toLowerCase()
                          .compareTo(bService.toString().toLowerCase());
                      break;
                      
                    case 'customer':
                      final aCustomer = aData['customerId'] ?? '';
                      final bCustomer = bData['customerId'] ?? '';
                      comparison = aCustomer.toString().toLowerCase()
                          .compareTo(bCustomer.toString().toLowerCase());
                      break;
                      
                    case 'created':
                    default:
                      final aDate = (aData['createdAt'] as Timestamp?)?.toDate() 
                          ?? DateTime(1970);
                      final bDate = (bData['createdAt'] as Timestamp?)?.toDate() 
                          ?? DateTime(1970);
                      comparison = aDate.compareTo(bDate);
                      break;
                  }
                  
                  // Apply sort direction (_sortAscending controls the order)
                  return _sortAscending ? comparison : -comparison;
                });

                if (bookings.isEmpty) {
                  return const Center(child: Text('No bookings found'));
                }

                // ====== REST OF YOUR EXISTING LISTVIEW CODE ======
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final data = booking.data() as Map<String, dynamic>;
                    final serviceName = data['serviceName'] ?? 'Unknown Service';
                    final customerId = data['customerId'] ?? '';
                    final vendorId = data['vendorId'] ?? '';
                    final status = data['status'] ?? 'pending';
                    final price = data['price'] ?? 0.0;
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final formattedDate = createdAt != null
                        ? DateFormat('MMM dd, yyyy HH:mm').format(createdAt)
                        : 'Unknown';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(serviceName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer ID: $customerId'),
                            Text('Vendor ID: $vendorId'),
                            Text('Booked on: $formattedDate'),
                            Text('Price: \$${price.toStringAsFixed(2)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(status.toUpperCase()),
                              backgroundColor: _getStatusColor(status),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              onSelected: (value) =>
                                  _handleBookingAction(value, booking),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Text('View Details'),
                                ),
                                if (status == 'pending')
                                  const PopupMenuItem(
                                    value: 'confirm',
                                    child: Text('Confirm Booking'),
                                  ),
                                if (status == 'pending')
                                  const PopupMenuItem(
                                    value: 'reject',
                                    child: Text('Reject Booking'),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete Booking'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getBookingStream() {
    Query query = FirebaseFirestore.instance.collection('bookings');

    // Apply status filter
    if (_statusFilter != 'all') {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    // Apply date range filter
    if (_startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }
    
    if (_endDate != null) {
      // Set end date to end of day
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green.withValues(alpha: 0.2);
      case 'rejected':
        return Colors.red.withValues(alpha: 0.2);
      case 'pending':
      default:
        return Colors.orange.withValues(alpha: 0.2);
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _handleBookingAction(
      String action, DocumentSnapshot booking) async {
    final data = booking.data() as Map<String, dynamic>;
    final serviceName = data['serviceName'] ?? 'Service';
    final bookingId = booking.id;

    switch (action) {
      case 'view':
        _showBookingDetails(booking);
        break;
      case 'confirm':
        _confirmAction(
          context,
          'Confirm Booking',
          'Are you sure you want to confirm the booking for "$serviceName"?',
          () => _updateBookingStatus(bookingId, 'confirmed'),
        );
        break;
      case 'reject':
        _confirmAction(
          context,
          'Reject Booking',
          'Are you sure you want to reject the booking for "$serviceName"?',
          () => _updateBookingStatus(bookingId, 'rejected'),
        );
        break;
      case 'delete':
        _confirmAction(
          context,
          'Delete Booking',
          'Are you sure you want to delete the booking for "$serviceName"? This action cannot be undone.',
          () => _deleteBooking(bookingId),
        );
        break;
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking $newStatus successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating booking: $e')),
        );
      }
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting booking: $e')),
        );
      }
    }
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(DocumentSnapshot booking) {
    final data = booking.data() as Map<String, dynamic>;
    final serviceName = data['serviceName'] ?? 'Unknown Service';
    final customerId = data['customerId'] ?? '';
    final vendorId = data['vendorId'] ?? '';
    final status = data['status'] ?? 'pending';
    final price = data['price'] ?? 0.0;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy HH:mm').format(createdAt)
        : 'Unknown';

    // Get customer and vendor names
    final customerFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(customerId)
        .get();
    final vendorFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(vendorId)
        .get();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(serviceName),
        content: FutureBuilder(
          future: Future.wait([customerFuture, vendorFuture]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            String customerName = 'Unknown Customer';
            String vendorName = 'Unknown Vendor';

            if (snapshot.hasData) {
              final customerDoc = snapshot.data![0] as DocumentSnapshot;
              final vendorDoc = snapshot.data![1] as DocumentSnapshot;

              if (customerDoc.exists) {
                customerName =
                    (customerDoc.data() as Map<String, dynamic>)['name'] ??
                        'Unknown Customer';
              }

              if (vendorDoc.exists) {
                vendorName =
                    (vendorDoc.data() as Map<String, dynamic>)['name'] ??
                        'Unknown Vendor';
              }
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer: $customerName'),
                  const SizedBox(height: 8),
                  Text('Vendor: $vendorName'),
                  const SizedBox(height: 8),
                  Text('Status: ${status.toUpperCase()}'),
                  const SizedBox(height: 8),
                  Text('Price: \$${price.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('Booked on: $formattedDate'),
                ],
              ),
            );
          },
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