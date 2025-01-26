// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeDNA _$NodeDNAFromJson(Map<String, dynamic> json) => NodeDNA(
      deviceUuid: json['deviceUuid'] as String,
      nodeUuid: json['nodeUuid'] as String,
      nodeFunction:
          NodeFunction.fromJson(json['nodeFunction'] as Map<String, dynamic>),
      nodeName: json['nodeName'] as String,
      nodeColor: json['nodeColor'] as String,
      nodeType: $enumDecode(_$NodeTypeEnumMap, json['nodeType']),
      svgIconString: json['svgIconString'] as String,
    );

Map<String, dynamic> _$NodeDNAToJson(NodeDNA instance) => <String, dynamic>{
      'deviceUuid': instance.deviceUuid,
      'nodeUuid': instance.nodeUuid,
      'nodeFunction': instance.nodeFunction.toJson(),
      'nodeName': instance.nodeName,
      'nodeColor': instance.nodeColor,
      'nodeType': _$NodeTypeEnumMap[instance.nodeType]!,
      'svgIconString': instance.svgIconString,
    };

const _$NodeTypeEnumMap = {
  NodeType.basicNode: 'basicNode',
  NodeType.outputNode: 'outputNode',
};

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
      json['devInfoMessage'] as String,
    );

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'devInfoMessage': instance.devInfoMessage,
    };

NodeParameter _$ParameterFromJson(Map<String, dynamic> json) => NodeParameter(
      name: json['name'] as String,
      type: $enumDecode(_$NodeParameterTypeEnumMap, json['type']),
      hardSet: json['hardSet'] as bool? ?? false,
      hardSetOptionsType: $enumDecodeNullable(
              _$HardSetOptionsTypeEnumMap, json['hardSetOptionsType']) ??
          HardSetOptionsType.directInput,
      hardSetOptions: (json['hardSetOptions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      value: json['value'],
    );

Map<String, dynamic> _$ParameterToJson(NodeParameter instance) => <String, dynamic>{
      'name': instance.name,
      'type': _$NodeParameterTypeEnumMap[instance.type]!,
      'hardSet': instance.hardSet,
      'hardSetOptionsType':
          _$HardSetOptionsTypeEnumMap[instance.hardSetOptionsType]!,
      'hardSetOptions': instance.hardSetOptions,
      'value': instance.value,
    };

const _$NodeParameterTypeEnumMap = {
  NodeParameterType.string: 'string',
  NodeParameterType.number: 'number',
  NodeParameterType.boolean: 'boolean',
  NodeParameterType.none: 'none',
};

const _$HardSetOptionsTypeEnumMap = {
  HardSetOptionsType.selectableList: 'selectableList',
  HardSetOptionsType.directInput: 'directInput',
};

NodeFunction _$NodeFunctionFromJson(Map<String, dynamic> json) => NodeFunction(
      command: json['command'] as String,
      returnType:
          $enumDecode(_$NodeFunctionReturnTypeEnumMap, json['returnType']),
      returnName: json['returnName'] as String? ?? "return",
      parameters: (json['parameters'] as List<dynamic>?)
          ?.map((e) => NodeParameter.fromJson(e as Map<String, dynamic>))
          .toList(),
      executionResult: $enumDecodeNullable(
              _$ExecutionResultEnumMap, json['executionResult']) ??
          ExecutionResult.unknown,
      executionState: $enumDecodeNullable(
              _$ExecutionStateEnumMap, json['executionState']) ??
          ExecutionState.pending,
    );

Map<String, dynamic> _$NodeFunctionToJson(NodeFunction instance) =>
    <String, dynamic>{
      'command': instance.command,
      'returnType': _$NodeFunctionReturnTypeEnumMap[instance.returnType]!,
      'returnName': instance.returnName,
      'parameters': instance.parameters,
      'executionResult': _$ExecutionResultEnumMap[instance.executionResult]!,
      'executionState': _$ExecutionStateEnumMap[instance.executionState]!,
    };

const _$NodeFunctionReturnTypeEnumMap = {
  NodeFunctionReturnType.string: 'string',
  NodeFunctionReturnType.number: 'number',
  NodeFunctionReturnType.boolean: 'boolean',
  NodeFunctionReturnType.none: 'none',
};

const _$ExecutionResultEnumMap = {
  ExecutionResult.success: 'success',
  ExecutionResult.failure: 'failure',
  ExecutionResult.unknown: 'unknown',
};

const _$ExecutionStateEnumMap = {
  ExecutionState.pending: 'pending',
  ExecutionState.executing: 'executing',
  ExecutionState.finished: 'finished',
};

Node _$NodeFromJson(Map<String, dynamic> json) => Node(
      name: json['name'] as String,
      type: $enumDecode(_$NodeTypeEnumMap, json['type']),
      color: json['color'] as String,
      svgIcon: json['svgIcon'] as String,
      function: json['function'] == null
          ? null
          : NodeFunction.fromJson(json['function'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NodeToJson(Node instance) => <String, dynamic>{
      'name': instance.name,
      'type': _$NodeTypeEnumMap[instance.type]!,
      'color': instance.color,
      'svgIcon': instance.svgIcon,
      'function': instance.function,
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
