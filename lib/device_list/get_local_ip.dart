import 'dart:async';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/material.dart';



Future<String> fetchIpAddress() async {
  final networkInfo = NetworkInfo();

  try {
    // Attempt to fetch IP address with a 100ms timeout
    final ipAddress = await networkInfo.getWifiIP().timeout(
      Duration(milliseconds: 100),
      onTimeout: () => 'Timeout: Unable to fetch IP address within 100ms',
    );

    return ipAddress ?? '';  // Return the IP or an empty string if null
  } catch (e) {
    print("Failed to get IP address: $e");
    return '';  // Return empty string on failure
  }
}



Widget ipAddressAsk() {
  return ListView.builder(
    itemCount: 3,  // Number of devices
    itemBuilder: (context, index) {
      return ListTile(
        title: Text('Device ${index + 1}'),
        leading: Icon(Icons.devices),  // Optional: Icon to represent each device
        trailing: Icon(Icons.arrow_forward),  // Optional: Arrow to indicate interaction
//        onTap: () {
//          // Handle tap event if needed
//        },
      );
    },
  );
}