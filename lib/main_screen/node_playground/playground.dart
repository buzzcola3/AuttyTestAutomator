import 'dart:convert';
import 'package:Autty/global_datatypes/device_info.dart';
import 'package:Autty/global_datatypes/json.dart';
import 'package:Autty/main_screen/node_playground/playground_file_interface.dart';
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
    required NodeDNA nodeDNA,
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
  final Map<String, NodeDNA> nodesDNA;
  final NodeEditorWidgetController customController;
  final PlaygroundFileInterface playgroundFileInterface;

  const NodeEditorWidget({
    super.key,
    required this.controller,
    required this.nodesDNA,
    required this.customController,
    required this.playgroundFileInterface
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
      required NodeDNA nodeDNA,
      required dynamic nodeWidget
    }) {

    NodeDNA nodeDNACopy = NodeDNA.fromJson(nodeDNA.toJson());
    

    
    if (nodeDNACopy.nodeUuid == "") {
      // ignore: prefer_const_constructors
      Uuid uuid = Uuid(); //Can not be CONST!!!
      nodeDNACopy.nodeUuid = uuid.v1();
    }

    widget.nodesDNA[nodeDNACopy.nodeUuid] = nodeDNACopy;

    _controller.addNode(
      generateNode(
        nodeType: nodeWidget,
        nodeUuid: nodeDNACopy.nodeUuid,
        onPanStart: (details) {
          _currentDraggedNodeId = nodeDNACopy.nodeUuid;
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
            if (_selectedNodeName == nodeDNACopy.nodeUuid) {
              _selectedNodeName = null;
            } else {
              _selectedNodeName = nodeDNACopy.nodeUuid;
            }
          });
          widget.controller.selectNodeAction(nodeDNACopy.nodeUuid);
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

  List<Json> getNodeParameters(String encodedNodeFunction) {
    Json decodedFunction = jsonDecode(encodedNodeFunction);
    return List<Json>.from(decodedFunction['nodeParameters'] ?? []);
  }

  void _updateSettings(String targetNode, String parameterName, String newParameterValue) {
      if (widget.nodesDNA[targetNode] != null) {
        for (var setting in widget.nodesDNA[targetNode]?.nodeFunction.settings ?? []) {
          if (setting.name == parameterName) {
            setting.value = newParameterValue;
            return;
          }
        }
      }
    
  }

  List getNodeSettingList(String targetNode) {

    if (widget.nodesDNA[targetNode] != null) {
      if (widget.nodesDNA[targetNode]!.nodeFunction.settings != []){
        return widget.nodesDNA[targetNode]!.nodeFunction.settings ?? [];
      }
    }
    
    return [];
  }

Widget getParameterWidget(NodeSetting parameter) { //TODO move out of playgroumd file
  NodeSettingType parameterType = parameter.type;
  String parameterName = parameter.name;
  String initialValue = parameter.value;

  if (parameterType == NodeSettingType.list) {
    final List<String> availableValues = List<String>.from(parameter.options!)
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
                _updateSettings(_selectedNodeName!, parameterName, newValue!);
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
  } else if (parameterType == NodeSettingType.number) {
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
              keyboardType: TextInputType.number,
              onSubmitted: (value) {
                _updateSettings(_selectedNodeName!, parameterName, value);
              },
            ),
          ),
        ],
      ),
    );
  } else if (parameterType == NodeSettingType.string) {
    // Handling for String parameter type
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
                _updateSettings(_selectedNodeName!, parameterName, value);
              },
            ),
          ),
        ],
      ),
    );
  } else {
    return const SizedBox.shrink();
  }
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
            child: DragTarget<Json>(
              onAcceptWithDetails: (details) => addNodeAtPosition(
                nodePosition: _calculateDropPosition(details),
                nodeDNA: details.data["nodeDNA"],
                nodeWidget: details.data["nodeWidget"],
              ),
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
                    ...getNodeSettingList(_selectedNodeName!).map((parameter) {
                      return getParameterWidget(parameter);
                    }),
                  ],
                ),
              ),
            ),
          // Icon buttons at the bottom right
Positioned(
  bottom: 3, // Extends the rectangle slightly below the visible screen
  right: 3, // Extends the rectangle slightly to the right
  child: ClipRRect(
    borderRadius: const BorderRadius.all(Radius.circular(10)),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => widget.playgroundFileInterface.saveFile(),
            icon: const Icon(Icons.save, color: Color.fromARGB(255, 40, 40, 40),),
            tooltip: 'Save',
          ),
          const SizedBox(width: 15),
          IconButton(
            onPressed: () => widget.playgroundFileInterface.executeFile(), // _runPlayground(),
            icon: const Icon(Icons.play_arrow, color: Color.fromARGB(255, 40, 40, 40),),
            tooltip: 'Run',
          ),
        ],
      ),
    ),
  ),
),

        ],
      ),
    ),
  );
}


}


