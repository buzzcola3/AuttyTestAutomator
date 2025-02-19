import 'package:Autty/global_datatypes/device_info.dart';
import 'package:Autty/main.dart';
import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
import 'package:Autty/main_screen/device_list/internal_device.dart';
import 'package:Autty/main_screen/device_list/node_generation/node_generator.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/communication_handler.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/websocket_manager.dart';
import 'package:Autty/main_screen/node_playground_file_manager/file_datatypes.dart';
import 'package:node_editor/node_editor.dart';

// ignore: constant_identifier_names
const bool _DEBUG_EXECUTOR = true;


class ExecutableNode {
  // Members
  final NodeWithNotifiers nodeDNA;
  final String deviceUniqueId;
  Map<String, ExecutableNode> allNodes;
  List<Connection> allConnections;

  Map<String, ExecutableNode> inputParameterNodes = {}; //key is the parameter name, value is the node that owns it
  List<ExecutableNode> nodesToTrigger = []; 
  List<ExecutableNode> nodesToGetTriggeredBy = [];  //this node can only get executed when all nodes in this list are executed
  
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
      if (connection.inNode.name == nodeDNA.notifierNodeDNA.value.nodeUuid) {
        inputParameterNodes[connection.inPort.name] = allNodes[connection.outNode.name]!;
      }
    }

    return;
  }

  void _getNodesToTrigger() {
    nodesToTrigger = [];

    for (var connection in allConnections) {
      if (connection.outNode.name == nodeDNA.notifierNodeDNA.value.nodeUuid) {
        nodesToTrigger.add(allNodes[connection.inNode.name]!);
      }
    }

    return;
  }

  void _getNodesToGetTriggeredBy() {
    nodesToGetTriggeredBy = [];

    for (var connection in allConnections) {
      if (connection.inNode.name == nodeDNA.notifierNodeDNA.value.nodeUuid) {
        nodesToGetTriggeredBy.add(allNodes[connection.outNode.name]!);
      }
    }

    return;
  }

  void updateNodeUI(){
    nodeDNA.notifierNodeDNA.value = NodeDNA.fromJson(nodeDNA.notifierNodeDNA.value.toJson());
  }

  ExecutionResult get executionResult{
    return nodeDNA.notifierNodeDNA.value.nodeFunction.executionResult;
  }
  set executionResult(ExecutionResult result){
    nodeDNA.notifierNodeDNA.value.nodeFunction.executionResult = result;
  }

  ExecutionState get executionState{
    return nodeDNA.notifierNodeDNA.value.nodeFunction.executionState;
  }
  set executionState(ExecutionState state){
    nodeDNA.notifierNodeDNA.value.nodeFunction.executionState = state;
  }

  String get nodeName{
    return nodeDNA.notifierNodeDNA.value.nodeName;
  }
  set nodeName(String newName){
    nodeDNA.notifierNodeDNA.value.nodeName = newName;
  }

  String get nodeUuid{
    return nodeDNA.notifierNodeDNA.value.nodeUuid;
  }

  String get deviceUuid{
    return nodeDNA.notifierNodeDNA.value.deviceUuid;
  }

  String get command{
    return nodeDNA.notifierNodeDNA.value.nodeFunction.command;
  }

  NodeFunction get nodeFunction{
    return nodeDNA.notifierNodeDNA.value.nodeFunction;
  }



}

class PlaygroundExecutor {
  final Map<String, RemoteDevice> wsDeviceList;
  final WebsocketManager websocketManager;
  final NodeEditorController controller;
  final Map<String, NodeWithNotifiers> nodesDNA;

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

    //check if all devices are alive TODO
    


    debugConsoleController.addInternalTabMessage(
        "Started execution", MessageType.info);
    debugConsoleController.clearTabMessages(ConsoleTab.execute);
    

    // Decode the nodes using the controller
    _decodeNodes();
    List<String> requiredRemoteDevices = [];

    for (var nodeKey in allNodes.keys) {
      // Retrieve the list of required remote devices for the current node
      final uuid = allNodes[nodeKey]!.deviceUuid;
      if(uuid != "internal"){
        requiredRemoteDevices.add(uuid);
      }
    }

    websocketManager.disableAliveTest();
    if(!(await websocketManager.requiredDevicesAvailable(requiredRemoteDevices))){
      websocketManager.enableAliveTest();
      print("(one or more) some required devices not available.");
      debugConsoleController.addInternalTabMessage(
          "Execution aborted, (one or more) some required devices are not available.", MessageType.error);
      return false;
    }
    


    // Find the start node with deviceUniqueId = "internal" and nodeCommand = "{RUN}"
    ExecutableNode? startNode = _findStartNode();
    if (startNode == null) {
      debugConsoleController.addInternalTabMessage(
          "No start node found.", MessageType.error);
      return false;
    }

    websocketManager.enableAliveTest();

    _resetNodeExecutionStates();

    await _beginExecution(startNode);

    

    for (var node in allNodes.values){
      print(node.executionResult.toJson());
      if (node.executionResult == ExecutionResult.failure || node.executionResult == ExecutionResult.unknown) {
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
            deviceUniqueId: nodesDNA[key]!.notifierNodeDNA.value.deviceUuid,
            allNodes: allNodes,
            allConnections: controller.connections
            );


        allNodes[node.nodeUuid] = node;

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
      if (node.deviceUniqueId == 'internal' && node.command == 'RUN') {
        return node;
      }
    }
    return null;
  }

  void _resetNodeExecutionStates(){
    for (var node in allNodes.values) {
      node.executionResult = ExecutionResult.unknown;
      node.executionState = ExecutionState.pending;
      //node.getNodeFunction.resultValue = null; TODO move it here aswel, maybe create a separete execution object for all
      node.updateNodeUI();
    }
  }

  Future<void> _beginExecution(ExecutableNode node, {bool startMiddle = false}) async {
    if (node.executionState == ExecutionState.finished || node.executionState == ExecutionState.executing) {
      return;
    }
    print(node.executionState);

    if(node.nodesToGetTriggeredBy.isNotEmpty){
      for(ExecutableNode dependentNode in node.nodesToGetTriggeredBy){
        if(dependentNode.executionState != ExecutionState.finished){
          if(!startMiddle){
            return;
          }
        }
      }
    }

    node.executionState = ExecutionState.executing;
    node.updateNodeUI();

    Map<String, dynamic> parameters = _getNodeParameters(node);

    //do here the actual execute
    await _callNodeFunction(node, parameters);
    _logExecutionResult(node);

    node.executionState = ExecutionState.finished;
    node.updateNodeUI();
    

    for(ExecutableNode nextNode in node.nodesToTrigger){
      _beginExecution(nextNode);
    }
  }

  _logExecutionResult(ExecutableNode node){
    if(node.executionResult == ExecutionResult.failure){
      debugConsoleController.addExecutionTabMessage(
          node.resultValue.toString(),
          node.nodeUuid,
          MessageType.error,
          controller.selectNodeAction
      );  
    }
    if(node.executionResult == ExecutionResult.unknown){
      debugConsoleController.addExecutionTabMessage(
          "Node ${node.nodeUuid} result is unknown",
          node.nodeUuid,
          MessageType.error,
          controller.selectNodeAction

      );
    }
    if(node.executionResult == ExecutionResult.success){
      debugConsoleController.addExecutionTabMessage(
          "${node.resultValue} --> success",
          node.nodeUuid,
          MessageType.info,
          controller.selectNodeAction
      );
    }
  }

  Future<void> _callNodeFunction(ExecutableNode node, Map<String, dynamic> parameters) async {
    print("executed node: ${node.command} with parameters: $parameters");

    dynamic result;

        try {
          if (node.deviceUuid!= 'internal') {
            // Await the WebSocketManager operation
            result = await websocketManager.sendAwaitedRequest(
              node.deviceUuid,
              node.command,
              parameters
            );
          } else {
            // Process internal device commands
            result = await internalDeviceCommandProcessor(
              node.command,
              parameters
            );
          }
          if(validateReturnType(node.nodeFunction.returnType, result)){
            node.executionState = ExecutionState.finished;
            node.executionResult = ExecutionResult.success;
            node.resultValue = result;
          }
          else{
            node.executionState = ExecutionState.finished;
            node.executionResult = ExecutionResult.failure;

            throw "node return value: $result does not match the expected type of: ${node.nodeFunction.returnType}.";
          }
        } catch (e) {
          // Log the error if necessary
          print('Error occurred: $e');
          node.executionResult = ExecutionResult.failure;
          node.executionState = ExecutionState.finished;
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

    node.nodeFunction.parameters?.forEach((parameter) {
      if(parameter.hardSet){
        parameters[parameter.name] = parameter.value;
      }
      if(!parameter.hardSet){
        //if it doesnt exist, in parameters, it means that it's not connected
        if(parameters[parameter.name] == null){
          debugConsoleController.addExecutionTabMessage(
              "Parameter ${parameter.name} is not connected",
              node.nodeUuid,
              MessageType.warning,
              controller.selectNodeAction
          );
        }
      }
    });
    

    return parameters;
  }


}
