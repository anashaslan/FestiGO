import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an event in the application.
/// 
/// Contains all relevant information about an event including its unique ID,
/// title, description, date/time, location and organizer information.
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String organizerId;

  /// Creates a new Event instance.
  /// 
  /// All parameters are required and must not be null.
  const Event({
    required this.id,
    required this.title, 
    required this.description,
    required this.dateTime,
    required this.location,
    required this.organizerId,
  });

  /// Creates an Event instance from a Firestore document.
  /// 
  /// The document must contain the required fields: title, description,
  /// dateTime, location, and organizerId.
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Event(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'] as String? ?? '',
      organizerId: data['organizerId'] as String? ?? '',
    );
  }

  /// Converts the Event instance to a Map for Firestore storage.
  /// 
  /// The returned map contains all fields except the id, which is handled
  /// by Firestore's document ID.
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description, 
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'organizerId': organizerId,
    };
  }

  /// Creates a copy of this Event with the given fields replaced with new values.
  Event copyWith({
    String? id,
    String? title,
    String? description, 
    DateTime? dateTime,
    String? location,
    String? organizerId,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Event &&
    runtimeType == other.runtimeType &&
    id == other.id &&
    title == other.title &&
    description == other.description &&
    dateTime == other.dateTime &&
    location == other.location &&
    organizerId == other.organizerId;

  @override
  int get hashCode => 
    id.hashCode ^
    title.hashCode ^
    description.hashCode ^
    dateTime.hashCode ^
    location.hashCode ^
    organizerId.hashCode;

  @override
  String toString() => 'Event(id: $id, title: $title, dateTime: $dateTime)';
}