import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_detail_screen.dart';

class CustomerBrowseServicesScreen extends StatefulWidget {
  const CustomerBrowseServicesScreen({super.key});

  @override
  _CustomerBrowseServicesScreenState createState() => _CustomerBrowseServicesScreenState();
}

class _CustomerBrowseServicesScreenState extends State<CustomerBrowseServicesScreen> {
  double _maxPrice = 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Browse Services')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('Max Price: \$${_maxPrice.toInt()}'),
                Expanded(
                  child: Slider(
                    value: _maxPrice,
                    min: 0,
                    max: 5000,
                    divisions: 50,
                    label: _maxPrice.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        _maxPrice = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .where('price', isLessThanOrEqualTo: _maxPrice)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final services = snapshot.data!.docs;

                if (services.isEmpty) {
                  return Center(child: Text('No services available.'));
                }

                return ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.all(10),
                      elevation: 3,
                      child: ListTile(
                        leading: (service['venue360Url'] != null && service['venue360Url'].isNotEmpty)
                            ? Image.network(service['venue360Url'], width: 70, height: 70, fit: BoxFit.cover)
                            : Icon(Icons.event),
                        title: Text(service['serviceName'] ?? 'No name'),
                        subtitle: Text('\$${service['price']?.toStringAsFixed(2) ?? '0.00'}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ServiceDetailScreen(serviceDoc: services[index])),
                          );
                        },
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
