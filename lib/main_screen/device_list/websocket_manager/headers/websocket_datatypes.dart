import 'dart:async';

import 'package:Autty/global_datatypes/ip_address.dart';
import 'package:uuid/uuid.dart';

class WsMessage {
  // Properties
  IPAddress deviceIp;
  String message;
  late String uuid;
  String? rawResponse;
  dynamic response;
  bool fulfilled = false;
  int resendCount = 0;  // New property to track duplicates


  final void Function(String)? resendRequest;
  Timer? _statusCheckTimer;
  String lastStatus = "";

  // Constructor
  WsMessage({
    required this.deviceIp, 
    required this.message, 
    this.resendRequest,
  }) {
    const messageUuid = Uuid();
    uuid = messageUuid.v1();
    _startStatusCheck();
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
      if (!fulfilled) {
        resendRequest!(uuid);
        resendCount++;
      } else {
        _statusCheckTimer?.cancel();
      }
    });
  }

  @override
  String toString() {
    return 'WsMessage(source: $deviceIp, message: $message, fulfilled: $fulfilled, duplicates: $resendCount)';
  }
}


class WsMessageList {
  List<WsMessage> messages = [];

  // Method to add a WsMessage to the list, with duplicate counting
  void addMessage(WsMessage message) {
    messages.add(message);  // Add new message if no duplicate
  }

  // Method to search for a WsMessage by UUID
  WsMessage? searchMessage(String messageUuid) {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].uuid == messageUuid) {
        return messages[i];
      }
    }
    return null;
  }


  // Method to search for a WsMessage starting from the most recent (last) message
  WsMessage? searchUnfulfilledMessage(String messageUuid) {
    for (int i = messages.length - 1; i >= 0; i--) {
      WsMessage message = messages[i];
      if (message.uuid == messageUuid) {
        if(message.fulfilled == false){
          return message;
        }
        
      }
    }
    return null; // Return null if no match is found
  }

  // Method to return all messages as a list
  List<WsMessage> getAllMessages() {
    return messages;
  }
}

/* Request-Response Process:

A request is sent, and a confirmation response is awaited.
The system checks the response status every 2 seconds, which can be one of the following states:
Pending (0x00): If the request is still being processed or not yet fulfilled.
Fulfilled (0x01): If the request has been completed and the response is ready.
Once the status is fulfilled, the actual response is sent.
Response Structure:

Type: Specifies the data type of the response (e.g., string, integer, or float).
Result: Indicates the outcome of the request, which can be:
Success: The operation was completed successfully.
Fail: The operation did not complete successfully.
Error: An error occurred during processing.

 +-------------------------+
 |          AUTTY          |
 +-------------------------+
              |
        Send Request
              |
              v
 +-------------------------+
 |        WS Device        |
 +-------------------------+
              |
     Wait for Confirmation
              |
              v
 +-------------------------+
 |  Response Status Check  |
 |    Every 2 Seconds:     |
 |  [Pending | Fulfilled]  |
 +-------------------------+
             |
     When "Fulfilled"
             |
             v               
+----------------------------+    
|       SEND RESPONSE        |    
|----------------------------|    
| Type: [string/int/float]   |  
| Result: [success/fail/err] | 
+----------------------------+    


Client:
Listen for requests: The client continuously listens for incoming requests from the server.

When a request comes: Once a request is received, the client triggers the execution process to handle the request.

After execution: When the execution is complete, the client triggers the process to send the response back to the server.

On status request: The client responds to status requests with:

Pending (0x00): If the request is still being processed or not yet fulfilled.
Fulfilled (0x01): If the request has been completed and the response is ready.
Response behavior:

If the request is fulfilled, the client prepares the response and sends it back to the server.
If the request is still pending, the client sends the "pending" status (0x00) until the request is completed.


+----------------------------+
|         IDLE                |
| (Waiting for Request)       |
+----------------------------+
           |
           | Request Received
           v
+----------------------------+
|     EXECUTING REQUEST      | --> if timed, setup a future trigger, that triggers at just the right time
| (Trigger Executor)         |
+----------------------------+
           |
           | Execution Done
           v
+----------------------------+
|     WAITING FOR RESPONSE   |
| (Send Fulfilled/ Pending)  |
+----------------------------+
           |
   +----------------------+
   |                      |
   | Status Request       |
   v                      v
+-------------------+  +-------------------+
|     PENDING (0x00)|  |   FULFILLED (0x01) |
+-------------------+  +-------------------+
           |                    |
  (Continue Waiting)        (Send Response)
           |                    |
           +--------------------+
           |
           v
+----------------------------+
|     BACK TO IDLE           |
+----------------------------+
*/