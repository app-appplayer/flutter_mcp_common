import 'dart:async';
import 'dart:isolate';

/// Message sent between main isolate and background isolate
class IsolateMessage {
  /// Type of message
  final String type;
  
  /// Payload of the message
  final dynamic payload;
  
  /// Create a new isolate message
  IsolateMessage(this.type, this.payload);
  
  @override
  String toString() => 'IsolateMessage($type, $payload)';
}

/// Background isolate for handling CPU-intensive tasks
class FlutterMcpBackgroundIsolate {
  /// Isolate instance
  Isolate? _isolate;
  
  /// Send port for communication with the isolate
  SendPort? _sendPort;
  
  /// Receive port for getting messages from the isolate
  ReceivePort? _receivePort;
  
  /// Stream controller for messages from the isolate
  final _messageController = StreamController<dynamic>.broadcast();
  
  /// Whether the isolate is currently running
  bool get isRunning => _isolate != null;
  
  /// Stream of messages from the isolate
  Stream<dynamic> get messages => _messageController.stream;
  
  /// Create and start a new isolate with the given entry point
  Future<void> spawn(Function entryPoint) async {
    if (_isolate != null) {
      throw StateError('Isolate is already running');
    }
    
    // Create the receive port
    _receivePort = ReceivePort();
    
    // Create the isolate
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _IsolateSetup(
        _receivePort!.sendPort,
        entryPoint,
      ),
    );
    
    // Listen for messages from the isolate
    final completer = Completer<SendPort>();
    
    final subscription = _receivePort!.listen((message) {
      if (message is SendPort) {
        // First message is the send port
        _sendPort = message;
        completer.complete(message);
      } else {
        // All other messages are forwarded to the messages stream
        _messageController.add(message);
      }
    });
    
    // Wait for the send port
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      subscription.cancel();
      await kill();
      throw TimeoutException('Timed out waiting for isolate to start');
    }
  }
  
  /// Send a message to the isolate
  void sendMessage(dynamic message) {
    if (_sendPort == null) {
      throw StateError('Isolate is not running');
    }
    
    _sendPort!.send(message);
  }
  
  /// Kill the isolate
  Future<void> kill() async {
    if (_isolate == null) {
      return;
    }
    
    _isolate!.kill(priority: Isolate.immediate);
    _isolate = null;
    
    _receivePort?.close();
    _receivePort = null;
    
    _sendPort = null;
  }
  
  /// Clean up resources
  void dispose() {
    kill();
    _messageController.close();
  }
}

/// Setup information for the isolate
class _IsolateSetup {
  /// Send port for communication back to the main isolate
  final SendPort sendPort;
  
  /// Entry point function to run in the isolate
  final Function entryPoint;
  
  /// Create isolate setup
  _IsolateSetup(this.sendPort, this.entryPoint);
}

/// Entry point for the isolate
void _isolateEntry(_IsolateSetup setup) {
  // Create a receive port for this isolate
  final receivePort = ReceivePort();
  
  // Send the send port back to the main isolate
  setup.sendPort.send(receivePort.sendPort);
  
  // Create a completer for when initialization is done
  final completer = Completer<void>();
  
  // Listen for messages
  receivePort.listen((message) {
    // Forward messages to the entry point
    if (setup.entryPoint is Function(dynamic, SendPort)) {
      (setup.entryPoint as Function(dynamic, SendPort))(message, setup.sendPort);
    } else if (setup.entryPoint is Function(dynamic)) {
      (setup.entryPoint as Function(dynamic))(message);
    } else if (!completer.isCompleted) {
      // If this is the first message and the entry point takes no arguments,
      // complete the initialization and call the entry point
      completer.complete();
      if (setup.entryPoint is Function()) {
        (setup.entryPoint as Function())();
      }
    }
  });
  
  // If the entry point takes no arguments, complete initialization immediately
  if (setup.entryPoint is Function() && !completer.isCompleted) {
    completer.complete();
    (setup.entryPoint as Function())();
  }
}
