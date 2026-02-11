import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../model/notification_model.dart';

class NotificationService {
  static const String _key = "notifications";
  static final ValueNotifier<int> notificationCount = ValueNotifier<int>(0);


  // Charger les notifications au démarrage
  static Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notifs = prefs.getStringList(_key) ?? [];

    // Désérialiser en objets Notification (si tu stockes en JSON)
    final notifications = notifs
        .map((n) => NotificationItem.fromJson(jsonDecode(n)))
        .toList();

    // Nombre total
    notificationCount.value = notifications.length;

    // Nombre non lues
    final unreadCount = notifications.where((n) => !n.isRead).length;
  }


  /// Sauvegarde une notification
  static Future<void> saveNotification(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_key) ?? [];

    final notifData = {
      "ref" : const Uuid().v1(),
      "title": message.notification?.title ?? "Sans titre",
      "body": message.notification?.body ?? "Pas de contenu",
      "time": DateTime.now().toIso8601String(),
      "isRead": false
    };

    notifications.insert(0, jsonEncode(notifData));
    await prefs.setStringList(_key, notifications);

    await SharedPreferences.getInstance()
        .then((prefs) => prefs.getStringList('notifications') ?? []);

    // Mettre à jour le compteur en temps réel
    notificationCount.value = notifications.length;
  }

  /// Récupère toutes les notifications
  static Future<List> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList(_key) ?? [];
    return notifications.map((e) => jsonDecode(e)).toList();
  }
}
