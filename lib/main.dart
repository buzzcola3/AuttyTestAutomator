import 'package:flutter/material.dart';
import 'main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainScreen(title: 'Yay:)',),
    );
  }
}

//todo: create file websocket_connection.dart where all of the connection stuff is handled
//      create ip_scanner.dart file.
//
//      +----+         +-----------+        +---------------------+
//      | App|         | IP Scanner| -----> | WebSocket Connection|
//      +----+         +-----------+        +---------------------+
//         |<------------------------------------------>|
