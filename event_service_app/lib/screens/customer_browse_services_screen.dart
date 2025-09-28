import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerBrowseServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Browse Services')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('services').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final services = snapshot.data!.docs;

          if (services.isEmpty) {
            return Center(child: Text('No services available'));
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(10),
                elevation: 3,
                child: ListTile(
                  title: Text(service['serviceName'] ?? 'No name'),
                  subtitle: Text('\$${service['price']?.toStringAsFixed(2) ?? '0.00'}'),
                  trailing: service['venue360Url'] != null && service['venue360Url'].isNotEmpty
                      ? Icon(Icons.photo_camera)
                      : null,
                  onTap: () {
                    // TODO: Navigate to service details with 360 viewer or booking
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
