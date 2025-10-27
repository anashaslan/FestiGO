import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/global_navigator.dart';
import '../screens/customer_home.dart';
import '../screens/vendor_booking_detail_screen.dart';

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
  static final navigatorKey = GlobalNavigator.navigatorKey;

  Future<void> initNotifications() async {
    // 1. Request permission from the user
    await _firebaseMessaging.requestPermission();

    // 2. THIS IS THE FIX: On iOS, explicitly get the APNS token first.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _firebaseMessaging.getAPNSToken();
    }

    // 3. Now that we've waited for the APNS token on iOS, it is safe to get the FCM token.
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print('FCM Token: $fcmToken');
      // Save the token to the user's document in Firestore
      _saveTokenToDatabase(fcmToken);
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Set up message handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _setupInteractedMessage();
    _handleForegroundMessages();
  }

  /// Handles messages that are received while the app is in the foreground.
  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      final notification = message.notification;
      if (notification != null && navigatorKey.currentContext != null) {
        showDialog(
          context: navigatorKey.currentContext!,
          builder: (_) => AlertDialog(
            title: Text(notification.title ?? 'New Notification'),
            content: Text(notification.body ?? ''),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(navigatorKey.currentContext!).pop();
                  // Optionally navigate when the dialog is tapped
                  _handleNotificationNavigation(message.data);
                },
                child: const Text('Open'),
              ),
              TextButton(
                onPressed: () => Navigator.of(navigatorKey.currentContext!).pop(),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
      }
    });
  }

  /// Handles notification taps when the app is in the background or terminated.
  void _setupInteractedMessage() async {
    // Get any message which caused the application to open from a terminated state.
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage.data);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationNavigation(message.data);
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

/// Navigate to the correct screen based on the notification data.
void _handleNotificationNavigation(Map<String, dynamic> data) {
  final String? type = data['type'];
  if (type == null) return;

  final navigator = GlobalNavigator.navigatorKey.currentState;
  if (navigator == null) return;

  if (type == 'booking_update') {
    // Navigate to CustomerHomeScreen and ensure the 'My Bookings' tab is selected.
    // The `CustomerHomeScreen` needs to be adapted for this.
    navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CustomerHomeScreen(initialTabIndex: 1)),
        (route) => false);
  } else if (type == 'new_booking') {
    final String? bookingId = data['bookingId'];
    if (bookingId != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => VendorBookingDetailScreen(bookingId: bookingId),
        ),
      );
    }
  }
}