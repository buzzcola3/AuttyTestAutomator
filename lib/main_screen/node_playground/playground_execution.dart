import 'package:attempt_two/main_screen/device_list/websocket_manager/websocket_connection.dart';
import 'package:node_editor/node_editor.dart';
import 'package:attempt_two/main_screen/device_list/websocket_manager/headers/websocket_datatypes.dart';
import 'dart:convert';

class ExecutableNode {
  // Members
  final String name;
  late String command;
  late String deviceUniqueId;
  bool executed = false;
  late Map<String, dynamic> executionResult;
  final dynamic node; // Type can be changed to the specific type you're using
  
  late List inPortResults;
  

  // Constructor
  ExecutableNode({
    required this.name,
    required this.node,
    this.executed = false,
  }) {

    Map<String, dynamic> decodedKey = jsonDecode(name);
    command = decodedKey['nodeCommand'];
    deviceUniqueId = decodedKey['deviceUniqueId'];
  }
}


class PlaygroundExecutor {
  final WsDeviceList wsDeviceList;
  final WsMessageList wsMessageList;
  final WebSocketController wsController;
  final NodeEditorController controller;

  PlaygroundExecutor({
    required this.wsDeviceList,
    required this.wsMessageList,
    required this.wsController,
    required this.controller,
  });

  ExecutableNode? findStartNode(List<ExecutableNode> decodedList) {
    for (var node in decodedList) {
      if (node.deviceUniqueId == 'internal' && node.command == '{RUN}') {
        return node;
      }
    }
    return null;
  }

  void execute() {
    print("Executing node chain");

    // Decode the nodes using the controller
    List<ExecutableNode> playgroundNodes = decodeNodes(controller.nodes);

    // Find the start node with deviceUniqueId = "internal" and nodeCommand = "{RUN}"
    ExecutableNode? startNode = findStartNode(playgroundNodes);
    if (startNode == null) {
      print("No start node found.");
      return;
    }
  
    Map<String, List<ExecutableNode>> nodeStructure = {};
    final execNodeTree = buildNodeConnectionStructure(startNode, controller.connections, nodeStructure);

    executeNodeTree(execNodeTree, startNode, playgroundNodes);
  }

  void executeNodeTree(Map<String, List<ExecutableNode>> execNodeTree, ExecutableNode startNode, List<ExecutableNode> playgroundNodes) {
    if (dependentNodesAlreadyExecuted(startNode, execNodeTree, playgroundNodes)) {
      executeNode(startNode, playgroundNodes);
    } else {
      return;
    }

    for (var execNode in execNodeTree[startNode.name] ?? []) {
      executeNodeTree(execNodeTree, execNode, playgroundNodes);
    }
  }

  void executeNode(ExecutableNode node, List<ExecutableNode> playgroundNodes) {
    for (var playgroundNode in playgroundNodes) {
      if(playgroundNode.name == node.name){

        if(node.deviceUniqueId != 'internal'){
          final deviceIp = wsController.getDeviceIp(node.deviceUniqueId);
          wsController.awaitRequest(deviceIp!, node.command);
        }
        //TODO execute internal
        playgroundNode.executed = true;
      }
    }

    print('Executed ${node.name}');
  }

  Map<String, List<ExecutableNode>> buildNodeConnectionStructure(
    ExecutableNode startNode,
    List<dynamic> connections,
    Map<String, List<ExecutableNode>> nodeStructure,
  ) {
    if (!nodeStructure.containsKey(startNode.name)) {
      nodeStructure[startNode.name] = [];
    }

    List<ExecutableNode> connectedNodes = getOutPortNodes(startNode, connections);

    for (var connectedNode in connectedNodes) {
      if (!nodeStructure[startNode.name]!.contains(connectedNode)) {
        nodeStructure[startNode.name]!.add(connectedNode);
        buildNodeConnectionStructure(connectedNode, connections, nodeStructure);
      }
    }

    return nodeStructure;
  }

  List<ExecutableNode> getOutPortNodes(ExecutableNode node, List<dynamic> connections) {
    List<ExecutableNode> inNodes = [];

    for (var connection in connections) {
      if (connection.outNode.name == node.name) {
        ExecutableNode execNode = ExecutableNode(name: connection.inNode.name, node: connection.inNode);
        inNodes.add(execNode);
      }
    }

    return inNodes;
  }

  bool dependentNodesAlreadyExecuted(ExecutableNode node, Map<String, List<ExecutableNode>> execNodeTree, List<ExecutableNode> playgroundNodes){
    List<String> dependencies = [];

    execNodeTree.forEach((key, connectedNodes) {
      
      for (var connectedNode in connectedNodes) {

        if(connectedNode.name == node.name){
          dependencies.add(key);
        }
        
      }
    });

    if (dependencies.isEmpty) {
      return true;
    }

    for (var dependency in dependencies) {
      for (var playgroundNode in playgroundNodes) {
        if(playgroundNode.name == dependency){
          if(!playgroundNode.executed){
            return false;
          }
        }
      }

    }

    return true;
  }

  List<ExecutableNode> decodeNodes(Map<String, dynamic> nodes) {
    List<ExecutableNode> decodedList = [];

    for (var key in nodes.keys) {
      try {
        ExecutableNode node = ExecutableNode(name: key, node: nodes[key]);
        decodedList.add(node);
      } catch (e) {
        print('Error decoding key: $key - $e');
      }
    }

    return decodedList;
  }
}