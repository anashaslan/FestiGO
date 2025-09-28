import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../models/event.dart';

class EventsScreen extends StatelessWidget {
  final EventService _eventService = EventService();

  EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Events')),
      body: StreamBuilder<List<Event>>(
        stream: _eventService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                title: Text(event.title),
                subtitle: Text(event.description),
                trailing: Text(event.dateTime.toString()),
                onTap: () {
                  // Navigate to event details
                },
              );
            },
          );
        },
      ),
    );
  }
}