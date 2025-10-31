import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  String _categoryFilter = 'all';
  String _sortBy = 'name';
  bool _sortAscending = true;
  final List<String> _categories = [
    'COMMUNITY AND PUBLIC',
    'CORPORATE & BUSINESS',
    'EDUCATION & SCHOOL',
    'ENTERTAINMENT & STAGES',
    'PERSONAL & FAMILY',
    'OTHERS & CUSTOM'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Management'),
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
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _categoryFilter,
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                            ..._categories.map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category, overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _categoryFilter = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _sortBy,
                          items: const [
                            DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                            DropdownMenuItem(value: 'price', child: Text('Sort by Price')),
                            DropdownMenuItem(value: 'created', child: Text('Sort by Created')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                      ),
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
              ],
            ),
          ),
          // Services list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getServiceStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var services = snapshot.data?.docs ?? [];

                // ====== CLIENT-SIDE SORTING ======
                services.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  
                  int comparison = 0;
                  
                  switch (_sortBy) {
                    case 'name':
                      final aName = aData['serviceName'] ?? '';
                      final bName = bData['serviceName'] ?? '';
                      comparison = aName.toString().toLowerCase()
                          .compareTo(bName.toString().toLowerCase());
                      break;
                      
                    case 'price':
                      final aPrice = aData['price'] ?? 0.0;
                      final bPrice = bData['price'] ?? 0.0;
                      comparison = aPrice.compareTo(bPrice);
                      break;
                      
                    case 'created':
                      final aDate = (aData['createdAt'] as Timestamp?)?.toDate() 
                          ?? DateTime(1970);
                      final bDate = (bData['createdAt'] as Timestamp?)?.toDate() 
                          ?? DateTime(1970);
                      comparison = aDate.compareTo(bDate);
                      break;
                  }
                  
                  // Apply sort direction
                  return _sortAscending ? comparison : -comparison;
                });

                if (services.isEmpty) {
                  return const Center(child: Text('No services found'));
                }

                // ====== YOUR EXISTING LISTVIEW CODE ======
                return ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final data = service.data() as Map<String, dynamic>;
                    final serviceName = data['serviceName'] ?? 'Unnamed Service';
                    final description = data['description'] ?? 'No description';
                    final price = data['price'] ?? 0.0;
                    final category = data['category'] ?? 'OTHERS & CUSTOM';
                    final imageUrl = data['imageUrl'];
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final formattedDate = createdAt != null
                        ? DateFormat('MMM dd, yyyy').format(createdAt)
                        : 'Unknown';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: imageUrl != null && imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.image, size: 25),
                                  ),
                            title: Text(
                              serviceName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('\$${price.toStringAsFixed(2)}'),
                                Text(
                                  category,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Created: $formattedDate',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) =>
                                  _handleServiceAction(value, service),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Text('View'),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
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

  Stream<QuerySnapshot> _getServiceStream() {
    Query query = FirebaseFirestore.instance.collection('services');

    // Apply category filter
    if (_categoryFilter != 'all') {
      query = query.where('category', isEqualTo: _categoryFilter);
    }

    return query.snapshots();
  }

  Future<void> _handleServiceAction(
      String action, DocumentSnapshot service) async {
    final data = service.data() as Map<String, dynamic>;
    final serviceName = data['serviceName'] ?? 'Service';

    switch (action) {
      case 'view':
        _showServiceDetails(service);
        break;
      case 'edit':
        _showEditServiceDialog(service);
        break;
      case 'delete':
        _confirmAction(
          context,
          'Delete Service',
          'Are you sure you want to delete "$serviceName"? This action cannot be undone.',
          () => _deleteService(service.id),
        );
        break;
    }
  }

  Future<void> _deleteService(String serviceId) async {
    try {
      // Delete service document
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .delete();

      // Delete associated bookings
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('serviceId', isEqualTo: serviceId)
          .get();
      for (var doc in bookingsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete associated reviews
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('serviceId', isEqualTo: serviceId)
          .get();
      for (var doc in reviewsSnapshot.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting service: $e')),
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

  void _showServiceDetails(DocumentSnapshot service) {
    final data = service.data() as Map<String, dynamic>;
    final serviceName = data['serviceName'] ?? 'Unnamed Service';
    final description = data['description'] ?? 'No description';
    final price = data['price'] ?? 0.0;
    final category = data['category'] ?? 'OTHERS & CUSTOM';
    final imageUrl = data['imageUrl'];
    // final venue360Url = data['venue360ImageUrl']; // Not used in this function
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final formattedDate = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt)
        : 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(serviceName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Description: $description'),
              const SizedBox(height: 8),
              Text('Price: \$${price.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Category: $category'),
              const SizedBox(height: 8),
              Text('Created: $formattedDate'),
              const SizedBox(height: 16),
              const Text(
                'Statistics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('serviceId', isEqualTo: service.id)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('Bookings: ${snapshot.data!.docs.length}');
                  }
                  return const Text('Bookings: 0');
                },
              ),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('reviews')
                    .where('serviceId', isEqualTo: service.id)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final reviews = snapshot.data!.docs;
                    double avgRating = 0;
                    if (reviews.isNotEmpty) {
                      double totalRating = 0;
                      for (var doc in reviews) {
                        totalRating +=
                            (doc.data() as Map<String, dynamic>)['rating'] ?? 0;
                      }
                      avgRating = totalRating / reviews.length;
                    }
                    return Text(
                        'Average Rating: ${avgRating.toStringAsFixed(1)} (${reviews.length} reviews)');
                  }
                  return const Text('Reviews: 0');
                },
              ),
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

  void _showEditServiceDialog(DocumentSnapshot service) {
    final data = service.data() as Map<String, dynamic>;
    final serviceNameController =
        TextEditingController(text: data['serviceName']);
    final descriptionController =
        TextEditingController(text: data['description']);
    final priceController =
        TextEditingController(text: data['price']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Service'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: serviceNameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('services')
                    .doc(service.id)
                    .update({
                  'serviceName': serviceNameController.text,
                  'description': descriptionController.text,
                  'price': double.tryParse(priceController.text) ?? 0.0,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating service: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}