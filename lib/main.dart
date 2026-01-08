import 'package:flutter/material.dart';
//import 'package:laundry_lens/admin/migration_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/home_locked.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'services/local_notification_service.dart';

import 'pages/onboarding.dart';

//import 'package:laundry_lens/services/firebase_service.dart';

import 'package:laundry_lens/pages/registration.dart';

import 'package:laundry_lens/pages/login.dart';

import 'package:laundry_lens/pages/index.dart';

import 'package:provider/provider.dart';

import 'package:laundry_lens/providers/machine_provider.dart';

import 'package:laundry_lens/pages/notifications_page.dart';

import 'package:laundry_lens/providers/notification_provider.dart';

import 'package:laundry_lens/providers/preferences_provider.dart';

import 'package:laundry_lens/pages/settings_page.dart';

import 'package:laundry_lens/providers/user_provider.dart';

import 'package:laundry_lens/pages/profil_page.dart';

import 'package:laundry_lens/pages/help_page.dart';

import 'package:laundry_lens/pages/forgot_password.dart';

Future<void> firebaseBackgroundHandler(RemoteMessage message) async {

  await Firebase.initializeApp();

  LocalNotificationService.showNotification(

    title: message.notification?.title ?? "Уведомление", // Перевод: "Уведомление" (Notification)

    body: message.notification?.body ?? "", // Перевод: "" (vide)

  );

}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

//print("🚀 Инициализация..."); // Перевод: "Инициализация..." (Initialization...)

  await Firebase.initializeApp();
  //await migrateMachines();
// 1️⃣ Инициализация локальных уведомлений // Initialisation des notifications locales

  await LocalNotificationService.initialize();
  await initFCM();
  await FirebaseMessaging.instance.subscribeToTopic("laundry_lens_test");

// Инициализация Alarm Manager // Initialiser Alarm Manager

  await AndroidAlarmManager.initialize();

// 2️⃣ Обработчик фоновых сообщений // Handler des messages en background

  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

// 3️⃣ Запрос разрешений (Android 13 / iOS) // Demander permission (Android 13 / iOS)

  await FirebaseMessaging.instance.requestPermission();

  //await syncMachinesToFirebase();

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override

  Widget build(BuildContext context) {

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {

      //print("🔥 Уведомление получено в foreground!"); // Перевод: "Уведомление получено в foreground!" (Notification received in foreground!)

      LocalNotificationService.showNotification(

        title: message.notification?.title ?? "Уведомление", // Перевод: "Уведомление" (Notification)

        body: message.notification?.body ?? "", // Перевод: "" (vide)

      );

    });

    return MultiProvider(

      providers: [

        ChangeNotifierProvider(

          create: (context) => MachineProvider(),

          lazy: false,

        ),

        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        ChangeNotifierProvider(

          create: (_) => PreferencesProvider()..loadPreferences(),

        ),

        ChangeNotifierProvider(create: (_) => UserProvider(), lazy: false),

      ],

      child: MaterialApp(

        debugShowCheckedModeBanner: false,

        home: const AuthWrapper(),

        routes: {

          OnboardingPage.id: (context) => OnboardingPage(),

          Login.id: (context) => Login(),

          Registration.id: (context) => Registration(),

          IndexPage.id: (context) => IndexPage(),

          NotificationsPage.id: (context) => NotificationsPage(),

          SettingsPage.id: (context) => SettingsPage(),

          ProfilePage.id: (context) => ProfilePage(),
          HomeLockedPage.id: (_) => const HomeLockedPage(),

          HelpPage.id: (context) => HelpPage(),

          ForgotPasswordPage.id: (context) => ForgotPasswordPage(),

        },

        theme: ThemeData(

          primaryColor: Color(0xFF459380),

          colorScheme: ColorScheme.fromSwatch(

            primarySwatch: Colors.green,

          ).copyWith(secondary: Colors.orange),

        ),

      ),

    );

  }

}

class AuthWrapper extends StatelessWidget {

  const AuthWrapper({super.key});

  @override

  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);



    if (userProvider.isLoading) {

      return Scaffold(

        backgroundColor: Color(0xFF459380),

        body: Center(

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              CircularProgressIndicator(

                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),

              ),

              SizedBox(height: 20),

              Text(

                'Загрузка...', // Перевод: "Загрузка..." (Chargement...)

                style: TextStyle(color: Colors.white, fontSize: 16),

              ),

            ],

          ),

        ),

      );

    }



    if (userProvider.isLoggedIn && userProvider.currentUser != null) {

      //print('✅ Пользователь вошел в систему: ${userProvider.currentUser!.email}'); // Перевод: "Пользователь вошел в систему" (Utilisateur connecté)

      WidgetsBinding.instance.addPostFrameCallback((_) {

        Navigator.pushReplacementNamed(context, IndexPage.id);

      });

      return const SizedBox();

    }



//print('ℹ️ Пользователь не вошел в систему'); // Перевод: "Пользователь не вошел в систему" (Aucun utilisateur connecté)

    return HomeLockedPage();

  }

}

Future<void> initFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Demande permission notification
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // S'abonner au topic (nom inchangé comme dans ton script)
  await FirebaseMessaging.instance.subscribeToTopic("laundry_lens_test");

}
