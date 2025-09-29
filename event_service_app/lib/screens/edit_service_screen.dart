import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditServiceScreen extends StatefulWidget {
  final DocumentSnapshot serviceDoc;

  const EditServiceScreen({super.key, required this.serviceDoc});

  @override
  _EditServiceScreenState createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _venue360Controller = TextEditingController();
  final _otherCategoryController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Photography/Videography',
    'Pelamin',
    'Bunga Telor',
    'Kad Jemputan',
    'Kompang',
    'Baju Pengantin',
    'Emcee',
    'Catering',
    'Others'
  ];
  late String _selectedCategory;
  bool _showOtherCategory = false;

  @override
  void initState() {
    super.initState();
    final data = widget.serviceDoc.data() as Map<String, dynamic>;
    _serviceNameController.text = data['serviceName'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _priceController.text = data['price']?.toString() ?? '';
    _venue360Controller.text = data['venue360Url'] ?? '';
    _selectedCategory = _categories.contains(data['category'])
        ? data['category']
        : 'Others';
    if (_selectedCategory == 'Others') {
      _otherCategoryController.text = data['category'] ?? '';
      _showOtherCategory = true;
    }
  }

  Future<void> updateService() async {
    if (_serviceNameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.serviceDoc.reference.update({
        'serviceName': _serviceNameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'venue360Url': _venue360Controller.text,
        'category': _selectedCategory == 'Others'
            ? _otherCategoryController.text
            : _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Service updated successfully')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating service: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Edit Service'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                  _showOtherCategory = newValue == 'Others';
                });
              },
            ),
            SizedBox(height: 16),
            if (_showOtherCategory) ...[
              TextField(
                controller: _otherCategoryController,
                decoration: InputDecoration(
                  labelText: 'Specify Category',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
            ],
            TextField(
              controller: _serviceNameController,
              decoration: InputDecoration(
                labelText: 'Service Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _venue360Controller,
              decoration: InputDecoration(
                labelText: 'Venue 360 Image URL (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            _isSubmitting
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: updateService,
                    child: Text('Update Service'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _venue360Controller.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }
}