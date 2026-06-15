import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:obstawiator/main.dart' as main;

Future<void> syncPushToken() async {
  if (Firebase.apps.isEmpty) return;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Sprawdź aktualny status uprawnień
  NotificationSettings settings = await messaging.getNotificationSettings();
  
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken(
      vapidKey: "BF2SnAcL-3kXg6KTjm7lclrpmj8T11L8ShuK1WVLb0mXvPHlxR_x985pjYIUIJKVfi-krY0YwYsaAUAm6FSrZ9U"
    );
    if (token != null) {
      await _saveTokenToServer(token);
    }
  }
}

Future<void> requestWebNotificationPermission() async {
  if (Firebase.apps.isEmpty) return;
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    if (kDebugMode) print('User granted permission');
    await syncPushToken();
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
