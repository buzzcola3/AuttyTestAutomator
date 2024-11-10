import 'dart:convert';
import 'package:attempt_two/main_screen/device_list/node_generation/node_generator.dart';
import 'package:attempt_two/main_screen/node_playground/playground.dart';
import 'package:attempt_two/main_screen/node_playground/playground_execution.dart';
import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import 'dart:async';

class PlaygroundSaveLoad {
  final NodeEditorController playgroundController;
  NodeEditorWidgetController nodeEditorWidgetController;
  Map<String, dynamic> nodesDNA;
  PlaygroundExecutor playgroundExecutor;

  PlaygroundSaveLoad(this.playgroundController, this.nodesDNA, this.nodeEditorWidgetController, this.playgroundExecutor);

  // Save the current state of nodes to JSON
  String saveToJson() {
    playgroundController;
    nodesDNA;

    playgroundController.nodes["<nodeName>"]?.pos; // nodePosition
    playgroundController.connections.removeLast();

    List<Map<String, dynamic>> nodesData = [];
    

    return jsonEncode(nodesData);
  }

  List<String> getNodesNameList(){
    return nodesDNA.keys.toList();
  }

  Offset getNodePosition(String nodeUniqueName){
    return playgroundController.nodes[nodeUniqueName]?.pos ?? Offset.zero;
  }

  Map<String, dynamic>? getSingleDNA(nodeUniqueName){
    if(nodesDNA[nodeUniqueName] != null){
      return nodesDNA[nodeUniqueName];
    }
    
    return null;
  }


Future<void> loadPlayground(String playgroundJson) async {
  playgroundController.nodes.clear();
  playgroundController.connections.clear();
  nodesDNA.clear();

  Map<String, dynamic> playgroundData = json.decode(playgroundJson);

  // Load nodes
  for (var node in playgroundData["nodes"]) {
    Offset position = Offset(node["nodePosition"]["dx"], node["nodePosition"]["dy"]);
    Map<String, dynamic> nodeDNA = node["nodeDNA"];

    Widget nodeWidget = fabricateNode(
      nodeName: nodeDNA["nodeName"],
      nodeColor: nodeDNA["nodeColor"],
      nodeType: nodeDNA["nodeType"],
      inPorts: nodeDNA["inPorts"],
      outPorts: nodeDNA["outPorts"],
      svgIconString: nodeDNA["svgIconString"],
      isDummy: false,
    )!; // Adding the null assertion operator
  
    nodeEditorWidgetController.addNodeAtPosition(nodePosition: position, nodeDNA: nodeDNA, nodeWidget: nodeWidget);
  }

  // Load connections
  for (var connection in playgroundData["connections"]) {
    var inNodeName = connection["inNodeName"];
    var outNodeName = connection["outNodeName"];
    var inPortName = connection["inPortName"];
    var outPortName = connection["outPortName"];

    // Wait until inPort and outPort are available
    await _waitUntilPortExists(inNodeName, inPortName);
    await _waitUntilPortExists(outNodeName, outPortName);

    var inNode = playgroundController.nodes[inNodeName]!;
    var outNode = playgroundController.nodes[outNodeName]!;

    var inPort = inNode.ports[inPortName]!;
    var outPort = outNode.ports[outPortName]!;

    Connection newConnection = Connection(inPort: inPort, inNode: inNode, outNode: outNode, outPort: outPort);
    playgroundController.connections.add(newConnection);
  }

  nodeEditorWidgetController.refreshUI();
}

Future<void> loadAndExecutePlayground(String playgroundJson) async {
  await loadPlayground(playgroundJson);
  await playgroundExecutor.execute();
}

// Helper function to wait until a port exists
Future<void> _waitUntilPortExists(String nodeName, String portName) async {
  try {
    await Future.any([
      Future.delayed(const Duration(seconds: 10), () {
        throw TimeoutException("Timeout: Port '$portName' in node '$nodeName' not found within 10 seconds.");
      }),
      () async {
        while (playgroundController.nodes[nodeName]?.ports[portName] == null) {
          await Future.delayed(const Duration(milliseconds: 5));
        }
      }(),
    ]);
  } on TimeoutException catch (e) {
    print(e.message); // Print the error message
  }
}


  String savePlayground(){
    return jsonEncode({"nodes": saveNodes(), "connections": saveConnections()});
  }

  List<Map<String, dynamic>> saveNodes(){
    List<String> nodeNameList = getNodesNameList();
   
    List<Map<String, dynamic>> jsonableNodes = [];
      
    for (var nodeName in nodeNameList) {
      jsonableNodes.add(saveNode(nodeName));
    }
   
    return jsonableNodes;
  }
  
  Map<String, dynamic> saveNode(String nodeUniqueName){
    Map<String, dynamic>? nodeDNA = getSingleDNA(nodeUniqueName);
    Offset nodePosition = getNodePosition(nodeUniqueName);

    Map<String, dynamic> jsonableNode = {
      "nodeName": nodeUniqueName,
      "nodePosition": {"dx": nodePosition.dx, "dy": nodePosition.dy},
      "nodeDNA": nodeDNA
    };

    return jsonableNode;
  }

  List<Map<String, dynamic>> saveConnections(){ //save playground

    List<Map<String, dynamic>> jsonableConnections = [];
    
    for (var connection in playgroundController.connections) {
      jsonableConnections.add(saveConnection(connection));
    }

    return jsonableConnections;
  }

  Map<String, dynamic> saveConnection(Connection connection){

    String inNodeName = connection.inNode.name;
    String inPortName = connection.inPort.name;
    String outNodeName = connection.outNode.name;
    String outPortName = connection.outPort.name;
    
    Map<String, dynamic> jsonableConnection = {
      "inNodeName": inNodeName,
      "inPortName": inPortName,
      "outNodeName": outNodeName,
      "outPortName": outPortName,
    };

    return jsonableConnection;
    
  }
}
