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
import 'package:Autty/main.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/communication_handler.dart';
import 'package:flutter/material.dart';

import 'package:Autty/global_datatypes/device_info.dart';
import 'package:Autty/global_datatypes/ip_address.dart';
import 'package:Autty/global_datatypes/json.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/headers/websocket_datatypes.dart';

String startNodeIcon = """
<?xml version="1.0" encoding="utf-8"?>

<!-- Uploaded to: SVG Repo, www.svgrepo.com, Generator: SVG Repo Mixer Tools -->
<svg version="1.1" id="Uploaded to svgrepo.com" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" 
	 width="800px" height="800px" viewBox="0 0 32 32" xml:space="preserve">
<style type="text/css">
	.hatch_een{fill:#265AA5;}
	.hatch_twee{fill:#FFC5BB;}
</style>
<g>
	<path class="hatch_twee" d="M18.157,12.714l0.905,0.509L8,24.285v-1.414L18.157,12.714z M12.277,22.594l3.232-1.818l6.114-6.114
		l-0.905-0.509L12.277,22.594z M24,16l-0.723-0.406l-1.858,1.858L24,16z M8,14.871v1.414l5.942-5.942l-0.905-0.509L8,14.871z
		 M8,8.285l0.822-0.822L8,7V8.285z M8,18.871v1.414l8.502-8.502l-0.905-0.509L8,18.871z M8,10.871v1.414l3.382-3.382l-0.905-0.509
		L8,10.871z"/>
	<path class="hatch_een" d="M24,16L8,25V7L24,16z M7.495,6.137C7.188,6.316,7,6.614,7,7v18c0,0.355,0.188,0.684,0.495,0.863
		C7.651,25.954,7.825,26,8,26c0.169,0,0.338-0.043,0.49-0.128l16-9C24.805,16.694,25,16.361,25,16c0-0.361-0.195-0.694-0.51-0.872
		l-16-9C8.338,6.043,8.18,6,8,6S7.651,6.046,7.495,6.137z"/>
</g>
</svg>
""";

AvailableNodes internalNodes = AvailableNodes(
  nodes: 
    [
      Node(
        name: "Start",
        type: NodeType.outputNode,
        color: "red",
        svgIcon: startNodeIcon,
        function: NodeFunction(
          command: "RUN",
          returnType: NodeFunctionReturnType.none,
          returnName: "void",
          parameters: []
        )
      ),

      Node(
        name: "Delay",
        type: NodeType.basicNode,
        color: "blue",
        svgIcon: startNodeIcon,
        function: NodeFunction(
          command: "DELAY",
          returnType: NodeFunctionReturnType.none,
          returnName: "void",
          parameters: [
            NodeParameter(
              name: "Delay(ms)",
              type: NodeParameterType.number,
              hardSet: true,
              value: "1000",
              hardSetOptionsType: HardSetOptionsType.directInput,
            ),
          ],
        ),
      ),

Node(
  name: "Compare Number",
  type: NodeType.basicNode,
  color: "green",
  svgIcon: startNodeIcon,
  function: NodeFunction(
    command: "COMPARE NUMBER",
    returnType: NodeFunctionReturnType.string,
    returnName: "void",
    parameters: [
      NodeParameter(
        name: "first value",
        type: NodeParameterType.number,
        value: "0",
        hardSet: false
      ),
      NodeParameter(
        name: "second value",
        type: NodeParameterType.number,
        value: "0",
        hardSet: false
      ),
      NodeParameter(
        name: "Compare Type",
        type: NodeParameterType.string,
        hardSet: true,
        value: "==",
        hardSetOptionsType: HardSetOptionsType.selectableList,
        hardSetOptions: [">", ">=", "==", "<=", "<" ]
      )
    ],
  )
),

      Node(
        name: "User Input",
        type: NodeType.basicNode,
        color: "yellow",
        svgIcon: startNodeIcon,
        function: NodeFunction(
          command: "USER INPUT",
          returnType: NodeFunctionReturnType.string,
          returnName: "User Input",
          parameters: [
            NodeParameter(
              name: "Text",
              type: NodeParameterType.string,
              hardSet: true,
              value: "Enter your input here",
              hardSetOptionsType: HardSetOptionsType.directInput
            )
          ]
        )
      ),

      Node(
        name: "User Confirm",
        type: NodeType.basicNode,
        color: "purple",
        svgIcon: startNodeIcon,
        function: NodeFunction(
          command: "USER CONFIRM",
          returnType: NodeFunctionReturnType.none,
          returnName: "User Confirm",
          parameters: [
            NodeParameter(
              name: "Prompt text",
              type: NodeParameterType.string,
              hardSet: true,
              value: "Do you confirm this decision?",
              hardSetOptionsType: HardSetOptionsType.directInput
            )
          ]
        )
      ),
    ]
);


Json internalDevice = {
  "DEVICE_NAME": "Functions",
  "UNIQUE_ID": "internal",
  "DEVICE_DESCRIPTION": "This is an internal device, that allows usage of internal nodes functions",
  "DEVICE_ICON_SVG": "",
  "DEVICE_AVAILABLE_NODES": internalNodes.toJson()
};

RemoteDevice internalWsDevice = RemoteDevice.dummy(deviceIp: IPAddress('', 0), deviceInfo: DeviceInfo(jsonEncode(internalDevice)));

Future<dynamic> internalDeviceCommandProcessor(String command, Map<String, dynamic> params) async {
  print(command);
  print(params);

  dynamic result = null;
  bool fail = true;

  
  if(command == "DELAY"){
    fail = false;
    await Future.delayed(Duration(milliseconds: int.parse(params["Delay(ms)"])));
  }
  else if(command == "RUN"){
    fail = false;
  }
  else if(command == "COMPARE NUMBER"){
    double? measuredValue = double.parse(params["first value"] ?? '');
    double expectedValue = double.parse(params["second value"] ?? '');
    String compareType = params["Compare Type"];

    if(compareType == "=="){
      if(measuredValue == expectedValue){
        result = "$measuredValue == $expectedValue";
      }
      else{
        throw Exception("Comparison failed: $measuredValue == $expectedValue");
      }
    }
    else if(compareType == ">"){
      if(measuredValue > expectedValue){
        result = "$measuredValue > $expectedValue";
      }
      else{
        throw Exception("Comparison failed: $measuredValue > $expectedValue");
      }
    }
    else if(compareType == "<"){
      if(measuredValue < expectedValue){
        result = "$measuredValue < $expectedValue"; 
      }
      else{
        throw Exception("Comparison failed: $measuredValue < $expectedValue");
      }
    }
    else if(compareType == ">="){
      if(measuredValue >= expectedValue){
        result = "$measuredValue >= $expectedValue";
      }
      else{
        throw Exception("Comparison failed: $measuredValue >= $expectedValue");
      }
    }
    else if(compareType == "<="){
      if(measuredValue <= expectedValue){
        result = "$measuredValue <= $expectedValue";
      }
      else{
        throw Exception("Comparison failed");
      }
    }
    fail = false;
  }
else if (command == "USER INPUT") {
  String userInput = ""; // To store user input from the TextField
  
  // Make the dialog blocking using showDialog and await
  await showDialog(
    context: alertDialogManager.navigatorKey.currentState!.context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(params["Text"], style: TextStyle(fontSize: 16)), // Display params[0] as instruction
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) {
                userInput = value; // Update userInput with the text field's value
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your input here",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // When "OK" is clicked, update the result map
              result = userInput;
              fail = false;
  
              // Close the dialog
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
else if (command == "USER CONFIRM") {
  // Display an alert with Pass/Fail buttons
  await showDialog(
    context: alertDialogManager.navigatorKey.currentState!.context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(params["Prompt text"], style: TextStyle(fontSize: 16)), // Title is params[0]
        content: const Text("Do you confirm this decision?"), // Prompt text
        actions: [
          TextButton(
            onPressed: () {
              // When "Fail" is clicked, set the result accordingly
              Navigator.of(context).pop();
              result = "User did not confirm";
            },
            child: const Text("Fail"),
          ),
          ElevatedButton(
            onPressed: () {
              // Close the dialog
              fail = false;
              Navigator.of(context).pop();
            },
            child: const Text("Pass"),
          ),
        ],
      );
    },
  );
}

if (fail) throw result;
return result;
}
