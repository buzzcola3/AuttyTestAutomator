import 'package:attempt_two/main_screen/device_list/websocket_manager/websocket_connection.dart';
import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import 'device_list/device_list.dart';
import 'node_playground/playground.dart';
import 'package:attempt_two/main_screen/communication_panel/communication_panel.dart';
import 'device_list/websocket_manager/headers/websocket_datatypes.dart';
import 'package:attempt_two/main_screen/node_playground/playground_execution.dart';
import 'package:attempt_two/main_screen/node_playground_file_manager/playground_file_manager.dart';
import 'package:attempt_two/main_screen/node_playground_file_manager/playground_save_and_load.dart';
import 'package:attempt_two/userdata_database.dart';

class MainScreen extends StatefulWidget {
  MainScreen({super.key, required this.title});

  final String title;

  final WsDeviceList wsDeviceList = WsDeviceList();
  final WsMessageList wsMessageList = WsMessageList();
  final NodeEditorController nodeController = NodeEditorController();
  final NodeEditorWidgetController nodeEditorWidgetController = NodeEditorWidgetController();

  @override
  State<MainScreen> createState() => _MainScreen();
}

class _MainScreen extends State<MainScreen> {
  late PlaygroundExecutor playgroundExecutor;
  late WebSocketController wsController;
  late Map<String, dynamic> nodesDNA;
  late DebugConsoleController debugConsoleController;
  late PlaygroundSaveLoad playgroundSaveLoad;
  late UserdataDatabase userdataDatabase;

  @override
  void initState() {
    super.initState();

    wsController = WebSocketController(
      wsDeviceList: widget.wsDeviceList,
      wsMessageList: widget.wsMessageList,
    );

    nodesDNA = {};
    
    playgroundExecutor = PlaygroundExecutor(
      wsDeviceList: widget.wsDeviceList,
      wsMessageList: widget.wsMessageList,
      wsController: wsController,
      controller: widget.nodeController,
      nodesDNA: nodesDNA
    );

    playgroundSaveLoad = PlaygroundSaveLoad(widget.nodeController, nodesDNA, widget.nodeEditorWidgetController, playgroundExecutor);

    userdataDatabase = UserdataDatabase();

    debugConsoleController = DebugConsoleController();

    wsController.messageChangeNotifyFunction = debugConsoleController.addMessage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenHeight = constraints.maxHeight;
          double screenWidth = constraints.maxWidth;

          double widgetHeight = screenHeight * 0.5;
          double widgetWidth = 200;

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
                    userdataDatabase: userdataDatabase
                  ),
                ),
              ),
              // Light gray box with rounded corners under DeviceScanner
              Positioned(
                top: widgetHeight + 20,
                left: 10,
                width: widgetWidth,
                height: widgetHeight - 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: JsonFileManager(playgroundSaveLoad: playgroundSaveLoad, userdataDatabase: userdataDatabase),
                  ),
                ),
              ),
              // NodeEditorWidget with overlay button
              Positioned(
                top: 10,
                left: widgetWidth + 20,
                width: screenWidth - widgetWidth - 30,
                height: widgetHeight,
                child: Stack(
                  children: [
                    NodeEditorWidget(
                      controller: widget.nodeController,
                      nodesDNA: nodesDNA,
                      customController: widget.nodeEditorWidgetController,
                    ),
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
                width: screenWidth - widgetWidth - 30,
                height: widgetHeight - 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DebugConsole(
                    key: debugConsoleController.key,
                    wsMessageList: widget.wsMessageList,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}