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

import 'dart:convert';
import 'package:Autty/global_datatypes/device_info.dart';
import 'package:Autty/global_datatypes/json.dart';
import 'package:Autty/main.dart';
import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
import 'package:Autty/main_screen/device_list/node_generation/node_generator.dart';
import 'package:Autty/main_screen/node_playground/playground.dart';
import 'package:Autty/main_screen/node_playground/playground_execution.dart';
import 'package:Autty/main_screen/node_playground_file_manager/file_datatypes.dart';
import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import 'dart:async';


class PlaygroundFileInterface {
  final NodeEditorController playgroundController;
  NodeEditorWidgetController nodeEditorWidgetController;
  Map<String, NodeWithNotifiers> nodesDNA;
  PlaygroundExecutor playgroundExecutor;
  PlaygroundFileInterface(this.playgroundController, this.nodesDNA, this.nodeEditorWidgetController, this.playgroundExecutor);

  AuttyJsonFile loadedFile = AuttyJsonFile(filename: "*current.json", executionData: [], nodePlaygroundData: "", filePosition: 0);

  List<String> getNodesNameList(){
    return nodesDNA.keys.toList();
  }

  Offset getNodePosition(String nodeUniqueName){
    return playgroundController.nodes[nodeUniqueName]?.pos ?? Offset.zero;
  }
  
  bool nodeExists(String nodeUniqueName) {
    return playgroundController.nodes.containsKey(nodeUniqueName);
  }


  NodeDNA? getSingleDNA(nodeUniqueName){
    if(nodesDNA[nodeUniqueName] != null){
      return nodesDNA[nodeUniqueName]?.notifierNodeDNA.value;
    }
    
    return null;
  }

  void _loadLastExecutionResult(AuttyJsonFile file){
    for (var line in file.executionData) {
      //executionData.add({"message": resultMessage, "sourceNode": sourceNode, "messageType": messageType.toJson()});
      MessageType type = MessageTypeExtension.fromJson(line["messageType"]);
      debugConsoleController.addExecutionTabMessage(line["message"], line["sourceNode"], type, playgroundController.selectNodeAction); 
    }
  }

  Future<void> loadFile(AuttyJsonFile file) async {
    loadedFile = file;
    playgroundController.nodes.clear();
    playgroundController.connections.clear();
    nodesDNA.clear();
  
    Json playgroundData = json.decode(file.nodePlaygroundData);
  
    // Load nodes
    for (var node in playgroundData["nodes"]) {
      Offset position = Offset(node["nodePosition"]["dx"], node["nodePosition"]["dy"]);
      NodeDNA nodeDNA = NodeDNA.fromJson(node["nodeDNA"]);
  
      NodeWithNotifiers nodeWidget = fabricateNode(
        nodeDNA: nodeDNA,
        isDummy: false,
      );
    
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
  
    debugConsoleController.clearTabMessages(ConsoleTab.execute);
    _loadLastExecutionResult(file);
    nodeEditorWidgetController.refreshUI();
  }


  AuttyJsonFile? saveFile(){
    loadedFile.nodePlaygroundData = _savePlayground();
    return loadedFile;
  }

  Future<bool> executeFile() async {
    final result = await playgroundExecutor.execute(loadedFile);
    loadedFile.executionResultSuccess = result;
    return result;
  }
  
  Future<bool> loadAndExecuteFile(AuttyJsonFile file) async {
    await loadFile(file);
    return await executeFile();
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


  String _savePlayground(){
    return jsonEncode({"nodes": _saveNodes(), "connections": _saveConnections()});
  }

  List<Json> _saveNodes(){
    List<String> nodeNameList = getNodesNameList();
   
    List<Json> jsonableNodes = [];
      
    for (var nodeName in nodeNameList) {
      if(nodeExists(nodeName)){
        jsonableNodes.add(_saveNode(nodeName));
      }
    }
   
    return jsonableNodes;
  }
  
  Json _saveNode(String nodeUniqueName){
    NodeDNA? nodeDNA = getSingleDNA(nodeUniqueName);
    Offset nodePosition = getNodePosition(nodeUniqueName);

    Json jsonableNode = {
      "nodeName": nodeUniqueName,
      "nodePosition": {"dx": nodePosition.dx, "dy": nodePosition.dy},
      "nodeDNA": nodeDNA?.toJson()
    };

    return jsonableNode;
  }

  List<Json> _saveConnections(){ //save playground

    List<Json> jsonableConnections = [];
    
    for (var connection in playgroundController.connections) {
      jsonableConnections.add(_saveConnection(connection));
    }

    return jsonableConnections;
  }

  Json _saveConnection(Connection connection){

    String inNodeName = connection.inNode.name;
    String inPortName = connection.inPort.name;
    String outNodeName = connection.outNode.name;
    String outPortName = connection.outPort.name;
    
    Json jsonableConnection = {
      "inNodeName": inNodeName,
      "inPortName": inPortName,
      "outNodeName": outNodeName,
      "outPortName": outPortName,
    };

    return jsonableConnection;
    
  }
}
