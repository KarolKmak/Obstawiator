import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:obstawiator/main.dart' as main;

Future<void> requestWebNotificationPermission() async {
  // To samo dla Androida
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken();
    if (token != null) {
      if (kDebugMode) print('FCM Token (Native): $token');
      await _saveTokenToServer(token);
    }
  }
}

Future<void> _saveTokenToServer(String token) async {
  if (main.userID == null) return;
  
  final url = Uri.parse("https://obstawiator.pages.dev/API/UpdatePushToken");
  try {
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': main.sessionToken ?? '',
      },
      body: json.encode({
        "ID": main.userID,
        "sessionToken": main.sessionToken,
        "pushToken": token,
        "platform": kIsWeb ? "web" : "android"
      }),
    );
  } catch (e) {
    if (kDebugMode) print("Error saving push token: $e");
  }
}
