import 'dart:convert';

class DeviceInfo {

  String devInfoMessage;
  late Map<String, dynamic> _devInfo;

  late String _deviceUniqueId;
  late String _deviceName;
  late String _deviceDescription;
  late List<String> _deviceAvailableCommands;
  late List<Map<String, dynamic>> _deviceAvailableNodes;
  late String _deviceIconSvg;



  DeviceInfo(this.devInfoMessage){
    _devInfo = jsonDecode(devInfoMessage);

    _deviceUniqueId = _devInfo["UNIQUE_ID"];
    _deviceName = _devInfo["DEVICE_NAME"];
    _deviceDescription = _devInfo["DEVICE_DESCRIPTION"];
    _deviceAvailableCommands = (_devInfo["DEVICE_AVAILABLE_COMMANDS"] as List<dynamic>).map((item) => item.toString()).toList();
    _deviceAvailableNodes = (_devInfo["DEVICE_AVAILABLE_NODES"] as List<dynamic>).map((item) => item as Map<String, dynamic>).toList();
    _deviceIconSvg = _devInfo["DEVICE_ICON_SVG"];
    
  }

  String get deviceUniqueId => _deviceUniqueId;
  String get deviceName => _deviceName;
  String get deviceDescription => _deviceDescription;
  List<String> get deviceAvailableCommands => _deviceAvailableCommands;
  List<Map<String, dynamic>> get deviceAvailableNodes => _deviceAvailableNodes;
  String get deviceIconSvg => _deviceIconSvg;

}