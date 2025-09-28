import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Create new event
  Future<void> createEvent(Event event) async {
    await _firestore.collection('events').add(event.toFirestore());
  }

  // Get all events
  Stream<List<Event>> getEvents() {
    return _firestore
        .collection('events')
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .toList();
        });
  }

  // Get single event
  Future<Event?> getEvent(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    return doc.exists ? Event.fromFirestore(doc) : null;
  }

  // Update event
  Future<void> updateEvent(String eventId, Event event) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .update(event.toFirestore());
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }
}