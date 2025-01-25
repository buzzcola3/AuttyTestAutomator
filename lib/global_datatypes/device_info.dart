import 'dart:convert';
import 'package:Autty/global_datatypes/json.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';

@JsonSerializable(explicitToJson: true)
class NodeDNA {
  String deviceUuid;
  String nodeUuid;
  FunctionNode nodeFunction;
  String nodeName;
  String nodeColor;
  NodeType nodeType;
  String svgIconString;

  NodeDNA({
    required this.deviceUuid,
    required this.nodeUuid,
    required this.nodeFunction,
    required this.nodeName,
    required this.nodeColor,
    required this.nodeType,
    required this.svgIconString,
  });

  // Factory constructor for creating a NodeDNA from JSON
  factory NodeDNA.fromJson(Map<String, dynamic> json) => _$NodeDNAFromJson(json);

  // Converts a NodeDNA instance to JSON
  Map<String, dynamic> toJson() => _$NodeDNAToJson(this);
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

@JsonSerializable()
class DeviceInfo {

  String devInfoMessage;
  late Json _devInfo;

  late String _deviceUniqueId;
  late String _deviceName;
  late String _deviceDescription;
  late AvailableNodes _deviceAvailableNodes;
  late String _deviceIconSvg;

  DeviceInfo(this.devInfoMessage) {
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

  // Factory constructor for creating a DeviceInfo from JSON
  factory DeviceInfo.fromJson(Map<String, dynamic> json) => _$DeviceInfoFromJson(json);

  // Converts a DeviceInfo instance to JSON
  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);
}

@JsonEnum(alwaysCreate: true)
enum HardSetOptionsType {
  selectableList,
  directInput
}
extension HardSetOptionsTypeExtension on HardSetOptionsType {
  String toJson() => _$HardSetOptionsTypeEnumMap[this]!;
  static HardSetOptionsType fromJson(String json) => _$HardSetOptionsTypeEnumMap.entries
      .firstWhere((element) => element.value == json)
      .key;
}
// Represents a parameter for a function
@JsonSerializable()
class Parameter {
  String name;
  NodeParameterType type;
  bool hardSet = false;
  HardSetOptionsType hardSetOptionsType = HardSetOptionsType.directInput;
  List<String> hardSetOptions = [];
  dynamic value;

  Parameter({required this.name, required this.type, this.hardSet = false, this.hardSetOptionsType = HardSetOptionsType.directInput, this.hardSetOptions = const [], this.value});

  // Factory constructor for creating a Parameter from JSON
  factory Parameter.fromJson(Map<String, dynamic> json) {
    return Parameter(
      name: json['Name'],
      type: NodeParameterTypeExtension.fromJson(json['Type']),
      hardSet: json['HardSet'] ?? false,
      hardSetOptionsType: HardSetOptionsTypeExtension.fromJson(json['HardSetOptionsType']),
      hardSetOptions: json['HardSetOptions'] != null
          ? List<String>.from(json['HardSetOptions'])
          : [],
      value: json['Value'],
    );
  }

  // Converts a Parameter instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'Name': name,
      'Type': type.toJson(),
      'HardSet': hardSet,
      'HardSetOptionsType': hardSetOptionsType.toJson(),
      'HardSetOptions': hardSetOptions,
      'Value': value,
    };
  }
}

//function to validate if return type is valid
bool isValidReturnType(NodeFunctionReturnType returnType, dynamic value) {
  switch (returnType) {
    case NodeFunctionReturnType.string:
      return value is String;
    case NodeFunctionReturnType.number:
      return value is num;
    case NodeFunctionReturnType.boolean:
      return value is bool;
    case NodeFunctionReturnType.none:
      return value == null;
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

  FunctionNode({
    required this.command,
    required this.returnType,
    this.returnName = "return",
    this.parameters,
  });

  // Factory constructor for creating a FunctionNode from JSON
  factory FunctionNode.fromJson(Map<String, dynamic> json) {
    var paramList = json['Parameters'] as List<dynamic>? ?? [];
    return FunctionNode(
      command: json['Command'],
      returnType: NodeFunctionReturnTypeExtension.fromJson(json['ReturnType']),
      returnName: json['ReturnName'],
      parameters: paramList.map((p) => Parameter.fromJson(p)).toList(),
    );
  }

  // Converts a FunctionNode instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'Command': command,
      'ReturnType': returnType.toJson(), // Ensure toJson is called here
      'ReturnName': returnName,
      'Parameters': parameters?.map((p) => p.toJson()).toList(),
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
      'Type': type.toJson(), // Ensure toJson is called here
      'Color': color,
      'SvgIcon': svgIcon,
      'Function': function!.toJson(),
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
