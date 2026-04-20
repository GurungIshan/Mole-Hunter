// lib/core/network/game_server.dart
import 'dart:convert';
import 'dart:isolate';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ServerMessage {
  final String type; // 'player_joined', 'game_event', etc.
  final Map<String, dynamic> data;
  const ServerMessage(this.type, this.data);
}

// Entry point for the isolate — must be a top-level function
Future<void> serverIsolateEntry(SendPort mainSendPort) async {
  final fromMain = ReceivePort();
  mainSendPort.send(fromMain.sendPort); // hand back our port

  // Map of playerId → socket
  final Map<String, WebSocketChannel> clients = {};

  final wsHandler = webSocketHandler((WebSocketChannel socket, String? protocol) {
    String? playerId;

    socket.stream.listen(
      (message) {
        final decoded = jsonDecode(message as String) as Map<String, dynamic>;
        
        if (decoded['type'] == 'join') {
          playerId = decoded['playerId'] as String;
          clients[playerId!] = socket;
          // tell the main isolate a player joined
          mainSendPort.send(ServerMessage('player_joined', {'id': playerId}));
        } else {
          // forward all other events to main isolate
          mainSendPort.send(ServerMessage(decoded['type'] as String, decoded));
        }
      },
      onDone: () {
        if (playerId != null) {
          clients.remove(playerId);
          mainSendPort.send(ServerMessage('player_left', {'id': playerId}));
        }
      },
    );
  });

  final handler = const Pipeline().addHandler(wsHandler);
  await shelf_io.serve(handler, '0.0.0.0', 8080);

  // Listen for broadcast commands from main isolate
  await for (final msg in fromMain) {
    if (msg is Map<String, dynamic>) {
      final json = jsonEncode(msg);
      if (msg['targetId'] != null) {
        // targeted send (e.g. secret role reveal)
        clients[msg['targetId']]?.sink.add(json);
      } else {
        // broadcast to everyone
        for (final c in clients.values) {
          c.sink.add(json);
        }
      }
    }
  }
}