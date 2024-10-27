import 'package:flutter/material.dart';
import 'package:attempt_two/main_screen/device_list/websocket_manager/headers/websocket_datatypes.dart';

class DebugConsoleController {
  final GlobalKey<_DebugConsoleState> _key = GlobalKey<_DebugConsoleState>();

  // Expose the GlobalKey
  GlobalKey<_DebugConsoleState> get key => _key;

  // External method to add messages
  void addMessage() { //TODO rename
    _key.currentState?._addMessage();
  }

  // External method to scroll to bottom
  void scrollToBottom() {
    _key.currentState?._scrollToBottom();
  }
}

class DebugConsole extends StatefulWidget {
  final WsMessageList wsMessageList;

  const DebugConsole({Key? key, required this.wsMessageList}) : super(key: key);

  @override
  _DebugConsoleState createState() => _DebugConsoleState();
}

enum MessageType { generic, response, warning, error }

class ConsoleMessage {
  final String content;
  final MessageType type;

  ConsoleMessage(this.content, this.type);
}

class _DebugConsoleState extends State<DebugConsole> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _autoScrollEnabled = true;
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset < _scrollController.position.maxScrollExtent - 100) {
      setState(() {
        _showScrollToBottomButton = true;
        _autoScrollEnabled = false;
      });
    } else {
      setState(() {
        _showScrollToBottomButton = false;
        _autoScrollEnabled = true;
      });
    }
  }

  void _addMessage() {
    setState(() {
      widget.wsMessageList;
    });
    if (_autoScrollEnabled) {
      _scrollToBottom();
    }
    _inputController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToBottomButtonPressed() {
    _scrollToBottom();
    setState(() {
      _showScrollToBottomButton = false;
      _autoScrollEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.wsMessageList.messages.length,
                      itemBuilder: (context, index) {
                        final message = widget.wsMessageList.messages[index];
                        return ExpandableMessageTile(
                          message: message.message,
                          response: message.rawResponse,
                          type: MessageType.generic,
                        );
                      },
                    ),
                  ),
                  Divider(color: Colors.grey[700], height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter command',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              filled: true,
                              fillColor: Colors.black54,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_showScrollToBottomButton)
                Positioned(
                  bottom: 60,
                  right: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_downward, size: 20),
                    onPressed: _scrollToBottomButtonPressed,
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }
}

class ExpandableMessageTile extends StatefulWidget {
  final String message;
  final String? response;
  final MessageType type;
  final int previewLength;

  const ExpandableMessageTile({
    Key? key,
    required this.message,
    this.response,
    required this.type,
    this.previewLength = 100,
  }) : super(key: key);

  @override
  _ExpandableMessageTileState createState() => _ExpandableMessageTileState();
}

class _ExpandableMessageTileState extends State<ExpandableMessageTile> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLongMessage = widget.message.length > widget.previewLength;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _getMessageBackgroundColor(widget.type),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 0.9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.type == MessageType.response ? Icons.arrow_right : Icons.arrow_left,
                color: Colors.grey[500],
                size: 16.0,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _isExpanded || !isLongMessage
                      ? widget.message
                      : '${widget.message.substring(0, widget.previewLength)}...',
                  style: TextStyle(
                    color: _getMessageTextColor(widget.type),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (widget.response == null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
            ],
          ),
          if (isLongMessage)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _toggleExpanded,
                child: Text(_isExpanded ? 'Collapse' : 'Expand'),
              ),
            ),
          if (widget.response != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                widget.response!,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getMessageTextColor(MessageType type) {
    switch (type) {
      case MessageType.warning:
        return Colors.yellowAccent;
      case MessageType.error:
        return Colors.redAccent;
      case MessageType.response:
        return Colors.grey[400]!;
      default:
        return Colors.white;
    }
  }

  Color _getMessageBackgroundColor(MessageType type) {
    switch (type) {
      case MessageType.warning:
        return Colors.yellow.withOpacity(0.2);
      case MessageType.error:
        return Colors.red.withOpacity(0.2);
      case MessageType.response:
        return Colors.black45;
      default:
        return Colors.black54;
    }
  }
}
