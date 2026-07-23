import 'dart:async';//imports Dart's built-in async library, provides future stream timer completed
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';// import flutter local notification  which lets your app show local notifications on the device (without needing a server/internet).

@pragma('vm:entry-point')//tells dart to not delete this forgeing code
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {


  NotificationService._();// Private constructor for singleton pattern


  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;//firebase cloud messaging instance
  final _firestore = FirebaseFirestore.instance;//firestore instance

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _notificationSubscription;//firebase listener subscription for notifications collection
  StreamSubscription<String>? _tokenRefreshSubscription;//token refresh listener — must be replaced on every login so it never writes to a previous user's doc

  // ── Initialization ────────────────────────────────────────────────────────
//for the notification on the phone
  Future<void> initialize() async {

    // Android initialization with default icon
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    //     // iOS initialization with permission requests
    // const DarwinInitializationSettings iosSettings =
    //     DarwinInitializationSettings(
    //       requestAlertPermission: true,
    //       requestBadgePermission: true,
    //       requestSoundPermission: true,
    //     );
        // Combine platform settings
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initializationSettings);
  }



//for the notification on the application
  Future<void> init() async {
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);


    // Request permissions on iOS (no-op on Android)
    // final settings = await _fcm.requestPermission(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    // For debugging: print the permission status
    // debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // On iOS, this controls whether notifications are shown when the app is in the foreground
    // await _fcm.setForegroundNotificationPresentationOptions(
    //   alert: true,
    //   badge: true,
    //   sound: true,
    // );

    //initialize the local notifications plugin
    await initialize();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);// handle messages received while tha app is in the foreground
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);// handle taps on the notification when the app is in the background or terminated


    //check if the app is still opened from a motification tap 
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);
  }

  // ── Token management ──────────────────────────────────────────────────────

  Future<void> clearTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Stop refreshing the token for a user who is logging out.
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    try {
      // Firestore writes only complete on server ack — the timeout keeps
      // logout from hanging forever on a flaky connection.
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      }).timeout(const Duration(seconds: 5));
      debugPrint('[FCM] Token cleared for ${user.uid}');
    } catch (e) {
      debugPrint('[FCM] Error clearing token: $e');
    }
  }




  // Call this after the manager logs in to save their FCM token in Firestore
  Future<void> saveTokenForCurrentUser() async {
    //get the current user, if not logged in return
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    //get the FCM token for this device and save it in the user's Firestore Document
    try {
      // getToken can hang indefinitely on some Android devices.
      final token =
          await _fcm.getToken().timeout(const Duration(seconds: 10));
      if (token == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      debugPrint('[FCM] Token saved for ${user.uid}');

      // Replace any listener left over from a previous login — otherwise it
      // keeps writing refreshed tokens to the previous user's document.
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) async {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('[FCM] Token refreshed for ${user.uid}');
        } catch (e) {
          debugPrint('[FCM] Error saving refreshed token: $e');
        }
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
    // define platform-specific details for the notification 
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          channelDescription: 'This is the default notification channel',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

        //ios details to show alert,badge and sound when the notification is received
    // const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    //   presentAlert: true,
    //   presentBadge: true,
    //   presentSound: true,
    // );

    //combine platform details into a single object
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      // iOS: iosDetails,
    );

    //show the notification using the plugin
    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }

  //Cancels a  specific notification by its id, 
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
  //cancel all nofifications shown by the app
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // ── FCM foreground / tap handlers ─────────────────────────────────────────

  //called when a message is received while the app is in the foreground
  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.messageId}');
    // Show a local notification so the manager sees it even while in the app
    showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Sale Claim',
      body: message.notification?.body ?? '',
    );
  }

  //called when the user taps on the notification while the app is in the background or terminated
  void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.messageId}');
  }

  // ── Firestore listener — shows notification on THIS device ───────────────
  // Call this after the manager logs in so their device pops notifications
  // whenever a salesperson writes a new entry into the notifications collection.


//this is needed because FCM does not guarantee delivery of the message if the app is in the foreground
  void startListeningForNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Only react to documents created from this moment forward
    final sessionStart = Timestamp.now();

    //collection listener that listens to new documents added to notification collection
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('timestamp', isGreaterThan: sessionStart)
        .snapshots()
        .listen((snapshot) {

          //for each document change in the snapshot
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
    }, onError: (e) {
      // Without this handler a query failure (e.g. missing Firestore index)
      // becomes an unhandled async error.
      debugPrint('[FCM] Notification listener error: $e');
    });

    debugPrint('[FCM] Listening for notifications for $uid');
  }
 //cancel the listener when the manager logs out to avoid memory leaks
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

  // ── Send sale-claim decision notification to the salesperson ──────────────

  // Call this from the manager app after a sale claim is approved or rejected.
  static Future<void> sendSaleClaimDecisionNotification({
    required String userId,
    required String productName,
    required int quantity,
    required String saleId,
    required bool approved,
    int pointsAwarded = 0,
  }) async {
    try {
      final title = approved ? 'Sale Approved' : 'Sale Rejected';
      final body = approved
          ? 'Your claim for ${quantity}x $productName was approved. +$pointsAwarded points!'
          : 'Your claim for ${quantity}x $productName was rejected.';

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'saleId': saleId,
        'title': title,
        'body': body,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Decision notification sent to $userId');
    } catch (e) {
      debugPrint('[FCM] Error sending sale decision notification: $e');
    }
  }
}
