import 'package:Autty/global_datatypes/json.dart';
import 'package:Autty/main.dart';
import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
import 'package:Autty/main_screen/device_list/internal_device.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/websocket_manager.dart';
import 'package:Autty/main_screen/node_playground_file_manager/file_datatypes.dart';
import 'package:node_editor/node_editor.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/headers/websocket_datatypes.dart';

// ignore: constant_identifier_names
const bool _DEBUG_EXECUTOR = true;

class ExecutableNode {
  // Members
  final String nodeUuid;
  final String command;
  final String deviceUniqueId;
  bool executed = false;
  late Json executionResult;
  final dynamic node;
  
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
  final WebsocketManager websocketManager;
  final NodeEditorController controller;
  final Json nodesDNA;

  AuttyJsonFile? executingFile;

  PlaygroundExecutor({
    required this.wsDeviceList,
    required this.websocketManager,
    required this.controller,
    required this.nodesDNA
  });

  bool overallExecuteSuccess = false;

  int nodesExecuting = 0;

  ExecutableNode? _findStartNode(List<ExecutableNode> decodedList) {
    for (var node in decodedList) {
      if (node.deviceUniqueId == 'internal' && node.command == 'RUN') {
        return node;
      }
    }
    return null;
  }

  Future<bool> execute(AuttyJsonFile file) async {
    print("execstart");
    executingFile = file;

    debugConsoleController.addInternalTabMessage("Started execution", MessageType.info);
    debugConsoleController.clearTabMessages(ConsoleTab.execute);
    file.executionData = [];
    overallExecuteSuccess = true;

    // Decode the nodes using the controller
    List<ExecutableNode> playgroundNodes = _decodeNodes(controller.nodes);

    // Find the start node with deviceUniqueId = "internal" and nodeCommand = "{RUN}"
    ExecutableNode? startNode = _findStartNode(playgroundNodes);
    if (startNode == null) {
      debugConsoleController.addInternalTabMessage("No start node found.", MessageType.error);
      return false;
    }
  
    Map<String, List<String>> nodeStructure = {};
    var execNodeTree = _buildNodeConnectionStructure(startNode, controller.connections, nodeStructure);

    await _executeNodeTree(execNodeTree, startNode.nodeUuid, playgroundNodes);

    print("execdone");

    return overallExecuteSuccess;
  }

Future<void> _executeNodeTree(Map<String, List<String>> execNodeTree, String startNode, List<ExecutableNode> playgroundNodes) async {
  if (_dependentNodesAlreadyExecuted(startNode, execNodeTree, playgroundNodes)) {
    await _executeNode(startNode, execNodeTree, playgroundNodes);
  } else {
    return; // Dependency not ready, return early
  }

  // Collect futures from recursive calls
  List<Future<void>> futures = [];
  for (var execNode in execNodeTree[startNode] ?? []) {
    futures.add(_executeNodeTree(execNodeTree, execNode, playgroundNodes));
  }

  // Wait for all recursive calls to complete
  await Future.wait(futures);
}

Future<void> _executeNode(String node, Map<String, List<String>> execNodeTree, List<ExecutableNode> playgroundNodes) async {
  
  Json dependencyResult = _dependentNodesResult(node, execNodeTree, playgroundNodes);


  for (var playgroundNode in playgroundNodes) {

    if (playgroundNode.nodeUuid == node) {
      if(playgroundNode.executed) return;

      List<String> parameters = [];
      if (nodesDNA[node] != null) {
        for (var parameter in nodesDNA[node]["nodeParameters"] ?? []) {
          parameters.add(parameter['Value']);
        }
      }
  
      Json result;
      controller.selectNodeAction(node); // highlight the node when executing
      if (nodesDNA[node]["deviceUniqueId"] != 'internal') {
        WsMessage? resultWsMessage = await websocketManager.sendAwaitedRequest(nodesDNA[node]["deviceUniqueId"], nodesDNA[node]["nodeCommand"], parameters);
        result = resultWsMessage?.response;
      } else {
        
        result = await internalDeviceCommandProcessor(nodesDNA[node]["nodeCommand"], parameters, dependencyResult);
        
      }

      playgroundNode.executionResult = result;

      if(result["OUTCOME"] == "ERROR") overallExecuteSuccess = false;


      playgroundNode.executed = true;

      final resultNode = playgroundNode.nodeUuid;
      final resultMessage = "${result["RESPONSE"]} --> ${result["OUTCOME"]}";
      MessageType resultMessageType = MessageType.error;

      if(result["OUTCOME"] == "SUCCESS") resultMessageType = MessageType.generic;
      
      debugConsoleController.addExecutionTabMessage(resultMessage, resultNode, resultMessageType, controller.selectNodeAction);
      executingFile?.addExecuteData(resultMessage, resultNode, resultMessageType);
        
      
      return;
    }
  }

  if(_DEBUG_EXECUTOR) debugConsoleController.addInternalTabMessage("", MessageType.info);
}


  Map<String, List<String>> _buildNodeConnectionStructure(
    ExecutableNode startNode,
    List<dynamic> connections,
    Map<String, List<String>> nodeStructure,
  ) {
    if (!nodeStructure.containsKey(startNode.nodeUuid)) {
      nodeStructure[startNode.nodeUuid] = [];
    }

    List<ExecutableNode> connectedNodes = _getOutPortNodes(startNode, connections);

    for (var connectedNode in connectedNodes) {
      nodeStructure[startNode.nodeUuid]!.add(connectedNode.nodeUuid);
      _buildNodeConnectionStructure(connectedNode, connections, nodeStructure);
    }

    return nodeStructure;
  }

  List<ExecutableNode> _getOutPortNodes(ExecutableNode node, List<dynamic> connections) {
    List<ExecutableNode> inNodes = [];

    for (var connection in connections) {
      if (connection.outNode.name == node.nodeUuid) {
        ExecutableNode execNode = ExecutableNode(nodeUuid: connection.inNode.name, node: connection.inNode, command: nodesDNA[node.nodeUuid]["nodeCommand"], deviceUniqueId: nodesDNA[node.nodeUuid]["deviceUniqueId"]);
        inNodes.add(execNode);
      }
    }

    return inNodes;
  }

  bool _dependentNodesAlreadyExecuted(String node, Map<String, List<String>> execNodeTree, List<ExecutableNode> playgroundNodes){
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

  Json _dependentNodesResult(String node, Map<String, List<String>> execNodeTree, List<ExecutableNode> playgroundNodes){
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

  List<ExecutableNode> _decodeNodes(Json nodes) {
    List<ExecutableNode> decodedList = [];

    for (var key in nodes.keys) {
      try {
        ExecutableNode node = ExecutableNode(nodeUuid: key, node: nodes[key], command: nodesDNA[key]["nodeCommand"], deviceUniqueId: nodesDNA[key]["deviceUniqueId"]);
        decodedList.add(node);
      } catch (e) {
        if(_DEBUG_EXECUTOR) debugConsoleController.addInternalTabMessage("Error decoding key: $key - $e", MessageType.info);
      }
    }

    return decodedList;
  }
}