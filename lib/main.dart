//import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
//import 'package:flutter/material.dart';
//import 'main_screen/main_screen.dart';
//import 'package:Autty/alert_manager.dart';
//
//void main() {
//  WidgetsFlutterBinding.ensureInitialized();
//
//  runApp(const MyApp());
//}
//
//late final AlertDialogManager alertDialogManager;
//late final DebugConsoleController debugConsoleController;
//
//class MyApp extends StatelessWidget {
//  const MyApp({super.key});
//
//  @override
//  Widget build(BuildContext context) {
//    // AlertDialogManager must be instantiated where the context is available
//    alertDialogManager = AlertDialogManager(context);
//    debugConsoleController = DebugConsoleController();
//
//    return MaterialApp(
//      title: 'Flutter Demo',
//      theme: ThemeData(
//        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//        useMaterial3: true,
//        fontFamily: 'CascadiaCode',
//      ),
//      home: MainScreen(alertDialogManager: alertDialogManager, debugConsoleController: debugConsoleController),
//    );
//  }
//}

import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
import 'package:flutter/material.dart';
import 'main_screen/main_screen.dart';
import 'package:Autty/alert_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Global instances
late AlertDialogManager alertDialogManager;
late DebugConsoleController debugConsoleController;

// Global Navigator Key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'CascadiaCode',
      ),
      home: const InitApp(),
    );
  }
}

class InitApp extends StatefulWidget {
  const InitApp({super.key});

  @override
  State<InitApp> createState() => _InitAppState();
}

class _InitAppState extends State<InitApp> {
  @override
  void initState() {
    super.initState();

    // Initialize AlertDialogManager with the global navigator key
    alertDialogManager = AlertDialogManager(navigatorKey);
    debugConsoleController = DebugConsoleController();
  }

  @override
  Widget build(BuildContext context) {
    // Proceed to the main screen after initialization
    return MainScreen();
  }
}
