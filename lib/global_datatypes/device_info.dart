import 'dart:convert';
import 'package:Autty/global_datatypes/json.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';

@JsonSerializable()
class DeviceInfo {

  String devInfoMessage;
  late Json _devInfo;

  late String _deviceUniqueId;
  late String _deviceName;
  late String _deviceDescription;
  late AvailableNodes _deviceAvailableNodes;
  late String _deviceIconSvg;



  DeviceInfo(this.devInfoMessage){
    _devInfo = jsonDecode(devInfoMessage);

    _deviceUniqueId = _devInfo["UNIQUE_ID"];
    _deviceName = _devInfo["DEVICE_NAME"];
    _deviceDescription = _devInfo["DEVICE_DESCRIPTION"];
    _deviceAvailableNodes = AvailableNodes.fromJson(_devInfo["DEVICE_AVAILABLE_NODES"]);
    _deviceIconSvg = _devInfo["DEVICE_ICON_SVG"];
    
  }

  String get deviceUniqueId => _deviceUniqueId;
  String get deviceName => _deviceName;
  String get deviceDescription => _deviceDescription;
  AvailableNodes get deviceAvailableNodes => _deviceAvailableNodes;
  String get deviceIconSvg => _deviceIconSvg;

}

@JsonEnum(alwaysCreate: true)
enum NodeParameterType {
  string,
  number,
  boolean,
  none
}
extension NodeParameterTypeExtension on NodeParameterType {
  String toJson() => _$NodeParameterTypeEnumMap[this]!;
  static NodeParameterType fromJson(String json) => _$NodeParameterTypeEnumMap.entries
      .firstWhere((element) => element.value == json)
      .key;
}
// Represents a parameter for a function
@JsonSerializable()
class Parameter {
  String name;
  NodeParameterType type;
  bool hardSet = false;

  Parameter({required this.name, required this.type, this.hardSet = false});

  // Factory constructor for creating a Parameter from JSON
  factory Parameter.fromJson(Map<String, dynamic> json) {
    return Parameter(
      name: json['Name'],
      type: NodeParameterTypeExtension.fromJson(json['Type']),
      hardSet: json['HardSet'] ?? false,
    );
  }

  // Converts a Parameter instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Type': type.toJson(),
      'HardSet': hardSet,
    };
  }
}

@JsonEnum(alwaysCreate: true)
enum NodeSettingType {
  string,
  number,
  boolean,
  list,
}
extension NodeSettingTypeExtension on NodeSettingType {
  String toJson() => _$NodeSettingTypeEnumMap[this]!;
  static NodeSettingType fromJson(String json) => _$NodeSettingTypeEnumMap.entries
      .firstWhere((element) => element.value == json)
      .key;
}
// Represents a parameter for a function
@JsonSerializable()
class NodeSetting {
  String name;
  NodeSettingType type;
  dynamic value; //TODO limit to just string? dynamic may not be json serializable
  List<String>? options;
  

  NodeSetting({required this.name, required this.type, this.value ,this.options});

  // Factory constructor for creating a Parameter from JSON
  factory NodeSetting.fromJson(Map<String, dynamic> json) {
    return NodeSetting(
      name: json['Name'],
      type: NodeSettingTypeExtension.fromJson(json['Type']),
      value: json['Value'],
      options: json['Options'] != null ? List<String>.from(json['Options']) : null,
    );
  }

  // Converts a Parameter instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Type': type.toJson(),
      'Options': options,
    };
  }
}

@JsonEnum(alwaysCreate: true)
enum NodeFunctionReturnType {
  string,
  number,
  boolean,
  none
}
extension NodeFunctionReturnTypeExtension on NodeFunctionReturnType {
  String toJson() => _$NodeFunctionReturnTypeEnumMap[this]!;
  static NodeFunctionReturnType fromJson(String json) => _$NodeFunctionReturnTypeEnumMap.entries
      .firstWhere((element) => element.value == json)
      .key;
}
// Represents a function associated with a node
@JsonSerializable()
class FunctionNode {
  String command;
  NodeFunctionReturnType returnType;
  String returnName;
  List<Parameter>? parameters;
  List<NodeSetting>? settings;

  FunctionNode({
    required this.command,
    required this.returnType,
    this.returnName = "return",
    this.parameters,
    this.settings,
  });

  // Factory constructor for creating a FunctionNode from JSON
  factory FunctionNode.fromJson(Map<String, dynamic> json) {
    var paramList = json['Parameters'] as List<dynamic>? ?? [];
    var settingsList = json['Settings'] as List<dynamic>? ?? [];
    return FunctionNode(
      command: json['Command'],
      returnType: NodeFunctionReturnTypeExtension.fromJson(json['ReturnType']),
      returnName: json['ReturnName'],
      parameters: paramList.map((p) => Parameter.fromJson(p)).toList(),
      settings: settingsList.map((s) => NodeSetting.fromJson(s)).toList(),
    );
  }

  // Converts a FunctionNode instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'Command': command,
      'ReturnType': returnType.toJson(), // Ensure toJson is called here
      'ReturnName': returnName,
      'Parameters': parameters?.map((p) => p.toJson()).toList(),
      'Settings': settings?.map((s) => s.toJson()).toList(),
    };
  }
}

@JsonEnum(alwaysCreate: true)
enum NodeType {
  basicNode,
  outputNode
}

extension NodeTypeExtension on NodeType {
  String toJson() => _$NodeTypeEnumMap[this]!;
  static NodeType fromJson(String json) => _$NodeTypeEnumMap.entries
      .firstWhere((element) => element.value == json)
      .key;
}

// Represents a node with a function
@JsonSerializable()
class Node {
  String name;
  NodeType type;
  String color;
  String svgIcon;
  FunctionNode? function;

  Node({
    required this.name,
    required this.type,
    required this.color,
    required this.svgIcon,
    this.function,
  });

  // Factory constructor for creating a Node from JSON
  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      name: json['Name'],
      type: NodeTypeExtension.fromJson(json['Type']),
      color: json['Color'],
      svgIcon: json['SvgIcon'],
      function: json['Function'] != null
          ? FunctionNode.fromJson(json['Function'])
          : null,
    );
  }

  // Converts a Node instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Type': type.toJson(),
      'Color': color,
      'SvgIcon': svgIcon,
      'Function': function?.toJson(),
    };
  }
}

// Manages a collection of nodes
@JsonSerializable()
class AvailableNodes {
  List<Node> nodes;

  AvailableNodes({List<Node>? nodes}) : nodes = nodes ?? [];

  // Factory constructor for creating AvailableNodes from JSON
  factory AvailableNodes.fromJson(List<dynamic> jsonList) {
    return AvailableNodes(
      nodes: jsonList.map((n) => Node.fromJson(n)).toList(),
    );
  }

  // Converts an AvailableNodes instance to JSON
  List<Map<String, dynamic>> toJson() {
    return nodes.map((n) => n.toJson()).toList();
  }
}
