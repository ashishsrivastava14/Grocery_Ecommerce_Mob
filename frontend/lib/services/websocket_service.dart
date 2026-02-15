import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/constants.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  Timer? _reconnectTimer;
  String? _currentUrl;

  Stream<Map<String, dynamic>> get stream =>
      _controller?.stream ?? const Stream.empty();

  void connectToOrder(String orderId) {
    _connect('${AppConstants.wsUrl}/ws/orders/$orderId');
  }

  void connectToVendor(String vendorId) {
    _connect('${AppConstants.wsUrl}/ws/vendor/$vendorId');
  }

  void _connect(String url) {
    disconnect();
    _currentUrl = url;
    _controller = StreamController<Map<String, dynamic>>.broadcast();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);
            _controller?.add(decoded as Map<String, dynamic>);
          } catch (_) {}
        },
        onDone: () => _scheduleReconnect(),
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void sendLocationUpdate(double latitude, double longitude) {
    _channel?.sink.add(jsonEncode({
      'type': 'location_update',
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_currentUrl != null) _connect(_currentUrl!);
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller?.close();
    _channel = null;
    _controller = null;
    _currentUrl = null;
  }
}
