import 'package:Autty/main.dart';
import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/communication_handler.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/headers/websocket_datatypes.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/ip_scanner/ip_scanner.dart';
import 'package:Autty/global_datatypes/ip_address.dart';


class WebsocketManager {
  late IPScanner ipScanner;
  final Map<String, RemoteDevice> deviceList = {};

  List<Function()> deviceListChangeCallbacks = [];

  WebsocketManager() {

    ipScanner = IPScanner(notifyChangeIPScanner: ipScannerChangeHandle);
  }

  void ipScannerChangeHandle(){
    for (var respondingDevice in ipScanner.respondingDevices) {
      connectDevice(respondingDevice);
    }

    for (var callback in deviceListChangeCallbacks) { //TODO workaround to get loading indicator to work, make a standalone callback in ipScanner
      callback();
    }
  }

  dynamic sendAwaitedRequest(String deviceUniqueId, String command, Map<String, dynamic> parameters) async {
    RemoteDevice? targetDevice = deviceList[deviceUniqueId];

    return await targetDevice?.callRemoteFunction(command, parameters);
  }

  Future<void> connectDevice(IPAddress deviceIp) async {

    for (var existingDevice in deviceList.values) {
      if(existingDevice.deviceIp == deviceIp){
        return;
      }
    }

    RemoteDevice newDevice = RemoteDevice(deviceIp: deviceIp);
    await newDevice.open();

    int timeoutCount = 0;

    while (newDevice.state != RemoteDeviceState.open) { 
      await Future.delayed(const Duration(milliseconds: 100)); // adjust delay as needed
      timeoutCount += 1;

      if(timeoutCount >= 50){
        debugConsoleController.addInternalTabMessage("failed to connecto to ${deviceIp.toString()}", MessageType.error);
        return;
      } //5 seconds
    }
    deviceList[newDevice.deviceInfo.deviceUniqueId] = newDevice;

    for (var callback in deviceListChangeCallbacks) {
      print("CALLBACK");
      callback();
    }

  }

  void disconnectDevice(){

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
