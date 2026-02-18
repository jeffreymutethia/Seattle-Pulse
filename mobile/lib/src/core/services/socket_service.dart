import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:seattle_pulse_mobile/src/core/constants/api_constants.dart';

class SocketService {
  static SocketService? _instance;
  io.Socket? _socket;
  final List<Function(dynamic)> _listeners = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _baseUrl = 'http://10.0.2.2:5001'; // Same server as API

  // Private constructor
  SocketService._();

  // Singleton pattern
  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  // Initialize socket connection
  Future<void> initSocket(String userId) async {
    try {
      if (_socket != null) {
        debugPrint('Socket already connected');
        return;
      }

      // Get session cookie
      final cookie = await _storage.read(key: "session_cookie");

      // Connect to socket server
      _socket = io.io(_baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'extraHeaders': {'Cookie': cookie}
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('Socket connected successfully to $_baseUrl');

        // Tell the server we're online and listening
        _socket!.emit('user_connected', {'user_id': userId});

        // Listen for user-specific notifications
        _socket!.on('notify_$userId', (data) {
          debugPrint(
              'Socket: User-specific notification received for user $userId: $data');

          // Process notification data
          if (data is Map &&
              data['chat_id'] != null &&
              data['content'] != null) {
            // This is a direct message notification, broadcast it to listeners
            debugPrint(
                'Socket: Broadcasting direct message notification to ${_listeners.length} listeners');

            // Notify all listeners with a copy of the data to avoid modification issues
            final dataCopy = Map<String, dynamic>.from(data as Map);
            for (var listener in _listeners) {
              listener(dataCopy);
            }
          } else {
            // General notification, just pass it along
            for (var listener in _listeners) {
              listener(data);
            }
          }
        });

        // Listen for general new message events - separate from user-specific notifications
        _socket!.on('new_message', (data) {
          debugPrint('Socket: General new_message event: $data');

          if (data is Map && data['chat_id'] != null) {
            debugPrint(
                'Socket: Broadcasting general message to ${_listeners.length} listeners');

            // Add unique timestamp to differentiate from other notifications
            final dataCopy = Map<String, dynamic>.from(data as Map);
            dataCopy['_timestamp'] = DateTime.now().millisecondsSinceEpoch;

            // Notify all listeners
            for (var listener in _listeners) {
              listener(dataCopy);
            }
          }
        });
      });

      _socket!.onConnectError((error) {
        debugPrint('Socket connection error: $error');
      });

      _socket!.onDisconnect((_) {
        debugPrint('Socket disconnected');
      });

      _socket!.onError((error) {
        debugPrint('Socket error: $error');
      });
    } catch (e) {
      debugPrint('Socket initialization error: $e');
    }
  }

  // Setup socket event listeners
  void _setupEventListeners(int userId) {
    _socket?.onConnect((_) {
      debugPrint('Socket connected');
    });

    _socket?.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    _socket?.onError((error) {
      debugPrint('Socket error: $error');
    });

    // Listen for notifications for the current user
    _socket?.on('notify_$userId', (data) {
      debugPrint('Received notification: $data');
      // Notify all listeners
      for (var listener in _listeners) {
        listener(data);
      }
    });
  }

  // Add a notification listener
  void addNotificationListener(Function(dynamic) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  // Remove a notification listener
  void removeNotificationListener(Function(dynamic) listener) {
    _listeners.remove(listener);
  }

  // Remove all notification listeners
  void removeAllListeners() {
    _listeners.clear();
    debugPrint('All notification listeners removed');
  }

  // Add a listener for a specific event
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  // Remove a listener for a specific event
  void off(String event) {
    _socket?.off(event);
  }

  // Emit an event
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  // Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _listeners.clear();
    debugPrint('Socket disconnected and cleared');
  }

  // Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;
}

// Provider for SocketService
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService.instance;
});
