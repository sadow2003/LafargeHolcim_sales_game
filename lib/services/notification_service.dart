import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {


  NotificationService._();// Private constructor for singleton pattern


  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _notificationSubscription;

  // ── Initialization ────────────────────────────────────────────────────────
//for the notification on the phone
  Future<void> initialize() async {

    // Android initialization with default icon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

        // iOS initialization with permission requests
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        // Combine platform settings
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(initializationSettings);
  }



//for the notification on the application
  Future<void> init() async {
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);


    // Request permissions on iOS (no-op on Android)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // For debugging: print the permission status
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // On iOS, this controls whether notifications are shown when the app is in the foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await initialize();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);
  }

  // ── Token management ──────────────────────────────────────────────────────
  // Call this after the manager logs in to save their FCM token in Firestore
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

      _fcm.onTokenRefresh.listen((newToken) async {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[FCM] Token refreshed for ${user.uid}');
      });
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  // ── Local notification display ────────────────────────────────────────────


  // Shows a local notification on THIS device. Called from FCM handlers and Firestore listener.
  Future<void> showNotification({
    int id = 0,
    String title = 'Notification',
    String body = 'This is a notification message',
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          channelDescription: 'This is the default notification channel',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // ── FCM foreground / tap handlers ─────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.messageId}');
    // Show a local notification so the manager sees it even while in the app
    showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Sale Claim',
      body: message.notification?.body ?? '',
    );
  }

  void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.messageId}');
  }

  // ── Firestore listener — shows notification on THIS device ───────────────
  // Call this after the manager logs in so their device pops notifications
  // whenever a salesperson writes a new entry into the notifications collection.

  void startListeningForNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Only react to documents created from this moment forward
    final sessionStart = Timestamp.now();

    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('timestamp', isGreaterThan: sessionStart)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          showNotification(
            id: change.doc.id.hashCode,
            title: data['title'] ?? 'New Notification',
            body: data['body'] ?? '',
          );
        }
      }
    });

    debugPrint('[FCM] Listening for notifications for $uid');
  }

  void stopListeningForNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    debugPrint('[FCM] Stopped listening for notifications');
  }

  // ── Send sale-claim notification to all managers ──────────────────────────


  // Call this from the salesperson app when a new sale claim is submitted. It creates
  static Future<void> sendNewSaleClaimNotification({
    required String userName,
    required String productName,
    required int quantity,
    required String saleId,
  }) async {
    try {
      final managersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'sales-manager')
          .get();

      if (managersSnap.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final manager in managersSnap.docs) {
        final ref =
            FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(ref, {
          'userId': manager.id,
          'saleId': saleId,
          'title': 'New Sale Claim',
          'body':
              '$userName submitted ${quantity}x $productName.',
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint(
          '[FCM] Notifications sent to ${managersSnap.docs.length} manager(s)');
    } catch (e) {
      debugPrint('[FCM] Error sending sale claim notification: $e');
    }
  }
}
