import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import 'device_list/device_list.dart';
import 'node_playground/playground.dart';
import 'package:attempt_two/node_generation/node_generator.dart';
import 'device_list/websocket_manager/headers/websocket_datatypes.dart';
import 'package:attempt_two/node_playground/playground_execution.dart';

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

  @override
  void initState() {
    super.initState();

    // Initialize PlaygroundExecutor
    playgroundExecutor = PlaygroundExecutor(
      wsDeviceList: widget.wsDeviceList,
      wsMessageList: widget.wsMessageList,
      controller: widget.nodeController,
    );
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
          double widgetWidth = widgetHeight * (10 / 16);  // Height should follow the 10:16 ratio

          // Ensure it doesn't exceed 1/2 of the screen height
          if (widgetHeight > screenHeight * 0.5) {
            widgetHeight = screenHeight * 0.5;
          }

          // Calculate remaining width for the empty box
          double remainingWidth = screenWidth - widgetWidth - 20; // account for padding

          return Stack(
            children: [
              // DeviceScanner box
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
                    wsDeviceList: widget.wsDeviceList, // Pass wsDeviceList from widget
                    wsMessageList: widget.wsMessageList, // Pass wsMessageList from widget
                  ),
                ),
              ),
              // NodeBox added from separate file with non-normalized constraints
              Positioned(
                top: 10,
                left: widgetWidth + 20, // 10px padding on both sides
                width: remainingWidth - 10,
                height: widgetHeight,
                child: Stack(
                  children: [
                    NodeEditorWidget(controller: widget.nodeController),
                    // Overlay button to execute PlaygroundExecutor
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: ElevatedButton(
                        onPressed: () {
                          playgroundExecutor.execute(); // Call execute method
                        },
                        child: const Text("Run"),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 400,
                child: generatePreviewNode(nodeType: basicNode(isDummy: true)),
              ),
            ],
          );
        },
      ),
    );
  }
}
