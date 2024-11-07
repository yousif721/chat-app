import 'package:chattask/screens/home_screen.dart';
import 'package:chattask/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
    runApp(MyApp(errorMessage: "Error initializing Firebase"));
    return;
  }
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a message: ${message.notification?.title} - ${message.notification?.body}');
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String? errorMessage;

  MyApp({this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: errorMessage != null
          ? ErrorScreen(errorMessage: errorMessage!)
          : MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return HomeScreen();
          }
          return LoginScreen();
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String errorMessage;

  ErrorScreen({required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Error")),
      body: Center(
        child: Text(
          errorMessage,
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
      ),
    );
  }
}
