import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import '../device_list/node_generation/node_generator.dart';

class NodeEditorWidget extends StatefulWidget {
  final NodeEditorController controller;
  final List<Map<String, dynamic>> nodeParameterValues;
  

  const NodeEditorWidget({
    super.key,
    required this.controller,
    required this.nodeParameterValues
    });

  @override
  NodeEditorWidgetState createState() => NodeEditorWidgetState();
}

class NodeEditorWidgetState extends State<NodeEditorWidget> {
  late NodeEditorController _controller;
  late FocusNode _focusNode;
  String? _currentDraggedNodeId;
  Offset _currentDraggedPosition = const Offset(0, 0);
  String? _selectedNodeName; // Store the unique name of the clicked node
  double dragStep = 20.0;

  // Store controllers for TextFields
  List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _playgroundScrollHandle(Offset offset) {
    double horPos = _controller.horizontalScrollController.offset;
    double verPos = _controller.verticalScrollController.offset;

    horPos -= offset.dx;
    verPos -= offset.dy;

    _controller.horizontalScrollController.jumpTo(horPos);
    _controller.verticalScrollController.jumpTo(verPos);
  }

  Offset _dragGridSnap(Offset draggingPosition) {
    double dragPosX = _currentDraggedPosition.dx;
    double dragPosY = _currentDraggedPosition.dy;

    double dragDeltaX = dragPosX - draggingPosition.dx;
    double dragDeltaY = dragPosY - draggingPosition.dy;

    double snapDragDeltaX = 0;
    double snapDragDeltaY = 0;

    if (dragDeltaX >= dragStep) {
      snapDragDeltaX -= dragStep;
      dragPosX -= dragStep;
      _currentDraggedPosition = Offset(dragPosX, _currentDraggedPosition.dy);
    }

    if (dragDeltaX <= -dragStep) {
      snapDragDeltaX += dragStep;
      dragPosX += dragStep;
      _currentDraggedPosition = Offset(dragPosX, _currentDraggedPosition.dy);
    }

    if (dragDeltaY >= dragStep) {
      snapDragDeltaY -= dragStep;
      dragPosY -= dragStep;
      _currentDraggedPosition = Offset(_currentDraggedPosition.dx, dragPosY);
    }

    if (dragDeltaY <= -dragStep) {
      snapDragDeltaY += dragStep;
      dragPosY += dragStep;
      _currentDraggedPosition = Offset(_currentDraggedPosition.dx, dragPosY);
    }

    return Offset(snapDragDeltaX, snapDragDeltaY);
  }

  int _nodeUniqueIndex = 0;

  void _addNodeAtPosition(Offset position, Map<String, dynamic> nodeData) {
    nodeData["encodedFunction"]["unique_index"] = _nodeUniqueIndex;
    _nodeUniqueIndex++;
    String uniqueNodeName = jsonEncode(nodeData["encodedFunction"]);

    widget.nodeParameterValues.add({uniqueNodeName: nodeData["encodedFunction"]['nodeParameters']});

    _controller.addNode(
      generateNode(
        nodeType: nodeData["node"],
        nodeEncodedFunction: uniqueNodeName,
        onPanStart: (details) {
          _currentDraggedNodeId = uniqueNodeName;
          _currentDraggedPosition = details.globalPosition;
          print('Pan started at: ${details.globalPosition}');
        },
        onPanUpdate: (details) {
          if (_currentDraggedNodeId != null) {
            Offset cursorDelta = _dragGridSnap(details.globalPosition);
            _controller.moveNodePosition(_currentDraggedNodeId!, cursorDelta);
            print('Cursor Position during drag: $cursorDelta');
          }
        },
        onPanEnd: (details) {
          _currentDraggedNodeId = null;
          print('Pan ended');
        },
        onTap: () {
          setState(() {
            _selectedNodeName = uniqueNodeName; // Show overlay with the node's unique name
          });
        }
      ),
      NodePosition.custom(position),
    );
  }

  Offset _calculateDropPosition(DragTargetDetails details) {
    Offset playgroundAbsPos = details.offset - (_controller.stackPos ?? Offset.zero);
    Offset playgroundRelPos = Offset(
      playgroundAbsPos.dx + _controller.horizontalScrollController.offset,
      playgroundAbsPos.dy + _controller.verticalScrollController.offset,
    );

    Offset snappedPos = Offset(
      _snapToGrid(playgroundRelPos.dx),
      _snapToGrid(playgroundRelPos.dy),
    );

    return Offset(
      snappedPos.dx < 0 ? 0 : snappedPos.dx,
      snappedPos.dy < 0 ? 0 : snappedPos.dy,
    );
  }

  double _snapToGrid(double value) {
    return (value / 20).round() * 20;
  }

  List<Map<String, dynamic>> getNodeParameters(String encodedNodeFunction) {
    Map<String, dynamic> decodedFunction = jsonDecode(encodedNodeFunction);
    return List<Map<String, dynamic>>.from(decodedFunction['nodeParameters'] ?? []); // Return an empty list if "Parameters" is not found
  }


  void _updateParameters(String encodedNodeFunction, String parameterName) {

    for (var nodeParameters in widget.nodeParameterValues) {
      if(nodeParameters[encodedNodeFunction] != null){
        for (var parameter in nodeParameters[encodedNodeFunction]) {
          if(parameter["Name"] == parameterName){
            parameter["Value"] = _controllers[0].text; 
          } 
        }
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.green,
        ),
        child: Stack(
          children: [
            GestureDetector(
              onPanUpdate: (details) {
                _playgroundScrollHandle(details.delta);
              },
              child: DragTarget<Map<String, dynamic>>(
                onAcceptWithDetails: (details) {
                  Offset finalPos = _calculateDropPosition(details);
                  _addNodeAtPosition(finalPos, details.data);
                },
                builder: (context, candidateData, rejectedData) {
                  return MouseRegion(
                    child: NodeEditor(
                      focusNode: _focusNode,
                      controller: _controller,
                      background: const GridBackground(),
                      infiniteCanvasSize: 5000,
                    ),
                  );
                },
              ),
            ),
            if (_selectedNodeName != null)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10), // Rounded edges
                  ),
                  width: 200,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedNodeName = null; // Close the overlay
                              _controllers.clear(); // Clear controllers on close
                            });
                          },
                          child: const Text(
                            "Close",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Build a list of parameters from getNodeParameters
                      ...getNodeParameters(_selectedNodeName!).asMap().entries.map((entry) {
                        int index = entry.key;
                        var parameter = entry.value;
                        String parameterName = parameter["Name"] ?? '';
                        String initialValue = parameter["Value"] ?? '';

                        // Initialize a controller for each parameter
                        if (_controllers.length <= index) {
                          _controllers.add(TextEditingController(text: initialValue));
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(parameterName),
                              ),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: initialValue,
                                  ),
                                  controller: _controllers[index],
                                  onSubmitted: (value) {
                                    // Update the parameter value here and call update function
                                    parameter["Value"] = value;
                                    _updateParameters(_selectedNodeName!, parameterName); // Call update function on submit
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
