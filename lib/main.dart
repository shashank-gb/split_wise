import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:split_wise/auth_services.dart';
import 'package:split_wise/firebase/firebase_service.dart';
import 'package:split_wise/firebase/expense_service.dart';
import 'package:split_wise/firebase/group_service.dart';
import 'package:split_wise/screens/google_sign_in_screen.dart';
import 'package:split_wise/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthService()
        ),
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
        Provider<ExpenseService>(
          create: (_) => ExpenseService(),
        ),
        Provider<GroupService>(
          create: (_) => GroupService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitWise App',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: Provider.of<AuthService>(context, listen: false).authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            return snapshot.hasData ? const HomeScreen() : const GoogleSignInScreen();
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}
