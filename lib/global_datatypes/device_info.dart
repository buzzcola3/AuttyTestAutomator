import 'dart:convert';
import 'package:Autty/global_datatypes/json.dart';

class DeviceInfo {

  String devInfoMessage;
  late Json _devInfo;

  late String _deviceUniqueId;
  late String _deviceName;
  late String _deviceDescription;
  late List<String> _deviceAvailableCommands;
  late List<Json> _deviceAvailableNodes;
  late String _deviceIconSvg;



  DeviceInfo(this.devInfoMessage){
    _devInfo = jsonDecode(devInfoMessage);

    _deviceUniqueId = _devInfo["UNIQUE_ID"];
    _deviceName = _devInfo["DEVICE_NAME"];
    _deviceDescription = _devInfo["DEVICE_DESCRIPTION"];
    _deviceAvailableCommands = (_devInfo["DEVICE_AVAILABLE_COMMANDS"] as List<dynamic>).map((item) => item.toString()).toList();
    _deviceAvailableNodes = (_devInfo["DEVICE_AVAILABLE_NODES"] as List<dynamic>).map((item) => item as Json).toList();
    _deviceIconSvg = _devInfo["DEVICE_ICON_SVG"];
    
  }

  String get deviceUniqueId => _deviceUniqueId;
  String get deviceName => _deviceName;
  String get deviceDescription => _deviceDescription;
  List<String> get deviceAvailableCommands => _deviceAvailableCommands;
  List<Json> get deviceAvailableNodes => _deviceAvailableNodes;
  String get deviceIconSvg => _deviceIconSvg;

}