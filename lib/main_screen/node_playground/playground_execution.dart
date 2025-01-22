import 'package:Autty/global_datatypes/device_info.dart';
import 'package:Autty/global_datatypes/json.dart';
import 'package:Autty/main.dart';
import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
import 'package:Autty/main_screen/device_list/internal_device.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/communication_handler.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/websocket_manager.dart';
import 'package:Autty/main_screen/node_playground_file_manager/file_datatypes.dart';
import 'package:node_editor/node_editor.dart';

// ignore: constant_identifier_names
const bool _DEBUG_EXECUTOR = true;

enum ExecutionState {
  pending,
  executing,
  finished
}
enum ExecutionResult {
  success,
  failure,
  unknown
}
class ExecutableNode {
  // Members
  final String nodeUuid;
  final String deviceUniqueId;

  ExecutionState state = ExecutionState.pending;
  ExecutionResult result = ExecutionResult.unknown;
  dynamic resultValue;

  // Constructor
  ExecutableNode({
    required this.nodeUuid,
    required this.deviceUniqueId,
  });
}

class PlaygroundExecutor {
  final Map<String, RemoteDevice> wsDeviceList;
  final WebsocketManager websocketManager;
  final NodeEditorController controller;
  final Json nodesDNA;

  List<ExecutableNode> unexecutedNodes = [];
  List<ExecutableNode> executedNodes = [];
  Map<String, ExecutableNode> allNodes = {};
  ExecutableNode? startNode;

  AuttyJsonFile? executingFile;

  PlaygroundExecutor(
      {
        required this.wsDeviceList,
        required this.websocketManager,
        required this.controller,
        required this.nodesDNA
      }
    );

  ExecutableNode? _findStartNode(List<ExecutableNode> decodedList) {
    for (var node in decodedList) {
      if (node.deviceUniqueId == 'internal' && nodesDNA[node.nodeUuid].nodeFunction.command == 'RUN') {
        return node;
      }
    }
    return null;
  }

  Future<bool> execute(AuttyJsonFile file) async {
    unexecutedNodes = [];
    executedNodes = [];
    allNodes = {};

    executingFile = file;

    debugConsoleController.addInternalTabMessage(
        "Started execution", MessageType.info);
    debugConsoleController.clearTabMessages(ConsoleTab.execute);
    file.executionData = [];

    // Decode the nodes using the controller
    List<ExecutableNode> playgroundNodes = _decodeNodes(controller.nodes);

    // Find the start node with deviceUniqueId = "internal" and nodeCommand = "{RUN}"
    startNode = _findStartNode(playgroundNodes);
    if (startNode == null) {
      debugConsoleController.addInternalTabMessage(
          "No start node found.", MessageType.error);
      return false;
    }

    unexecutedNodes = _getRelevantNodes(playgroundNodes, controller.connections, startNode!);
    for (var node in unexecutedNodes) {
      allNodes[node.nodeUuid] = node;
    }

    return _execute();
  }

  bool _execute(){
    if (unexecutedNodes.isEmpty) {
      debugConsoleController.addInternalTabMessage(
          "No nodes to execute.", MessageType.error);
      return false;
    }

    // Execute the start node
    _executeNode(startNode!.nodeUuid);
    unexecutedNodes.remove(startNode);
    executedNodes.add(startNode!);

    // Execute the rest of the nodes
    while (unexecutedNodes.isNotEmpty) {
      List<ExecutableNode> nodesToExecute = [];
      for (var node in unexecutedNodes) {
        if (_dependentNodesAlreadyExecuted(
            node.nodeUuid)) {
          nodesToExecute.add(node);
        }
      }

      for (var node in nodesToExecute) {
        _executeNode(node.nodeUuid);
        unexecutedNodes.remove(node);
        //add only if not there already
        if (!executedNodes.contains(node)) executedNodes.add(node);
      }
    }

    return true;

  }

  List<ExecutableNode> _getRelevantNodes(List<ExecutableNode> playgroundNodes, List<Connection> connections, ExecutableNode startNode) {
    List<ExecutableNode> relevantNodes = [];

    for (var connection in connections) {
      for (var playgroundNode in playgroundNodes) {
        if (playgroundNode.nodeUuid == connection.inNode.name || playgroundNode.nodeUuid == connection.outNode.name) {
          //if not already in the list
          if (!relevantNodes.contains(playgroundNode)){
            relevantNodes.add(playgroundNode);
          }
        }
      }
    }

    return relevantNodes;
  }

  Future<void> _executeNode(String node) async {
    if (allNodes[node]!.state == ExecutionState.finished || allNodes[node]!.state == ExecutionState.executing) {
      return;
    }

    allNodes[node]!.state = ExecutionState.finished;
    print("executed node: ${nodesDNA[node].nodeFunction.command}");

    if (_DEBUG_EXECUTOR)
      debugConsoleController.addInternalTabMessage("", MessageType.info);
  }

  List<String> _getOutPortNodes(String nodeUuid) {
    List<String> outNodes = [];

    for (var connection in controller.connections) {
      if (connection.outNode.name == nodeUuid) {
        outNodes.add(connection.inNode.name);
      }
    }

    return outNodes;
  }

  List<String> _getInPortNodes(String nodeUuid) {
    List<String> inNodes = [];

    for (var connection in controller.connections) {
      if (connection.inNode.name == nodeUuid) {
        inNodes.add(connection.outNode.name);
      }
    }

    return inNodes;
  }

  bool _dependentNodesAlreadyExecuted(String node) {
    List<String> inNodes = _getInPortNodes(node);
      

    for (String nodeUuid in inNodes) {
      if(allNodes[nodeUuid]!.state != ExecutionState.finished) return false;
    }

    return true;
  }

  Json _dependentNodesResult(
      String node,
      Map<String, List<String>> execNodeTree,
      List<ExecutableNode> playgroundNodes) {
    List<String> dependencies = [];

    execNodeTree.forEach((key, connectedNodes) {
      for (var connectedNode in connectedNodes) {
        if (connectedNode == node) {
          dependencies.add(key);
        }
      }
    });

    if (dependencies.isEmpty) {
      return {};
    }

    for (var dependency in dependencies) {
      for (var playgroundNode in playgroundNodes) {
        if (playgroundNode.nodeUuid == dependency) {
          return playgroundNode.resultValue;
        }
      }
    }

    return {};
  }

  List<ExecutableNode> _decodeNodes(Json nodes) {
    List<ExecutableNode> decodedList = [];

    for (var key in nodes.keys) {
      try {
        ExecutableNode node = ExecutableNode(
            nodeUuid: key,
            deviceUniqueId: nodesDNA[key].deviceUuid);
        decodedList.add(node);
      } catch (e) {
        if (_DEBUG_EXECUTOR)
          debugConsoleController.addInternalTabMessage(
              "Error decoding key: $key - $e", MessageType.info);
      }
    }

    return decodedList;
  }
}
