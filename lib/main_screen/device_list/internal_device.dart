

import 'dart:convert';
import 'package:Autty/main.dart';
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

Json internalDevice = {
  "DEVICE_NAME": "Functions",
  "UNIQUE_ID": "internal",
  "DEVICE_DESCRIPTION": "This is an internal device, that allows usage of internal nodes functions",
  "DEVICE_ICON_SVG": "",
  "DEVICE_AVAILABLE_COMMANDS": [],
  "DEVICE_AVAILABLE_NODES": [
    {
      "Name": "Start",
      "Type": "outputNode",
      "Command": "RUN",
      "Parameters": [],
      "Color": "red",
      "InPorts": [],
      "OutPorts": ["start_outport"],
      "SvgIcon": startNodeIcon
    },
    {
      "Name": "Delay",
      "Type": "basicNode",
      "Command": "DELAY",
      "Parameters": 
      [
        {
          "Name": "Delay(ms)",
          "Type": "Int",
          "Value": "1000",
        }
      ],
      "Color": "blue",
      "InPorts": ["delay_inport"],
      "OutPorts": ["delay_outport"],
      "SvgIcon": startNodeIcon
    },
    {
      "Name": "Compare Number",
      "Type": "basicNode",
      "Command": "COMPARE NUMBER",
      "Parameters": 
      [
        {
          "Name": "expected value",
          "Type": "Int",
          "Value": "0",
        },
        {
          "Name": "compare type",
          "Type": "List",
          "Value": "==",
          "AvailableValues": [">", ">=", "==", "<=", "<" ],
        },
      ],
      "Color": "green",
      "InPorts": ["delay_inport"],
      "OutPorts": ["delay_outport"],
      "SvgIcon": startNodeIcon
    },
    {
      "Name": "User Input",
      "Type": "basicNode",
      "Command": "USER INPUT",
      "Parameters": 
      [
        {
          "Name": "Text",
          "Type": "String",
          "Value": "User input text",
        },
      ],
      "Color": "yellow",
      "InPorts": ["user_input_inport"],
      "OutPorts": ["user_input_outport"],
      "SvgIcon": startNodeIcon
    },
    {
      "Name": "User Confirm",
      "Type": "basicNode",
      "Command": "USER CONFIRM",
      "Parameters": 
      [
        {
          "Name": "Text",
          "Type": "String",
          "Value": "User input text",
        },
      ],
      "Color": "purple",
      "InPorts": ["user_input_inport"],
      "OutPorts": ["user_input_outport"],
      "SvgIcon": startNodeIcon
    },
    {
      "Name": "User Decide",
      "Type": "basicNode",
      "Command": "USER DECIDE",
      "Parameters": 
      [
        {
          "Name": "Text",
          "Type": "String",
          "Value": "User input text",
        },
      ],
      "Color": "cyan",
      "InPorts": ["user_input_inport"],
      "OutPorts": ["user_input_outport"],
      "SvgIcon": startNodeIcon
    },
  ],
};

WsDevice internalWsDevice = WsDevice(ipAddress: IPAddress('', 0), deviceInfo: DeviceInfo(jsonEncode(internalDevice)));

Future<Json> internalDeviceCommandProcessor(String command, List<dynamic> params, Json dependencyResult) async {
  print(command);
  print(params);

  Json result = {"OUTCOME": "ERROR", "RESPONSE": "internalDeviceCommandProcessor did not return"};

  
  if(command == "DELAY"){
    await Future.delayed(Duration(milliseconds: int.parse(params[0])));
    result["OUTCOME"] = "SUCCESS";
    result["RESPONSE"] = "ok";
  }
  else if(command == "RUN"){
    result["OUTCOME"] = "SUCCESS";
    result["RESPONSE"] = "ok";
  }
  else if(command == "COMPARE NUMBER"){
    double? measuredValue = double.tryParse(dependencyResult["RESPONSE"] ?? '');
    double expectedValue = double.parse(params[0]);
    String compareType = params[1];

    result["RESPONSE"] = "$measuredValue $compareType $expectedValue";
    print(result["RESPONSE"]);

    if(compareType == "=="){
      if(measuredValue == expectedValue){
        result["OUTCOME"] = "SUCCESS";
      }
      else{
        result["OUTCOME"] = "ERROR";
      }
    }
    else if(compareType == ">"){
      if(measuredValue! > expectedValue){
        result["OUTCOME"] = "SUCCESS";
      }
      else{
        result["OUTCOME"] = "ERROR";
      }
    }
    else if(compareType == "<"){
      if(measuredValue! < expectedValue){
        result["OUTCOME"] = "SUCCESS";
      }
      else{
        result["OUTCOME"] = "ERROR";
      }
    }
    else if(compareType == ">="){
      if(measuredValue! >= expectedValue){
        result["OUTCOME"] = "SUCCESS";
      }
      else{
        result["OUTCOME"] = "ERROR";
      }
    }
    else if(compareType == "<="){
      if(measuredValue! <= expectedValue){
        result["OUTCOME"] = "SUCCESS";
      }
      else{
        result["OUTCOME"] = "ERROR";
      }
    }
  }
else if (command == "USER INPUT") {
  String userInput = ""; // To store user input from the TextField
  
  // Make the dialog blocking using showDialog and await
  await showDialog(
    context: alertDialogManager.navigatorKey.currentState!.context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(params[0], style: TextStyle(fontSize: 16)), // Display params[0] as instruction
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
              result["RESPONSE"] = userInput;
              result["OUTCOME"] = "SUCCESS";
  
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
        title: Text(params[0], style: TextStyle(fontSize: 16)), // Title is params[0]
        content: const Text("Do you confirm this decision?"), // Prompt text
        actions: [
          TextButton(
            onPressed: () {
              // When "Fail" is clicked, set the result accordingly
              result["RESPONSE"] = "Fail";
              result["OUTCOME"] = "ERROR"; // Outcome is "ERROR" if Fail
  
              // Close the dialog
              Navigator.of(context).pop();
            },
            child: const Text("Fail"),
          ),
          ElevatedButton(
            onPressed: () {
              // When "Pass" is clicked, set the result accordingly
              result["RESPONSE"] = "Pass";
              result["OUTCOME"] = "SUCCESS"; // Outcome is "SUCCESS" if Pass
  
              // Close the dialog
              Navigator.of(context).pop();
            },
            child: const Text("Pass"),
          ),
        ],
      );
    },
  );
}
else if (command == "USER DECIDE") {
  // Display a confirmation dialog with Pass/Fail buttons
  await showDialog(
    context: alertDialogManager.navigatorKey.currentState!.context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(params[0], style: TextStyle(fontSize: 16)), // Title is params[0]
        content: Text(dependencyResult["RESPONSE"] ?? "No response"), // Text is from dependencyResult["RESPONSE"]
        actions: [
          TextButton(
            onPressed: () {
              // When "Fail" is clicked, set the result accordingly
              result["RESPONSE"] = "Fail";
              result["OUTCOME"] = "ERROR"; // Outcome is "ERROR" if Fail
  
              // Close the dialog
              Navigator.of(context).pop();
            },
            child: const Text("Fail"),
          ),
          ElevatedButton(
            onPressed: () {
              // When "Pass" is clicked, set the result accordingly
              result["RESPONSE"] = "Pass";
              result["OUTCOME"] = "SUCCESS"; // Outcome is "SUCCESS" if Pass
  
              // Close the dialog
              Navigator.of(context).pop();
            },
            child: const Text("Pass"),
          ),
        ],
      );
    },
  );
}

  return result;
}
