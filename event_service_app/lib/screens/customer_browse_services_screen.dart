import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_detail_screen.dart';

class CustomerBrowseServicesScreen extends StatefulWidget {
  const CustomerBrowseServicesScreen({super.key});

  @override
  _CustomerBrowseServicesScreenState createState() =>
      _CustomerBrowseServicesScreenState();
}

class _CustomerBrowseServicesScreenState
    extends State<CustomerBrowseServicesScreen> {
  double _maxPrice = 20000;
  String? _selectedCategory;
  String _searchQuery = '';
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Catering',
    'Photography',
    'Venue',
    'Entertainment',
    'Decoration',
    'Planning',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedCategory = null;
                        _maxPrice = 20000;
                        _selectedDate = null;
                      });
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Category Filter
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category ||
                      (category == 'All' && _selectedCategory == null);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedCategory = category == 'All' ? null : category;
                      });
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Price Filter
              Text('Max Price: RM${_maxPrice.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _maxPrice,
                min: 0,
                max: 20000,
                divisions: 100,
                label: 'RM${_maxPrice.toInt()}',
                onChanged: (value) {
                  setModalState(() {
                    _maxPrice = value;
                  });
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              
              // Date Filter
              const Text('Event Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setModalState(() {
                      _selectedDate = date;
                    });
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('services');

    // Apply price filter
    query = query.where('price', isLessThanOrEqualTo: _maxPrice);

    // Apply category filter
    if (_selectedCategory != null) {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  List<QueryDocumentSnapshot> _filterBySearch(List<QueryDocumentSnapshot> services) {
    if (_searchQuery.isEmpty) return services;
    
    return services.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final serviceName = (data['serviceName'] as String? ?? '').toLowerCase();
      final category = (data['category'] as String? ?? '').toLowerCase();
      final description = (data['description'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return serviceName.contains(query) ||
          category.contains(query) ||
          description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FestiGO'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar with Filter Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search services...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _showFilterModal,
                  child: const Icon(Icons.filter_list),
                ),
              ],
            ),
          ),

          // Active Filters Display
          if (_selectedCategory != null || _selectedDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedCategory != null)
                    Chip(
                      label: Text(_selectedCategory!),
                      onDeleted: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                      },
                    ),
                  if (_selectedDate != null)
                    Chip(
                      label: Text(
                          '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                      onDeleted: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                    ),
                ],
              ),
            ),

          // Services List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No services available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final services = _filterBySearch(snapshot.data!.docs);

                if (services.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No services match your search',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: services.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final service = services[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceDetailScreen(serviceDoc: services[index]),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Service Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: service['venue360Url'] != null &&
                                        (service['venue360Url'] as String).isNotEmpty
                                    ? Image.network(
                                        service['venue360Url'],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        child: Icon(
                                          Icons.event,
                                          size: 40,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              
                              // Service Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service['serviceName'] ?? 'Unnamed Service',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (service['category'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          service['category'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'RM ${service['price']?.toStringAsFixed(2) ?? '0.00'}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const Icon(Icons.chevron_right),
                            ],
                          ),
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
}
