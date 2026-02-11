import 'package:ASSOU/pages/auth/login_screen.dart';
import 'package:ASSOU/pages/feature/notification/service/notification_service.dart';
import 'package:ASSOU/pages/home/home.dart';
import 'package:ASSOU/pages/mes-bons/mes_bons.dart';
import 'package:ASSOU/pages/recompenses/recompense.dart';
import 'package:ASSOU/widgets/inactivity_tracker.dart';
import 'package:ASSOU/widgets/reward_celebration_overlay.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';
import 'package:ASSOU/providers/reward_provider.dart';

import 'theme/app_theme.dart';
import 'config/environment.dart';
import 'data/services/deep_link_payment_service.dart';
import 'firebase_options.dart';

// =======================================
// 🔔 Config plugin notifications locales
// =======================================
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: initSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

// Fonction asynchrone pour charger le compteur
Future<void> loadNotificationsCount() async {
  await NotificationService.loadNotifications();
}

// =======================================
// Handler pour notifications en background
// =======================================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // ⚠️ nécessaire en background
  await NotificationService.saveNotification(message);
  print("📩 [BG] Notification reçue: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Active l’affichage bord à bord
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Initialise Firebase et autres services
  await Environment.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initLocalNotifications();

  // Charger les notifications existantes
  await loadNotificationsCount();

  // Handler background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Si l’app est ouverte via une notif (terminated)
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    await NotificationService.saveNotification(initialMessage);
  }

  // Bloquer l’orientation en portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation
        .portraitDown, // facultatif si tu veux autoriser l’inversion
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RewardProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DeepLinkPaymentService _deepLinkService = DeepLinkPaymentService();

  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();

    // Init deep link service
    _deepLinkService.initializeDeepLinkListener();

    // Listen to milestone events from RewardProvider
    context.read<RewardProvider>().milestoneStream.listen((event) {
      RewardCelebrationOverlay.show(
        context: context,
        points: event.points,
        message: event.message,
      );
    });

    // Demander l'autorisation pour iOS
    _requestNotificationPermission();

    // =========================
    // Foreground notifications
    // =========================
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await NotificationService.saveNotification(message);

      // Rafraîchir les récompenses si c'est une notif de milestone ou badge
      final type = message.data['type'];
      if (type == 'milestone_reached' ||
          type == 'badge_unlocked' ||
          type == 'points_earned') {
        if (mounted) {
          context.read<RewardProvider>().refreshAll();
        }
      }

      // Afficher notif locale
      if (message.notification != null) {
        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          'default_channel', // id channel
          'Notifications', // nom du channel
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

        const NotificationDetails notifDetails =
            NotificationDetails(android: androidDetails);

        await flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification?.title,
          message.notification?.body,
          notifDetails,
        );
      }

      setState(() {}); // rafraîchir UI
    });

    // =========================
    // Notification cliquée
    // =========================
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await NotificationService.saveNotification(message);
      setState(() {});
    });
  }

  // Fonction pour demander la permission sur iOS
  Future<void> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notifications autorisées');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('Notifications provisoires');
    } else {
      print('Notifications refusées');
    }
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InactivityTracker(
      child: MaterialApp(
        title: 'ASSOU',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        routes: {
          "/home": (context) => const HomePage(),
          "/bons": (context) => const MesBonsPage(),
          "/recompenses": (context) => const RecompensesPage(),
        },
        home: LoginScreen(),
      ),
    );
  }
}
