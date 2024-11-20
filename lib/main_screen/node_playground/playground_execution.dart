import 'package:attempt_two/main_screen/communication_panel/communication_panel.dart';
import 'package:attempt_two/main_screen/device_list/internal_device.dart';
import 'package:attempt_two/main_screen/device_list/websocket_manager/websocket_manager.dart';
import 'package:node_editor/node_editor.dart';
import 'package:attempt_two/main_screen/device_list/websocket_manager/headers/websocket_datatypes.dart';

class ExecutableNode {
  // Members
  final String nodeUuid;
  final String command;
  final String deviceUniqueId;
  bool executed = false;
  late Map<String, dynamic> executionResult;
  final dynamic node; // Type can be changed to the specific type you're using
  
  late List inPortResults;
  

  // Constructor
  ExecutableNode({
    required this.nodeUuid,
    required this.node,
    required this.command,
    required this. deviceUniqueId,
    this.executed = false,
  });
}


class PlaygroundExecutor {
  final WsDeviceList wsDeviceList;
  final DebugConsoleController debugConsole;
  final WebsocketManager websocketManager;
  final NodeEditorController controller;
  final Map<String, dynamic> nodesDNA;

  PlaygroundExecutor({
    required this.wsDeviceList,
    required this.debugConsole,
    required this.websocketManager,
    required this.controller,
    required this.nodesDNA
  });

  bool executeSuccess = false;

  ExecutableNode? findStartNode(List<ExecutableNode> decodedList) {
    for (var node in decodedList) {
      if (node.deviceUniqueId == 'internal' && node.command == 'RUN') {
        return node;
      }
    }
    return null;
  }

  Future<bool> execute() async {
    print("Executing node chain");
    executeSuccess = true;

    // Decode the nodes using the controller
    List<ExecutableNode> playgroundNodes = decodeNodes(controller.nodes);

    // Find the start node with deviceUniqueId = "internal" and nodeCommand = "{RUN}"
    ExecutableNode? startNode = findStartNode(playgroundNodes);
    if (startNode == null) {
      print("No start node found.");
      return false;
    }
  
    Map<String, List<String>> nodeStructure = {};
    var execNodeTree = buildNodeConnectionStructure(startNode, controller.connections, nodeStructure);

    await executeNodeTree(execNodeTree, startNode.nodeUuid, playgroundNodes);

    return executeSuccess;
  }

  Future<void> executeNodeTree(Map<String, List<String>> execNodeTree, String startNode, List<ExecutableNode> playgroundNodes) async {
    if (dependentNodesAlreadyExecuted(startNode, execNodeTree, playgroundNodes)) {
      await executeNode(startNode, execNodeTree, playgroundNodes);
    } else {
      return;
    }

    for (var execNode in execNodeTree[startNode] ?? []) {
      await executeNodeTree(execNodeTree, execNode, playgroundNodes);
    }
  }

Future<void> executeNode(String node, Map<String, List<String>> execNodeTree, List<ExecutableNode> playgroundNodes) async {
  
  Map<String, dynamic> dependencyResult = dependentNodesResult(node, execNodeTree, playgroundNodes);


  for (var playgroundNode in playgroundNodes) {
    
    if (playgroundNode.nodeUuid == node) {

      List<String> parameters = [];
      if (nodesDNA[node] != null) {
        for (var parameter in nodesDNA[node]["nodeParameters"] ?? []) {
          parameters.add(parameter['Value']);
        }
      }
  
      Map<String, dynamic> result;
      controller.selectNodeAction(node); // highlight the node when executing
      if (nodesDNA[node]["deviceUniqueId"] != 'internal') {
        WsMessage? resultWsMessage = await websocketManager.sendAwaitedRequest(nodesDNA[node]["deviceUniqueId"], nodesDNA[node]["nodeCommand"], parameters);
        result = resultWsMessage?.response;
      } else {
        
        result = await internalDeviceCommandProcessor(nodesDNA[node]["nodeCommand"], parameters, dependencyResult);
        
      }

      playgroundNode.executionResult = result;

      if(result["OUTCOME"] == "ERROR"){
        debugConsole.addMessage("${result["RESPONSE"]} --> ${result["OUTCOME"]}", MessageType.error, ConsoleTab.execute);
        executeSuccess = false;
      }else{
        debugConsole.addMessage("${result["RESPONSE"]} --> ${result["OUTCOME"]}", MessageType.generic, ConsoleTab.execute);
      }
        
      playgroundNode.executed = true;
      return;
    }
  }

  print('Executed node: ${node}');
}


  Map<String, List<String>> buildNodeConnectionStructure(
    ExecutableNode startNode,
    List<dynamic> connections,
    Map<String, List<String>> nodeStructure,
  ) {
    if (!nodeStructure.containsKey(startNode.nodeUuid)) {
      nodeStructure[startNode.nodeUuid] = [];
    }

    List<ExecutableNode> connectedNodes = getOutPortNodes(startNode, connections);

    for (var connectedNode in connectedNodes) {
      nodeStructure[startNode.nodeUuid]!.add(connectedNode.nodeUuid);
      buildNodeConnectionStructure(connectedNode, connections, nodeStructure);
    }

    return nodeStructure;
  }

  List<ExecutableNode> getOutPortNodes(ExecutableNode node, List<dynamic> connections) {
    List<ExecutableNode> inNodes = [];

    for (var connection in connections) {
      if (connection.outNode.name == node.nodeUuid) {
        ExecutableNode execNode = ExecutableNode(nodeUuid: connection.inNode.name, node: connection.inNode, command: nodesDNA[node.nodeUuid]["nodeCommand"], deviceUniqueId: nodesDNA[node.nodeUuid]["deviceUniqueId"]);
        inNodes.add(execNode);
      }
    }

    return inNodes;
  }

  bool dependentNodesAlreadyExecuted(String node, Map<String, List<String>> execNodeTree, List<ExecutableNode> playgroundNodes){
    List<String> dependencies = [];

    execNodeTree.forEach((key, connectedNodes) {
      
      for (var connectedNode in connectedNodes) {

        if(connectedNode == node){
          dependencies.add(key);
        }
        
      }
    });

    if (dependencies.isEmpty) {
      return true;
    }

    for (var dependency in dependencies) {
      for (var playgroundNode in playgroundNodes) {
        if(playgroundNode.nodeUuid == dependency){
          if(!playgroundNode.executed){
            return false;
          }
        }
      }

    }

    return true;
  }

  Map<String, dynamic> dependentNodesResult(String node, Map<String, List<String>> execNodeTree, List<ExecutableNode> playgroundNodes){
    List<String> dependencies = [];

    execNodeTree.forEach((key, connectedNodes) {
      
      for (var connectedNode in connectedNodes) {

        if(connectedNode == node){
          dependencies.add(key);
        }
        
      }
    });

    if (dependencies.isEmpty) {
      return {};
    }

    for (var dependency in dependencies) {
      for (var playgroundNode in playgroundNodes) {
        if(playgroundNode.nodeUuid == dependency){
          
          return playgroundNode.executionResult;
          
        }
      }

    }

    return {};
  }

  List<ExecutableNode> decodeNodes(Map<String, dynamic> nodes) {
    List<ExecutableNode> decodedList = [];

    for (var key in nodes.keys) {
      try {
        ExecutableNode node = ExecutableNode(nodeUuid: key, node: nodes[key], command: nodesDNA[key]["nodeCommand"], deviceUniqueId: nodesDNA[key]["deviceUniqueId"]);
        decodedList.add(node);
      } catch (e) {
        print('Error decoding key: $key - $e');
      }
    }

    return decodedList;
  }
}