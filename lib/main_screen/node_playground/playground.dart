import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:node_editor/node_editor.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../device_list/node_generation/node_generator.dart';
import 'package:uuid/uuid.dart';


class NodeEditorWidgetController {
  NodeEditorWidgetState? _nodeEditorWidgetState;

  void bind(NodeEditorWidgetState state) {
    _nodeEditorWidgetState = state;
  }

  void unbind() {
    _nodeEditorWidgetState = null;
  }

  void addNodeAtPosition({
    required Offset nodePosition,
    required Map<String, dynamic> nodeDNA,
    required dynamic nodeWidget,
  }) {
    _nodeEditorWidgetState?.addNodeAtPosition(
      nodePosition: nodePosition,
      nodeDNA: nodeDNA,
      nodeWidget: nodeWidget,
    );
  }

  void refreshUI(){
    _nodeEditorWidgetState?.refreshUI();
  }
}


class NodeEditorWidget extends StatefulWidget {
  final NodeEditorController controller;
  final Map<String, dynamic> nodesDNA;
  final NodeEditorWidgetController customController;

  const NodeEditorWidget({
    super.key,
    required this.controller,
    required this.nodesDNA,
    required this.customController,
  });

  @override
  NodeEditorWidgetState createState() => NodeEditorWidgetState();
}

class NodeEditorWidgetState extends State<NodeEditorWidget> {
  late NodeEditorController _controller;
  late FocusNode _focusNode;
  String? _currentDraggedNodeId;
  Offset _currentDraggedPosition = const Offset(0, 0);
  String? _selectedNodeName;
  double dragStep = 20.0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    widget.customController.bind(this); // Bind the controller
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    widget.customController.unbind(); // Unbind the controller
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

  void refreshUI() {
    setState(() {}); // Calls setState from within the State class
  }

  void addNodeAtPosition({
      required Offset nodePosition,
      required Map<String, dynamic> nodeDNA,
      required dynamic nodeWidget
    }) {

    Map<String, dynamic> nodeDNACopy = jsonDecode(jsonEncode(nodeDNA));

    if(widget.controller.nodes.keys.firstOrNull != null){
      widget.controller.selectNodeAction(widget.controller.nodes.keys.first);
    }
    

    var uuid = const Uuid();
    nodeDNACopy["nodeUuid"] ??= uuid.v1();

    widget.nodesDNA[nodeDNACopy["nodeUuid"]] = nodeDNACopy;

    _controller.addNode(
      generateNode(
        nodeType: nodeWidget,
        nodeUuid: nodeDNACopy["nodeUuid"],
        onPanStart: (details) {
          _currentDraggedNodeId = nodeDNACopy["nodeUuid"];
          _currentDraggedPosition = details.globalPosition;
        },
        onPanUpdate: (details) {
          if (_currentDraggedNodeId != null) {
            Offset cursorDelta = _dragGridSnap(details.globalPosition);
            _controller.moveNodePosition(_currentDraggedNodeId!, cursorDelta);
          }
        },
        onPanEnd: (details) {
          _currentDraggedNodeId = null;
        },
        onTap: () {
          setState(() {
            if (_selectedNodeName == nodeDNACopy["nodeUuid"]) {
              _selectedNodeName = null;
            } else {
              _selectedNodeName = nodeDNACopy["nodeUuid"];
            }
          });
          widget.controller.selectNodeAction(nodeDNACopy["nodeUuid"]);
        },
      ),
      NodePosition.custom(nodePosition),
    );

    setState(() {}); // Ensure the widget updates immediately
  }


  Offset _calculateDropPosition(DragTargetDetails details) {
    Offset playgroundAbsPos = details.offset - (_controller.stackPos ?? Offset.zero);
    Offset playgroundRelPos = Offset(
      playgroundAbsPos.dx + _controller.horizontalScrollController.offset,
      playgroundAbsPos.dy + _controller.verticalScrollController.offset,
    );
    return Offset(
      _snapToGrid(playgroundRelPos.dx),
      _snapToGrid(playgroundRelPos.dy),
    );
  }

  double _snapToGrid(double value) => (value / 20).round() * 20;

  List<Map<String, dynamic>> getNodeParameters(String encodedNodeFunction) {
    Map<String, dynamic> decodedFunction = jsonDecode(encodedNodeFunction);
    return List<Map<String, dynamic>>.from(decodedFunction['nodeParameters'] ?? []);
  }

  void _updateParameter(String targetNode, String parameterName, String newParameterValue) {
      if (widget.nodesDNA[targetNode] != null) {
        for (var parameter in widget.nodesDNA[targetNode]["nodeParameters"]) {
          if (parameter["Name"] == parameterName) {
            parameter["Value"] = newParameterValue;
            return;
          }
        }
      }
    
  }

  List getNodeParameterList(String targetNode) {

    if (widget.nodesDNA[targetNode] != null) {
      if (widget.nodesDNA[targetNode]["nodeParameters"]!= null){
        return widget.nodesDNA[targetNode]["nodeParameters"];
      }
    }
    
    return [];
  }

  Widget getParameterWidget(dynamic parameter){
    String parameterType = parameter["Type"]?.toString() ?? '';
    String parameterName = parameter["Name"]?.toString() ?? '';
    String initialValue = parameter["Value"]?.toString() ?? '';


  if (parameterType == 'List') {
    final List<String> availableValues = List<String>.from(parameter["AvailableValues"])
      ..sort((a, b) => a.compareTo(b)); // Sort alphabetically

    String? selectedValue = initialValue;
    final GlobalKey<DropdownSearchState<String>> dropDownKey = GlobalKey();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(parameterName)),
          // Using SizedBox to control the dropdown width
          SizedBox(
            width: 130, // Adjust this value to make the selection area wider
            child: DropdownSearch<String>(
              key: dropDownKey,
              selectedItem: selectedValue,
              items: (String? filter, _) => availableValues,
              onChanged: (newValue) {
                selectedValue = newValue;
                _updateParameter(_selectedNodeName!, parameterName, newValue!);
              },
              popupProps: PopupProps.menu(
                fit: FlexFit.loose,
                constraints: BoxConstraints(),
                showSearchBox: true, // Enables search box within the dropdown
              ),
            ),
          ),
        ],
      ),
    );
  }

    else if(parameterType == 'Int'){
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(parameterName)),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: initialValue,
                ),
                onSubmitted: (value) {
                  _updateParameter(_selectedNodeName!, parameterName, value);
                },
              ),
            ),
          ],
        ),
      );
    }

    else return const SizedBox.shrink();


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(255, 58, 58, 58),
        ),
        child: Stack(
          children: [
            GestureDetector(
              onPanUpdate: (details) => _playgroundScrollHandle(details.delta),
              child: DragTarget<Map<String, dynamic>>(
                //onAcceptWithDetails: (details) => addNodeAtPosition(_calculateDropPosition(details), details.data),
                onAcceptWithDetails: (details) => addNodeAtPosition(nodePosition: _calculateDropPosition(details), nodeDNA: details.data["nodeDNA"], nodeWidget: details.data["nodeWidget"]),
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
                    borderRadius: BorderRadius.circular(10),
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
                              _selectedNodeName = null;
                            });
                          },
                          child: const Text("Close", style: TextStyle(fontSize: 12, color: Colors.black54)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...getNodeParameterList(_selectedNodeName!).map((parameter) {
                        return getParameterWidget(parameter);
                      }),
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


