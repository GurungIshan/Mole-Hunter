// lib/core/network/server_manager.dart
import 'dart:isolate';
// import 'dart:convert';

import 'package:mole_hunter/core/network/game_server.dart';

class ServerManager {
  Isolate? _isolate;
  SendPort? _serverSendPort;
  final _fromServer = ReceivePort();

  // Callback so GameStateNotifier can react to messages
  Function(ServerMessage)? onMessage;

  Future<void> start() async {
    _isolate = await Isolate.spawn(
      serverIsolateEntry,
      _fromServer.sendPort,
    );

    _fromServer.listen((msg) {
      if (msg is SendPort) {
        _serverSendPort = msg; // store the isolate's port
      } else if (msg is ServerMessage) {
        onMessage?.call(msg);
      }
    });
  }

  void broadcast(Map<String, dynamic> event) {
    _serverSendPort?.send(event);
  }

  void sendTo(String playerId, Map<String, dynamic> event) {
    _serverSendPort?.send({...event, 'targetId': playerId});
  }

  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _fromServer.close();
  }
}