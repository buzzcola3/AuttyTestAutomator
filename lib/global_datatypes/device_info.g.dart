// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
      json['devInfoMessage'] as String,
    );

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'devInfoMessage': instance.devInfoMessage,
    };

Parameter _$ParameterFromJson(Map<String, dynamic> json) => Parameter(
      name: json['name'] as String,
      type: $enumDecode(_$NodeParameterTypeEnumMap, json['type']),
      hardSet: json['hardSet'] as bool? ?? false,
    );

Map<String, dynamic> _$ParameterToJson(Parameter instance) => <String, dynamic>{
      'name': instance.name,
      'type': _$NodeParameterTypeEnumMap[instance.type]!,
      'hardSet': instance.hardSet,
    };

const _$NodeParameterTypeEnumMap = {
  NodeParameterType.string: 'string',
  NodeParameterType.number: 'number',
  NodeParameterType.boolean: 'boolean',
  NodeParameterType.none: 'none',
};

NodeSetting _$NodeSettingFromJson(Map<String, dynamic> json) => NodeSetting(
      name: json['name'] as String,
      type: $enumDecode(_$NodeSettingTypeEnumMap, json['type']),
      value: json['value'],
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$NodeSettingToJson(NodeSetting instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': _$NodeSettingTypeEnumMap[instance.type]!,
      'value': instance.value,
      'options': instance.options,
    };

const _$NodeSettingTypeEnumMap = {
  NodeSettingType.string: 'string',
  NodeSettingType.number: 'number',
  NodeSettingType.boolean: 'boolean',
  NodeSettingType.list: 'list',
};

FunctionNode _$FunctionNodeFromJson(Map<String, dynamic> json) => FunctionNode(
      command: json['command'] as String,
      returnType:
          $enumDecode(_$NodeFunctionReturnTypeEnumMap, json['returnType']),
      returnName: json['returnName'] as String? ?? "return",
      parameters: (json['parameters'] as List<dynamic>?)
          ?.map((e) => Parameter.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: (json['settings'] as List<dynamic>?)
          ?.map((e) => NodeSetting.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FunctionNodeToJson(FunctionNode instance) =>
    <String, dynamic>{
      'command': instance.command,
      'returnType': _$NodeFunctionReturnTypeEnumMap[instance.returnType]!,
      'returnName': instance.returnName,
      'parameters': instance.parameters,
      'settings': instance.settings,
    };

const _$NodeFunctionReturnTypeEnumMap = {
  NodeFunctionReturnType.string: 'string',
  NodeFunctionReturnType.number: 'number',
  NodeFunctionReturnType.boolean: 'boolean',
  NodeFunctionReturnType.none: 'none',
};

Node _$NodeFromJson(Map<String, dynamic> json) => Node(
      name: json['name'] as String,
      type: $enumDecode(_$NodeTypeEnumMap, json['type']),
      color: json['color'] as String,
      svgIcon: json['svgIcon'] as String,
      function: json['function'] == null
          ? null
          : FunctionNode.fromJson(json['function'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NodeToJson(Node instance) => <String, dynamic>{
      'name': instance.name,
      'type': _$NodeTypeEnumMap[instance.type]!,
      'color': instance.color,
      'svgIcon': instance.svgIcon,
      'function': instance.function,
    };

const _$NodeTypeEnumMap = {
  NodeType.basicNode: 'basicNode',
  NodeType.outputNode: 'inputNode',
};

AvailableNodes _$AvailableNodesFromJson(Map<String, dynamic> json) =>
    AvailableNodes(
      nodes: (json['nodes'] as List<dynamic>?)
          ?.map((e) => Node.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AvailableNodesToJson(AvailableNodes instance) =>
    <String, dynamic>{
      'nodes': instance.nodes,
    };
