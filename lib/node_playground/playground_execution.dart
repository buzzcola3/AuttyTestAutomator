import 'package:node_editor/node_editor.dart';
import 'package:attempt_two/device_list/websocket_manager/headers/websocket_datatypes.dart';
import 'dart:convert';

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
    List<Map<String, dynamic>> playgroundNodes = decodeNodes(controller.nodes);

    //find startNode
    //loop:
    //  find outnodes
    //  execute
    
  }

  List<Map<String, dynamic>> decodeNodes(Map nodes) {
    List<Map<String, dynamic>> decodedList = [];
  
    for (var key in nodes.keys) {
      try {
        // Decode the key as JSON
        Map<String, dynamic> decodedKey = jsonDecode(key);
  
        // Create a new map that includes both the original key and its decoded content
        Map<String, dynamic> resultEntry = {
          'originalKey': key,
          'decodedKey': decodedKey,
        };
  
        decodedList.add(resultEntry);
      } catch (e) {
        print('Error decoding key: $key - $e');
      }
    }

    return decodedList;
}

  //getNodeOutNode
}

// I think I need the _controller
// use the controller to create a tree-like structure for execution
// execute from the root to the leefs ;)