import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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

  
  XFile? _serviceImage;
  XFile? _venue360Image;
  String? _currentServiceImageUrl;
  String? _currentVenue360ImageUrl;
  
  bool _isSubmitting = false;

  final List<String> _categories = [
    'COMMUNITY AND PUBLIC',
    'CORPORATE & BUSINESS',
    'EDUCATION & SCHOOL',
    'ENTERTAINMENT & STAGES',
    'PERSONAL & FAMILY',
    'OTHERS & CUSTOM'
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
    _currentServiceImageUrl = data['imageUrl'];
    _currentVenue360ImageUrl = data['venue360ImageUrl'];
    _selectedCategory = _categories.contains(data['category'])
        ? data['category']
        : 'OTHERS & CUSTOM';
    // No special handling needed for the new categories
  }

  Future<void> _pickServiceImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _serviceImage = pickedFile;
      });
    }
  }

  Future<void> _pickVenue360Image() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _venue360Image = pickedFile;
      });
    }
  }

  Future<String?> _uploadImage(XFile image, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null;
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('User not logged in')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? serviceImageUrl = _currentServiceImageUrl;
      String? venue360ImageUrl = _currentVenue360ImageUrl;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final uploadTasks = <Future<String?>>[];
      if (_serviceImage != null) {
        uploadTasks.add(_uploadImage(_serviceImage!, 'services/${user.uid}/${timestamp}_service.jpg'));
      }
      if (_venue360Image != null) {
        uploadTasks.add(_uploadImage(_venue360Image!, 'services/${user.uid}/${timestamp}_360.jpg'));
      }

      if (uploadTasks.isNotEmpty) {
        final results = await Future.wait(uploadTasks);
        int index = 0;
        if (_serviceImage != null) {
          serviceImageUrl = results[index++];
        }
        if (_venue360Image != null) {
          venue360ImageUrl = results[index++];
        }
      }

      await widget.serviceDoc.reference.update({
        'serviceName': _serviceNameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'imageUrl': serviceImageUrl,
        'venue360ImageUrl': venue360ImageUrl,
        'category': _selectedCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Service updated successfully')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
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
                  _showOtherCategory = false;
                });
              },
            ),
            SizedBox(height: 16),

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
            Text('Service Image (Optional)'),
            SizedBox(height: 5),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickServiceImage,
                  child: Text('Pick Service Image'),
                ),
                SizedBox(width: 10),
                if (_serviceImage != null)
                  Expanded(
                    child: Text(
                      _serviceImage!.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (_serviceImage != null) ...[
              SizedBox(height: 10),
              Image.file(
                File(_serviceImage!.path),
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ],
            if (_currentServiceImageUrl != null && _serviceImage == null) ...[
              SizedBox(height: 10),
              Text('Current Service Image:'),
              SizedBox(height: 5),
              Image.network(
                _currentServiceImageUrl!,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ],
            SizedBox(height: 16),
            Text('Venue 360 Image (Optional)'),
            SizedBox(height: 5),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickVenue360Image,
                  child: Text('Pick 360 Image'),
                ),
                SizedBox(width: 10),
                if (_venue360Image != null)
                  Expanded(
                    child: Text(
                      _venue360Image!.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (_venue360Image != null) ...[
              SizedBox(height: 10),
              Image.file(
                File(_venue360Image!.path),
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ],
            if (_currentVenue360ImageUrl != null && _venue360Image == null) ...[
              SizedBox(height: 10),
              Text('Current 360 Image:'),
              SizedBox(height: 5),
              Image.network(
                _currentVenue360ImageUrl!,
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ],
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

    super.dispose();
  }
}