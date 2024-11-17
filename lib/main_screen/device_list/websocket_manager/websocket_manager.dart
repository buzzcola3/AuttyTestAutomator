import 'package:attempt_two/main_screen/device_list/websocket_manager/headers/websocket_datatypes.dart';
import 'package:attempt_two/main_screen/device_list/websocket_manager/ip_scanner/ip_scanner.dart';
import 'package:attempt_two/global_datatypes/ip_address.dart';

class WebsocketManager {
  late IPScanner ipScanner;
  final WsDeviceList deviceList = WsDeviceList();

  WebsocketManager() {
    ipScanner = IPScanner(notifyChangeIPScanner: ipScannerChangeHandle);
  }

  List<Function()> deviceListChangeCallbacks = [];

  void ipScannerChangeHandle(){
    for (var respondingDevice in ipScanner.respondingDevices) {
      connectDevice(respondingDevice);
    }
  }

  Future<WsMessage?> sendAwaitedRequest(String deviceUniqueId, command, parameters) async {
    WsDevice? targetDevice = deviceList.findDevice(deviceUniqueId);
    WsMessage? requestMessage = await targetDevice?.sendAwaitedRequest(command, parameters);
    return requestMessage;
  }

  Future<void> connectDevice(IPAddress deviceIp) async {

    for (var existingDevice in deviceList.devices) {
      if(existingDevice.getIPAddress == deviceIp){
        return;
      }
    }

    WsDevice newDevice = WsDevice(ipAddress: deviceIp);

    while (newDevice.ready == false) {
      await Future.delayed(const Duration(milliseconds: 100)); // adjust delay as needed
    }
    deviceList.addDevice(newDevice);

    for (var callback in deviceListChangeCallbacks) {
      print("CALLBACK");
      callback();
    }

  }

  void disconnectDevice(){

  }

  void reconnectDevice(){

  }

  void loadRespondingDevices(){
    
  }

  void saveRespondingDevices(){

  }

  void sendMessage(){

  }

  void sendRequest(){

  }
}
