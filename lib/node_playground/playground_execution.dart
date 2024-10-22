import 'package:node_editor/node_editor.dart';
import 'package:attempt_two/device_list/websocket_manager/headers/websocket_datatypes.dart';

void nodeExecutor(String? command, String? uniqueId){
  //fetch device websocket
  print(uniqueId);
  print(command);
}

class PlaygroundExecutor {
  final WsDeviceList wsDeviceList;
  final WsMessageList wsMessageList;
  final NodeEditorController controller;

  PlaygroundExecutor({
    required this.wsDeviceList,
    required this.wsMessageList,
    required this.controller, // Add the controller as a required parameter
  });

  void execute() {
    print("ATYAYAYAYAY");
    // Example function where you can add logic
    // Use wsDeviceList, wsMessageList, and controller as needed
  }
}


// I think I need the _controller
// use the controller to create a tree-like structure for execution
// execute from the root to the leefs ;)