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

import 'package:Autty/main.dart';
import 'dart:async';
import 'package:Autty/main_screen/communication_panel/communication_panel.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/communication_handler.dart';
import 'package:Autty/main_screen/device_list/websocket_manager/ip_scanner/ip_scanner.dart';
import 'package:Autty/global_datatypes/ip_address.dart';


class WebsocketManager {
  late IPScanner ipScanner;
  final Map<String, RemoteDevice> deviceList = {};

  List<Function()> deviceListChangeCallbacks = [];

  bool aliveTest = false;
  Timer? _aliveTestTimer;

  WebsocketManager() {

    ipScanner = IPScanner(notifyChangeIPScanner: ipScannerChangeHandle);

    enableAliveTest();
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

void _startAliveTest() {
  int currentIndex = 0;
  Set<String> activeDevices = {}; // Track devices currently being checked
  _aliveTestTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
    List<String> deviceKeys = deviceList.keys.toList();
    if (deviceKeys.isNotEmpty) {
      currentIndex = currentIndex % deviceKeys.length;
      var deviceKey = deviceKeys[currentIndex];
      currentIndex = (currentIndex + 1) % deviceKeys.length;

      // Skip devices already being checked
      if (!activeDevices.contains(deviceKey)) {
        activeDevices.add(deviceKey); // Mark as active
        try {
          await deviceList[deviceKey]?.checkAlive();

          // Handle closed state
          if (deviceList[deviceKey]?.state == RemoteDeviceState.closed) {
            deviceList.remove(deviceKey);
            for (var callback in deviceListChangeCallbacks) {
              callback(); // Notify callbacks
            }
            print("removed unresponsive device");
          }
        } catch (e) {
          print("Error checking device $deviceKey: $e");
        } finally {
          activeDevices.remove(deviceKey); // Mark as inactive
        }
      }else{print("skip");}
    }
  });
}

Future<bool> requiredDevicesAvailable(List<String> requiredDeviceUuids) async {
  for (var requiredUuid in requiredDeviceUuids) {
    // Find the matching device in the deviceList
    RemoteDevice? matchingDevice;
    try {
      matchingDevice = deviceList.values.firstWhere(
        (device) =>
            device.deviceInfo.deviceUniqueId == requiredUuid &&
            device.state != RemoteDeviceState.closed,
      );
    } catch (e) {
      // Handle the case where no matching device is found
      print("No matching device found");
      // You can add additional logic here if needed
    }

    if (matchingDevice != null) {
      // If the device exists, perform the checkAlive call
      await matchingDevice.checkAlive();
      if(matchingDevice.state == RemoteDeviceState.closed){
        return false;
      }

    } else {
      // If the device does not exist, return false
      return false;
    }
  }

  // If all required devices are available and alive, return true
  return true;
}



  void enableAliveTest() {
    if (!aliveTest) {
      aliveTest = true;
      _startAliveTest();
    }
  }

  void disableAliveTest() {
    if (aliveTest) {
      aliveTest = false;
      _aliveTestTimer?.cancel();
    }
  }

}
