import 'package:flutter/material.dart';
import 'package:attempt_two/main_screen/device_list/websocket_manager/headers/websocket_datatypes.dart';

class DebugConsoleController {
  final GlobalKey<_DebugConsoleState> _key = GlobalKey<_DebugConsoleState>();

  GlobalKey<_DebugConsoleState> get key => _key;

  void addMessage() {
    _key.currentState?._addMessage();
  }

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
    final nearBottom = _scrollController.offset < _scrollController.position.maxScrollExtent - 100;
    setState(() {
      _showScrollToBottomButton = nearBottom;
      _autoScrollEnabled = !nearBottom;
    });
  }

  void _addMessage() {
    setState(() => widget.wsMessageList);
    if (_autoScrollEnabled) _scrollToBottom();
    _inputController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
                          type: message.messageType,
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (_showScrollToBottomButton)
                Positioned(
                  bottom: 60,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 20),
                    onPressed: _scrollToBottom,
                    color: Colors.white,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
  final VoidCallback? onResponseReceived;

  const ExpandableMessageTile({
    Key? key,
    required this.message,
    this.response,
    required this.type,
    this.previewLength = 100,
    this.onResponseReceived,
  }) : super(key: key);

  @override
  _ExpandableMessageTileState createState() => _ExpandableMessageTileState();
}

class _ExpandableMessageTileState extends State<ExpandableMessageTile> {
  bool _isMessageExpanded = false;
  bool _isResponseExpanded = false;
  bool _isResponseReceived = false;

  @override
  void didUpdateWidget(ExpandableMessageTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if response is received (this assumes widget.response is updated when response is available)
    if (widget.response != null && !_isResponseReceived) {
      _isResponseReceived = true;
      if (widget.onResponseReceived != null) {
        widget.onResponseReceived!(); // Notify parent that response is received
      }
    }
  }

  void _toggleMessageExpanded() {
    setState(() => _isMessageExpanded = !_isMessageExpanded);
  }

  void _toggleResponseVisibility() {
    setState(() => _isResponseExpanded = !_isResponseExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final isLongMessage = widget.message.length > widget.previewLength;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: _getMessageBackgroundColor(widget.type),
        border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 1)),
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
                  _isMessageExpanded || !isLongMessage
                      ? widget.message
                      : '${widget.message.substring(0, widget.previewLength)}...',
                  style: TextStyle(color: _getMessageTextColor(widget.type), fontFamily: 'monospace'),
                ),
              ),
              // Only show the loading or checkmark for MessageType.generic
              if (widget.type == MessageType.generic) 
                Container(
                  width: 50,
                  height: 20,
                  color: Colors.transparent,
                  child: !_isResponseReceived
                      ? const Center(
                          child: SizedBox(
                            width: 16,  // Set width and height to match the circular progress indicator's default size
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Center(
                          child: ElevatedButton(
                            onPressed: _toggleResponseVisibility,  // Toggle response visibility
                            style: ElevatedButton.styleFrom(
                              shape: CircleBorder(),
                              padding: EdgeInsets.zero,  // Remove padding to make it only the icon
                              backgroundColor: Colors.transparent,  // Make button background transparent
                            ),
                            child: Icon(Icons.check, color: Colors.white), // Change to checkmark icon
                          ),
                        ),
                ),
              if (isLongMessage)
                TextButton(
                  onPressed: _toggleMessageExpanded,
                  child: Text(_isMessageExpanded ? 'Collapse' : 'Expand'),
                ),
            ],
          ),
          // Display response text only if it is visible
          if (_isResponseExpanded && widget.response != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.response!,
              style: TextStyle(color: Colors.grey[400], fontFamily: 'monospace'),
            ),
          ],
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
