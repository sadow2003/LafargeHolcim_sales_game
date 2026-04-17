// notification_service.dart — Firebase Cloud Messaging setup and helpers.
//
// Responsibilities:
//   1. Request notification permissions from the OS.
//   2. Get the FCM token and save it to the user's Firestore document so a
//      backend / Cloud Function can send targeted push notifications later.
//   3. Handle messages that arrive while the app is in the FOREGROUND
//      (show an in-app banner via SnackBar / overlay).
//   4. Handle taps on notifications that open the app from the background.
//
// NOTE ON BACKGROUND PUSH:
//   Sending a push notification TO a specific user requires a server-side
//   call to the FCM HTTP v1 API (using a service account).  Without Cloud
//   Functions or a custom backend the admin device cannot do this safely
//   (server keys must never be embedded in a client app).
//   → The approach used here is:
//       • Admin writes a document to the `notifications` Firestore collection.
//       • The salesperson app listens to that collection in real-time and
//         surfaces an in-app banner (foreground) or badge (on next open).
//       • The FCM token is stored so you can wire up Cloud Functions later.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Top-level handler required by FCM for background / terminated state messages.
// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this is called.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;

  // ── Initialise ─────────────────────────────────────────────────────────────
  // Call once from main() AFTER Firebase.initializeApp().
  Future<void> init() async {
    // Register the background handler.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (required on iOS; Android 13+ also needs this).
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // On iOS, show notifications even when the app is in the foreground.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages (app is open).
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Handle notification tap when app was in background (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // Handle notification tap when app was terminated.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);
  }

  // ── Save FCM Token ─────────────────────────────────────────────────────────
  // Call this after the user logs in so the token is linked to their account.
  Future<void> saveTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Token saved for ${user.uid}');

      // Refresh token whenever FCM rotates it.
      _fcm.onTokenRefresh.listen((newToken) async {
        final current = FirebaseAuth.instance.currentUser;
        if (current == null) return;
        await _firestore.collection('users').doc(current.uid).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[FCM] Token refreshed for ${current.uid}');
      });
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  // ── Foreground Message Handler ─────────────────────────────────────────────
  // Called when a push notification arrives while the app is open.
  // We just log it here; the UI layer shows the in-app banner via Firestore
  // stream (see _NotificationBell in home_page.dart).
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');
  }

  // ── Notification Tap Handler ───────────────────────────────────────────────
  void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    // Navigation could be added here once a global navigator key is wired up.
  }

  // ── Write a notification document (called by admin) ────────────────────────
  // Creates a document in the `notifications` collection that the recipient's
  // app will pick up in real-time via a Firestore stream.
  static Future<void> sendSaleStatusNotification({
    required String recipientUserId,
    required String saleId,
    required String productName,
    required String status, // 'approved' | 'rejected'
    int pointsAwarded = 0,
  }) async {
    final message = status == 'approved'
        ? 'Your sale of "$productName" was approved! You earned $pointsAwarded pts.'
        : 'Your sale of "$productName" was rejected.';

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId':      recipientUserId,
      'saleId':      saleId,
      'type':        'sale_status',
      'status':      status,
      'productName': productName,
      'pointsAwarded': pointsAwarded,
      'message':     message,
      'read':        false,
      'createdAt':   FieldValue.serverTimestamp(),
    });
  }
}
