import 'package:attempt_two/main_screen/device_list/websocket_manager/websocket_connection.dart';
import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import 'device_list/device_list.dart';
import 'node_playground/playground.dart';
import 'package:attempt_two/main_screen/communication_panel/communication_panel.dart';
import 'device_list/websocket_manager/headers/websocket_datatypes.dart';
import 'package:attempt_two/main_screen/node_playground/playground_execution.dart';

class MainScreen extends StatefulWidget {
  MainScreen({super.key, required this.title});

  final String title;

  final WsDeviceList wsDeviceList = WsDeviceList();
  final WsMessageList wsMessageList = WsMessageList();
  final NodeEditorController nodeController = NodeEditorController();

  @override
  State<MainScreen> createState() => _MainScreen();
}

class _MainScreen extends State<MainScreen> {
  late PlaygroundExecutor playgroundExecutor;
  late WebSocketController wsController;
  late DebugConsoleController debugConsoleController;

  @override
  void initState() {
    super.initState();

    wsController = WebSocketController(wsDeviceList: widget.wsDeviceList, wsMessageList: widget.wsMessageList);

    // Initialize PlaygroundExecutor
    playgroundExecutor = PlaygroundExecutor(
      wsDeviceList: widget.wsDeviceList,
      wsMessageList: widget.wsMessageList,
      wsController: wsController,
      controller: widget.nodeController,
    );



    debugConsoleController = DebugConsoleController();

    wsController.messageChangeNotifyFunction = debugConsoleController.addMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Get screen dimensions
          double screenHeight = constraints.maxHeight;
          double screenWidth = constraints.maxWidth;

          // Calculate height based on 9:16 ratio and width (1/4 of the screen width)
          double widgetHeight = screenHeight * 0.5;
          double widgetWidth = 200;

          // Calculate remaining width for the empty box
          double remainingWidth = screenWidth - widgetWidth - 20; // account for padding

          return Stack(
            children: [
              // DeviceScanner box with capped width
              Positioned(
                top: 10,
                left: 10,
                width: widgetWidth,
                height: widgetHeight,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromARGB(255, 208, 211, 204),
                  ),
                  child: DeviceScanner(
                    wsController: wsController,
                  ),
                ),
              ),
              // NodeEditorWidget with overlay button
              Positioned(
                top: 10,
                left: widgetWidth + 20,
                width: remainingWidth - 10,
                height: widgetHeight,
                child: Stack(
                  children: [
                    NodeEditorWidget(controller: widget.nodeController),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: ElevatedButton(
                        onPressed: () {
                          playgroundExecutor.execute();
                        },
                        child: const Text("Run"),
                      ),
                    ),
                  ],
                ),
              ),
              // Light gray box under the NodeEditorWidget with rounded edges and bottom padding
              Positioned(
                top: widgetHeight + 20,
                left: widgetWidth + 20,
                width: remainingWidth - 10,
                height: widgetHeight - 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DebugConsole(key: debugConsoleController.key, wsMessageList: widget.wsMessageList), // Embed the DebugConsole inside the gray box
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}