import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:node_editor/node_editor.dart';


double _DEFAULT_WIDTH = 180;
const double _DEFAULT_NODE_PADDING = 0; // Keep 0
Color _NODE_CONNECTION_COLOR = const Color.fromARGB(255, 109, 109, 109);
const double _NODE_EDGE_RADIUS = 6;

NodeWidgetBase generateNode({
  required Widget nodeType,

  required String nodeUuid,

  required void Function(DragStartDetails) onPanStart,
  required void Function(DragUpdateDetails) onPanUpdate,
  required void Function(DragEndDetails) onPanEnd,
  required GestureTapCallback onTap,
}) {

  
  return ContainerNodeWidget(
    name: nodeUuid,
    typeName: 'node',
    selectedBorder: Border.all(color: Colors.white),
    border: Border.all(color: Colors.transparent),
    radius: _NODE_EDGE_RADIUS,
    backgroundColor: Colors.transparent, // Transparent background
    width: _DEFAULT_WIDTH, // Width is fixed
    contentPadding: const EdgeInsets.all(_DEFAULT_NODE_PADDING),
    child: GestureDetector(
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: nodeType, // Child widget defines height and appearance
    ),
  );
}

Container generatePreviewNode({
  required Widget? nodeType,
}) {
  return Container(
    decoration: const BoxDecoration(
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

Color getNodeAccentColor(String colorName) {
  // Map of base colors to their accent equivalents
  Map<String, Color> colorMap = {
    'red': Colors.redAccent,
    'blue': Colors.blueAccent,
    'green': Colors.greenAccent,
    'yellow': Colors.yellowAccent,
    'purple': Colors.purpleAccent,
    'orange': Colors.orangeAccent,
    'pink': Colors.pinkAccent,
    'teal': Colors.tealAccent,
    'indigo': Colors.indigoAccent,
    'cyan': Colors.cyanAccent,
  };

  // Normalize the input (convert to lowercase to handle case-insensitive input)
  String normalizedColorName = colorName.toLowerCase();

  // Return the accent color if it's found in the map, or a default accent color if not found
  return colorMap[normalizedColorName] ?? Colors.blueAccent; // Default to blueAccent if not found
}

Color getNodeColor(String colorName) {
  // Map of color names to their base Color equivalents
  Map<String, Color> colorMap = {
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Colors.green,
    'yellow': Colors.yellow,
    'purple': Colors.purple,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
    'cyan': Colors.cyan,
  };

  // Normalize the input (convert to lowercase to handle case-insensitive input)
  String normalizedColorName = colorName.toLowerCase();

  // Return the color if found in the map, or a default color if not found
  return colorMap[normalizedColorName] ?? Colors.blue; // Default to blue if not found
}

Widget? fabricateNode({
  String nodeName = "",
  String nodeColor = "",
  String nodeType = "",
  dynamic inPorts = null,  // Initially dynamic to accept any type
  dynamic outPorts = null, // Initially dynamic to accept any type
  bool isDummy = false,
  String svgIconString = ""
}) {
  // Ensure inPorts and outPorts are cast to List<String>?
  List<String>? inPortsCast = (inPorts as List?)?.cast<String>();
  List<String>? outPortsCast = (outPorts as List?)?.cast<String>();

  switch(nodeType) {
    case "basicNode":
      return basicNode(
        isDummy: isDummy, 
        nodeName: nodeName,  
        color: getNodeColor(nodeColor), 
        accentColor: getNodeAccentColor(nodeColor), 
        inPorts: inPortsCast,  // Cast inPorts
        outPorts: outPortsCast // Cast outPorts
      );

    case "buttonNode":
      return buttonNode(
        isDummy: isDummy, 
        nodeName: nodeName, 
        color: getNodeColor(nodeColor), 
        accentColor: getNodeAccentColor(nodeColor), 
        outPorts: outPortsCast,  // Cast outPorts
        svgIconString: svgIconString
      );
  }
  return null;  // Handle any other cases if needed
}



Widget basicNode({
  bool isDummy = false,
  Color accentColor = Colors.lightBlue,
  Color color = Colors.lightBlueAccent,
  String? nodeName, // New parameter for node text
  String? svgIconString, // SVG string for the icon
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
              border: Border.all(color: Colors.grey, width: 1), // Thin border
              borderRadius: BorderRadius.circular(_NODE_EDGE_RADIUS), // Rounded corners for both sides
            ),
            child: Row(
              children: [
                // Left side accent color section with rounded corners
                Container(
                  width: 40, // Fixed width for accent color section
                  decoration: BoxDecoration(
                    color: accentColor, // Apply the accent color to the left side
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(_NODE_EDGE_RADIUS)), // Rounded corners for the left side
                  ),
                  child: Center(
                    child: svgIconString != null
                        ? SvgPicture.string(
                            svgIconString, // Use the SVG string
                            color: Colors.white, // Adjust color if necessary
                            width: 16.0, // Adjust the size of the SVG
                            height: 16.0,
                          )
                        : const Icon(
                            Icons.warning, // Fallback icon if SVG string is null
                            color: Colors.white,
                            size: 16.0, // Adjust the icon size
                          ),
                  ),
                ),
                // Vertical divider where the blue meets the accent blue
                Container(
                  width: 0.7, // Thin width for the divider
                  color: Colors.grey, // Same color as the border
                ),
                // Right side main section for the node content
                Expanded(
                  child: Container(
                    color: Colors.transparent, // Keep transparent to let the border show
                    child: Center(
                      child: Text(
                        nodeName ?? '', // Display the node text, default to empty string if null
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'CascadiaCode'
                          ), // Customize the text style as needed
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
  String? nodeName, // Parameter for node text
  String? svgIconString, // SVG string for the icon
  List<String>? outPorts, // Nullable list for outPorts
}) {
  outPorts ??= ["outPort0"]; // Default value if not provided

  // Calculate the height based on the number of outPorts
  int numberOfPorts = outPorts.length;
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
              border: Border.all(color: Colors.grey, width: 1), // Thin border
              borderRadius: BorderRadius.circular(_NODE_EDGE_RADIUS), // Rounded corners for the node
            ),
            child: Row(
              children: [
                // Left side button with accent color and rounded square edges
                Container(
                  width: 40, // Fixed width for the button section
                  decoration: BoxDecoration(
                    color: accentColor, // Apply the accent color to the button section
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(_NODE_EDGE_RADIUS)), // Rounded corners for the left side
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24.0,
                      height: 24.0, // Make the button a square
                      child: ElevatedButton(
                        onPressed: () {
                          //nodeExecutor(nodeCommand, deviceUniqueId);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero, // Remove default padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5), // Rounded edges for the square
                          ),
                        ),
                        child: svgIconString != null
                          ? SvgPicture.string(
                              svgIconString, // Use the SVG string
                              color: color, // Adjust color if necessary
                              width: 16.0, // Adjust the size of the SVG
                              height: 16.0,
                            )
                          : Icon(
                              Icons.warning, // Fallback icon if SVG string is null
                              color: color,
                              size: 16.0, // Adjust the icon size
                            ),
                      ),
                    ),
                  ),
                ),
                // Vertical divider where the blue meets the accent blue
                Container(
                  width: 1, // Thin width for the divider
                  color: Colors.grey, // Same color as the border
                ),
                // Right side main section for the node content
                Expanded(
                  child: Container(
                    color: Colors.transparent, // Keep transparent to let the border show
                    child: Center(
                      child: Text(
                        nodeName ?? '', // Display the node text, default to empty string if null
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'CascadiaCode'
                          ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Overlay for out-ports (right side)
        Positioned(
          right: -9.5, // Stick out by 9.5px (half of port size)
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
