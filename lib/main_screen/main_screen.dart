// Copyright 2025 Samuel Betak
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:Autty/main.dart';
import 'package:Autty/main_screen/device_list/node_generation/node_generator.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/communication_handler.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/websocket_manager.dart';
import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import 'device_list/device_list.dart';
import 'node_playground/playground.dart';
import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
import 'device_list/websocket_manager/headers/websocket_datatypes.dart';
import 'package:Autty/main_screen/node_playground/playground_execution.dart';
import 'package:Autty/main_screen/node_playground_file_manager/playground_file_manager.dart';
import 'package:Autty/main_screen/node_playground/playground_file_interface.dart';
import 'package:Autty/userdata_database.dart';

class MainScreen extends StatefulWidget {
  MainScreen({
    super.key,
  });

  final Map<String, RemoteDevice> wsDeviceList = {};
  final WsMessageList globalWsMessageList = WsMessageList();
  final NodeEditorController nodeController = NodeEditorController();
  final NodeEditorWidgetController nodeEditorWidgetController = NodeEditorWidgetController();
  final DebugConsoleController debugConsoleController = DebugConsoleController();

  @override
  State<MainScreen> createState() => _MainScreen();
}

class _MainScreen extends State<MainScreen> {
  late PlaygroundExecutor playgroundExecutor;
  late WebsocketManager websocketManager;
  late Map<String, NodeWithNotifiers> nodesDNA;
  late PlaygroundFileInterface playgroundFileInterface;
  late UserdataDatabase userdataDatabase;

  @override
  void initState() {
    super.initState();

    websocketManager = WebsocketManager();

    nodesDNA = {};
    
    playgroundExecutor = PlaygroundExecutor(
      wsDeviceList: widget.wsDeviceList,
      websocketManager: websocketManager,
      controller: widget.nodeController,
      nodesDNA: nodesDNA
    );

    playgroundFileInterface = PlaygroundFileInterface(widget.nodeController, nodesDNA, widget.nodeEditorWidgetController, playgroundExecutor);

    userdataDatabase = UserdataDatabase();


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
                    websocketManager: websocketManager,
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
                    child: JsonFileManager(playgroundFileInterface: playgroundFileInterface, userdataDatabase: userdataDatabase),
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
                      playgroundFileInterface: playgroundFileInterface,
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