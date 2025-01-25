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
  final NodeDNA nodeDNA;
  final String deviceUniqueId;
  Map<String, ExecutableNode> allNodes;
  List<Connection> allConnections;

  Map<String, ExecutableNode> inputParameterNodes = {}; //key is the parameter name, value is the node that owns it
  List<ExecutableNode> nodesToTrigger = []; 
  List<ExecutableNode> nodesToGetTriggeredBy = [];  //this node can only get executed when all nodes in this list are executed
  
  ExecutionState state = ExecutionState.pending;
  ExecutionResult result = ExecutionResult.unknown;
  dynamic resultValue;



  // Constructor
  ExecutableNode({
    required this.nodeDNA,
    required this.deviceUniqueId,
    required this.allNodes,
    required this.allConnections
  });

  void init(){
    _getInputParameterNodes();
    _getNodesToTrigger();
    _getNodesToGetTriggeredBy();
  }

  void _getInputParameterNodes() {
    inputParameterNodes = {};

    for (var connection in allConnections) {
      if (connection.inNode.name == nodeDNA.nodeUuid) {
        inputParameterNodes[connection.inPort.name] = allNodes[connection.outNode.name]!;
      }
    }

    return;
  }

  void _getNodesToTrigger() {
    nodesToTrigger = [];

    for (var connection in allConnections) {
      if (connection.outNode.name == nodeDNA.nodeUuid) {
        nodesToTrigger.add(allNodes[connection.inNode.name]!);
      }
    }

    return;
  }

  void _getNodesToGetTriggeredBy() {
    nodesToGetTriggeredBy = [];

    for (var connection in allConnections) {
      if (connection.inNode.name == nodeDNA.nodeUuid) {
        nodesToGetTriggeredBy.add(allNodes[connection.outNode.name]!);
      }
    }

    return;
  }

}

class PlaygroundExecutor {
  final Map<String, RemoteDevice> wsDeviceList;
  final WebsocketManager websocketManager;
  final NodeEditorController controller;
  final Map<String, NodeDNA> nodesDNA;

  Map<String, ExecutableNode> allNodes = {};

  AuttyJsonFile? executingFile;

  PlaygroundExecutor(
      {
        required this.wsDeviceList,
        required this.websocketManager,
        required this.controller,
        required this.nodesDNA
      }
    );

  Future<bool> execute(AuttyJsonFile file) async {
    allNodes = {};

    executingFile = file;
    file.executionData = []; //clear the old execution data

    debugConsoleController.addInternalTabMessage(
        "Started execution", MessageType.info);
    debugConsoleController.clearTabMessages(ConsoleTab.execute);
    

    // Decode the nodes using the controller
    _decodeNodes();

    // Find the start node with deviceUniqueId = "internal" and nodeCommand = "{RUN}"
    ExecutableNode? startNode = _findStartNode();
    if (startNode == null) {
      debugConsoleController.addInternalTabMessage(
          "No start node found.", MessageType.error);
      return false;
    }

    _beginExecution(startNode);

    for (var node in allNodes.values) {
      if (node.result == ExecutionResult.failure || node.result == ExecutionResult.unknown) {
        return false;
      }
    }
    return true;
  }

  void _decodeNodes() {
    for (var key in controller.nodes.keys) {
      try {
        ExecutableNode node = ExecutableNode(
            nodeDNA: nodesDNA[key]!,
            deviceUniqueId: nodesDNA[key]!.deviceUuid,
            allNodes: allNodes,
            allConnections: controller.connections
            );


        allNodes[node.nodeDNA.nodeUuid] = node;

      } catch (e) {
        if (_DEBUG_EXECUTOR)
          debugConsoleController.addInternalTabMessage(
              "Error decoding key: $key - $e", MessageType.info);
      }
    }

    for (var node in allNodes.values) {
      node.init();
    }
  }

  ExecutableNode? _findStartNode() {
    for (var node in allNodes.values) {
      if (node.deviceUniqueId == 'internal' && nodesDNA[node.nodeDNA.nodeUuid]!.nodeFunction.command == 'RUN') {
        return node;
      }
    }
    return null;
  }

  Future<void> _beginExecution(ExecutableNode node, {bool startMiddle = false}) async {
    if (node.state == ExecutionState.finished || node.state == ExecutionState.executing) {
      return;
    }
    print(node.state);

    if(node.nodesToGetTriggeredBy.isNotEmpty){
      for(ExecutableNode dependentNode in node.nodesToGetTriggeredBy){
        if(dependentNode.state != ExecutionState.finished){
          if(!startMiddle){
            return;
          }
        }
      }
    }

    node.state = ExecutionState.executing;
    Map<String, dynamic> parameters = _getNodeParameters(node);

    //do here the actual execute
    await _callNodeFunction(node, parameters);
    _logExecutionResult(node);

    node.state = ExecutionState.finished;
    

    for(ExecutableNode nextNode in node.nodesToTrigger){
      await _beginExecution(nextNode);
    }
  }

  _logExecutionResult(ExecutableNode node){
    if(node.result == ExecutionResult.failure){
      debugConsoleController.addExecutionTabMessage(
          node.resultValue.toString(),
          node.nodeDNA.nodeUuid,
          MessageType.error,
          controller.selectNodeAction
      );  
    }
    if(node.result == ExecutionResult.unknown){
      debugConsoleController.addExecutionTabMessage(
          "Node ${node.nodeDNA.nodeUuid} result is unknown",
          node.nodeDNA.nodeUuid,
          MessageType.error,
          controller.selectNodeAction

      );
    }
    if(node.result == ExecutionResult.success){
      debugConsoleController.addExecutionTabMessage(
          "${node.resultValue} --> success",
          node.nodeDNA.nodeUuid,
          MessageType.info,
          controller.selectNodeAction
      );
    }
  }

  Future<void> _callNodeFunction(ExecutableNode node, Map<String, dynamic> parameters) async {
    print("executed node: ${node.nodeDNA.nodeFunction.command} with parameters: $parameters");

    dynamic result;

        node.result = ExecutionResult.failure;
        node.state = ExecutionState.finished;

        try {
          if (node.nodeDNA.deviceUuid!= 'internal') {
            // Await the WebSocketManager operation
            result = await websocketManager.sendAwaitedRequest(
              node.nodeDNA.deviceUuid,
              node.nodeDNA.nodeFunction.command,
              parameters
            );
          } else {
            // Process internal device commands
            result = await internalDeviceCommandProcessor(
              node.nodeDNA.nodeFunction.command,
              parameters
            );
          }
          if(isValidReturnType(node.nodeDNA.nodeFunction.returnType, result)){
            node.state = ExecutionState.finished;
            node.result = ExecutionResult.success;
            node.resultValue = result;
          }
        } catch (e) {
          // Log the error if necessary
          print('Error occurred: $e');
          node.result = ExecutionResult.failure;
          node.state = ExecutionState.finished;
          node.resultValue = e;
        }



  }

  Map<String, dynamic> _getNodeParameters(ExecutableNode node){
    Map<String, dynamic> parameters = {};

    //get parameters from executed nodes
    for (String key in node.inputParameterNodes.keys) {
      if (key != "Trigger In") {
        parameters[key] = node.inputParameterNodes[key]!.resultValue;
      }
    }

    node.nodeDNA.nodeFunction.parameters?.forEach((parameter) {
      if(parameter.hardSet){
        parameters[parameter.name] = parameter.value;
      }
      if(!parameter.hardSet){
        //if it doesnt exist, in parameters, it means that it's not connected
        if(parameters[parameter.name] == null){
          debugConsoleController.addExecutionTabMessage(
              "Parameter ${parameter.name} is not connected",
              node.nodeDNA.nodeUuid,
              MessageType.warning,
              controller.selectNodeAction
          );
        }
      }
    });
    

    return parameters;
  }


}
