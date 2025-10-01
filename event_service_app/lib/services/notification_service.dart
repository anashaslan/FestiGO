import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Needs to be a top-level function to handle background messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp(); // Not needed if already done in main
  print('Handling a background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission from the user
    await _firebaseMessaging.requestPermission();

    // Get the FCM token for this device
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print('FCM Token: $fcmToken');
      // Save the token to the user's document in Firestore
      _saveTokenToDatabase(fcmToken);
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Here you could show a local notification using a package like
        // `flutter_local_notifications` to make sure the user sees it.
      }
    });
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
      } catch (e) {
        if (kDebugMode) {
          print('Could not save FCM token to database: $e');
        }
      }
    }
  }
}
