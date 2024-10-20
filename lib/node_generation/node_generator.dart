import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';

double _DEFAULT_WIDTH = 180;
const double _DEFAULT_NODE_PADDING = 0; // Keep 0
Color _NODE_CONNECTION_COLOR = Color.fromARGB(255, 109, 109, 109);

NodeWidgetBase generateNode({
  required String name,
  required Widget nodeType,
  required void Function(DragStartDetails) onPanStart,
  required void Function(DragUpdateDetails) onPanUpdate,
  required void Function(DragEndDetails) onPanEnd,
}) {
  return ContainerNodeWidget(
    name: name,
    typeName: 'node_3',
    backgroundColor: Colors.transparent, // Transparent background
    width: _DEFAULT_WIDTH, // Width is fixed
    contentPadding: const EdgeInsets.all(_DEFAULT_NODE_PADDING),
    child: GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: nodeType, // Child widget defines height and appearance
    ),
  );
}



Container generatePreviewNode({
  required Widget nodeType,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.transparent, // Default color for the preview node// Selected border
    ),
    width: _DEFAULT_WIDTH,
    child: nodeType,
  );
}

Widget generateInPort({ bool isDummy = false, required String name }) {
  if (isDummy) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        borderRadius: BorderRadius.circular(4), // Rounded edges
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4), // Rounded edges
            border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
          ),
        ),
      ),
    );
  } else {
    return InPortWidget(
      name: name,
      onConnect: (String name, String port) => true,
      icon: Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(4), // Rounded edges
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white, // White background
              borderRadius: BorderRadius.circular(4), // Rounded edges
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
            ),
          ),
        ),
      ),
      iconConnected: Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(4), // Rounded edges
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white, // Background color when connected
              borderRadius: BorderRadius.circular(4), // Rounded edges
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
            ),
          ),
        ),
      ),
      multiConnections: false,
      connectionTheme: ConnectionTheme(
        color: _NODE_CONNECTION_COLOR,
        strokeWidth: 2,
      ),
    );
  }
}

Widget generateOutPort({ bool isDummy = false, required String name }) {
  if (isDummy) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        borderRadius: BorderRadius.circular(4), // Rounded edges
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white, // Color for dummy port
            borderRadius: BorderRadius.circular(4), // Rounded edges
            border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
          ),
        ),
      ),
    );
  } else {
    return OutPortWidget(
      name: name,
      icon: Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(4), // Rounded edges
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white, // White background
              borderRadius: BorderRadius.circular(4), // Rounded edges
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
            ),
          ),
        ),
      ),
      iconConnected: Container(
        width: 19,
        height: 19,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(4), // Rounded edges
        ),
        child: Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white, // Background color when connected
              borderRadius: BorderRadius.circular(4), // Rounded edges
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1),
            ),
          ),
        ),
      ),
      multiConnections: false,
      connectionTheme: ConnectionTheme(
        color: _NODE_CONNECTION_COLOR,
        strokeWidth: 2,
      ),
    );
  }
}



Widget basicNode({
  bool isDummy = false,
  Color accentColor = Colors.lightBlue,
  Color color = Colors.lightBlueAccent,
  String? command, // New parameter for node text
  String? deviceUniqueId,
  List<String>? inPorts, // Nullable lists
  List<String>? outPorts,
}) {
  inPorts ??= ["inPort0"]; // Default value if not provided
  outPorts ??= ["outPort0"]; // Default value if not provided

  // Calculate the height based on the number of inPorts and outPorts
  int numberOfPorts = (inPorts.length > outPorts.length) ? inPorts.length : outPorts.length;
  double calculatedHeight = 20 * numberOfPorts + 20;

  return Container(
    height: calculatedHeight, // Set the height for the transparent container
    color: Colors.transparent, // Make the container transparent
    child: Stack(
      clipBehavior: Clip.none, // Allow the ports to overflow the node bounds
      children: [
        // Main node container with border and radius, wrapped in a Center widget
        Center(
          child: Container(
            height: calculatedHeight - 3, // Set the calculated height for the entire node
            decoration: BoxDecoration(
              color: color, // Apply the main color to the node
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1), // Thin border
              borderRadius: BorderRadius.circular(5), // Rounded corners for both sides
            ),
            child: Row(
              children: [
                // Left side accent color section with rounded corners
                Container(
                  width: 40, // Fixed width for accent color section
                  decoration: BoxDecoration(
                    color: accentColor, // Apply the accent color to the left side
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(5)), // Rounded corners for the left side
                  ),
                  child: Center(
                    child: Icon(Icons.safety_divider, color: Colors.white), // Move the icon here
                  ),
                ),
                // Vertical divider where the blue meets the accent blue
                Container(
                  width: 0.7, // Thin width for the divider
                  color: _NODE_CONNECTION_COLOR, // Same color as the border
                ),
                // Right side main section for the node content
                Expanded(
                  child: Container(
                    color: Colors.transparent, // Keep transparent to let the border show
                    child: Center(
                      child: Text(
                        command ?? '', // Display the node text, default to empty string if null
                        style: TextStyle(color: Colors.black), // Customize the text style as needed
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Overlay for in-ports (left side)
        Positioned(
          left: -9.5, // Stick out by 9.5px (half of port size)
          top: 0,
          bottom: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space in-ports vertically
            children: inPorts.map((portName) {
              return generateInPort(isDummy: isDummy, name: portName);
            }).toList(),
          ),
        ),
        // Overlay for out-ports (right side)
        Positioned(
          right: -9.5, // Stick out by -9.5px (half of port size)
          top: 0,
          bottom: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space out-ports vertically
            children: outPorts.map((portName) {
              return generateOutPort(isDummy: isDummy, name: portName);
            }).toList(),
          ),
        ),
      ],
    ),
  );
}


Widget buttonNode({
  bool isDummy = false,
  Color accentColor = Colors.lightBlue,
  Color color = Colors.lightBlueAccent,
  String? command, // New parameter for node text
  String? deviceUniqueId,
  List<String>? inPorts, // Nullable lists
  List<String>? outPorts,
}) {
  inPorts ??= ["inPort0"]; // Default value if not provided
  outPorts ??= ["outPort0"]; // Default value if not provided

  // Calculate the height based on the number of inPorts and outPorts
  int numberOfPorts = (inPorts.length > outPorts.length) ? inPorts.length : outPorts.length;
  double calculatedHeight = 20 * numberOfPorts + 20;

  return Container(
    height: calculatedHeight, // Set the height for the transparent container
    color: Colors.transparent, // Make the container transparent
    child: Stack(
      clipBehavior: Clip.none, // Allow the ports to overflow the node bounds
      children: [
        // Main node container with border and radius, wrapped in a Center widget
        Center(
          child: Container(
            height: calculatedHeight - 3, // Set the calculated height for the entire node
            decoration: BoxDecoration(
              color: color, // Apply the main color to the node
              border: Border.all(color: _NODE_CONNECTION_COLOR, width: 1), // Thin border
              borderRadius: BorderRadius.circular(5), // Rounded corners for both sides
            ),
            child: Row(
              children: [
                // Left side accent color section with rounded corners
                Container(
                  width: 40, // Fixed width for accent color section
                  decoration: BoxDecoration(
                    color: accentColor, // Apply the accent color to the left side
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(5)), // Rounded corners for the left side
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24.0,
                      height: 24.0,
                      child: ElevatedButton(
                        onPressed: () {
                          // Add button logic here
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // Remove default padding
                          shape: CircleBorder() // Make the button circular
                        ),
                        child: Icon(
                          Icons.safety_divider, // Keep the icon inside the button
                          color: Colors.white,
                          size: 18.0, // Adjust the icon size
                        ),
                      ),
                    ),
                  ),
                ),
                // Vertical divider where the blue meets the accent blue
                Container(
                  width: 0.7, // Thin width for the divider
                  color: _NODE_CONNECTION_COLOR, // Same color as the border
                ),
                // Right side main section for the node content
                Expanded(
                  child: Container(
                    color: Colors.transparent, // Keep transparent to let the border show
                    child: Center(
                      child: Text(
                        command ?? '', // Display the node text, default to empty string if null
                        style: TextStyle(color: Colors.black), // Customize the text style as needed
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Overlay for in-ports (left side)
        Positioned(
          left: -9.5, // Stick out by 9.5px (half of port size)
          top: 0,
          bottom: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space in-ports vertically
            children: inPorts.map((portName) {
              return generateInPort(isDummy: isDummy, name: portName);
            }).toList(),
          ),
        ),
        // Overlay for out-ports (right side)
        Positioned(
          right: -9.5, // Stick out by -9.5px (half of port size)
          top: 0,
          bottom: 0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space out-ports vertically
            children: outPorts.map((portName) {
              return generateOutPort(isDummy: isDummy, name: portName);
            }).toList(),
          ),
        ),
      ],
    ),
  );
}
