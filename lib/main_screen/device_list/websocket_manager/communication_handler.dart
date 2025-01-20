import 'dart:async';

import 'package:Autty/global_datatypes/device_info.dart';
import 'package:Autty/global_datatypes/ip_address.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum RemoteDeviceState {
    uninit,   // Represents a new state
    open,  // Represents an open state
    closed // Represents a closed state
}

class RemoteDevice {
    RemoteDeviceState state = RemoteDeviceState.uninit;

    final IPAddress deviceIp;

    late DeviceInfo deviceInfo;

    late final Client _rpcClient;
    late final WebSocketChannel _wsChannel;

    
    RemoteDevice({
        required this.deviceIp
    }){
        _wsChannel = WebSocketChannel.connect(Uri.parse('ws://$deviceIp'));
        _rpcClient = Client(_wsChannel.cast<String>());
    }

    // Dummy constructor
    RemoteDevice.dummy({
      required this.deviceIp,
      required this.deviceInfo,
    }) {
      state = RemoteDeviceState.open; // Set state as open for dummy
    }

    Future<bool> open() async {
        if (state == RemoteDeviceState.open) {
           return true;
        }

      try {
        _rpcClient.listen();
        state = RemoteDeviceState.open;
        final String rawDeviceInfo = await callRemoteFunction("DEVINFO", {});
        deviceInfo = DeviceInfo(rawDeviceInfo);
        return true; // Return true if the operation succeeds
      } catch (e) {
        state = RemoteDeviceState.closed;
        print('Error occurred: $e'); // Optional: Log the error for debugging
        return false; // Return false if an exception occurs
      }
    }

    void close(){
        state = RemoteDeviceState.closed;
        _rpcClient.close();
    }

    Future<bool> refetchDeviceInfo() async {
      if (state != RemoteDeviceState.open) {
        throw StateError('Cannot call remote function: Device is not in the open state.');
      }
    
      try {
        // Fetch device information using the "DEVINFO" method
        final rawDeviceInfo = await callRemoteFunction("DEVINFO", {});
        deviceInfo = DeviceInfo(rawDeviceInfo);
    
        // Return true to indicate success
        return true;
      } catch (e) {
        // Handle errors (e.g., logging the exception)
        print('Error fetching device info: $e');
    
        // Return false to indicate failure
        return false;
      }
    }



  Future<dynamic> callRemoteFunction(String method, Map<String, dynamic> parameters) async {
    if (state != RemoteDeviceState.open) {
      throw StateError('Cannot call remote function: Device is not in the open state.');
    }

    return await _rpcClient.sendRequest(method, parameters);
  }

  Future<double> roundtripTime() async {
    if (state != RemoteDeviceState.open) {
      throw StateError('Cannot measure roundtrip time: Device is not in the open state.');
    }
  
    // Record the start time
    final startTime = DateTime.now();
  
    // Send the request and wait for the response
    await _rpcClient.sendRequest('ping');
  
    // Record the end time
    final endTime = DateTime.now();
  
    // Calculate the round-trip time in milliseconds
    final roundTripTime = endTime.difference(startTime).inMilliseconds.toDouble();
  
    return roundTripTime;
  }

}