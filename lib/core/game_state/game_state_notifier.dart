// // lib/core/game_state/game_state_notifier.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mole_hunter/core/network/game_server.dart';
// import 'package:mole_hunter/core/network/server_manager.dart';

// enum GamePhase { lobby, roleReveal, discussion, miniGame, voting, result }

// class GameState {
//   final List<Player> players;
//   final GamePhase phase;
//   final Map<String, int> votes;

//   const GameState({
//     this.players = const [],
//     this.phase = GamePhase.lobby,
//     this.votes = const {},
//   });

//   GameState copyWith({List<Player>? players, GamePhase? phase, Map<String, int>? votes}) =>
//       GameState(
//         players: players ?? this.players,
//         phase: phase ?? this.phase,
//         votes: votes ?? this.votes,
//       );

//   Map<String, dynamic> toJson() => {
//     'players': players.map((p) => p.toJson()).toList(),
//     'phase': phase.name,
//     'votes': votes,
//   };
// }

// class GameStateNotifier extends StateNotifier<GameState> {
//   final ServerManager serverManager;

//   GameStateNotifier(this.serverManager) : super(const GameState()) {
//     serverManager.onMessage = _handleServerMessage;
//   }

//   void _handleServerMessage(ServerMessage msg) {
//     switch (msg.type) {
//       case 'player_joined':
//         final newPlayer = Player(id: msg.data['id'], name: msg.data['name'] ?? 'Unknown');
//         state = state.copyWith(players: [...state.players, newPlayer]);
//         _broadcast(); // push updated state to all clients
//         break;
//       case 'player_left':
//         state = state.copyWith(
//           players: state.players.where((p) => p.id != msg.data['id']).toList()
//         );
//         _broadcast();
//         break;
//       case 'vote_cast':
//         final newVotes = Map<String, int>.from(state.votes);
//         newVotes[msg.data['targetId']] = (newVotes[msg.data['targetId']] ?? 0) + 1;
//         state = state.copyWith(votes: newVotes);
//         _broadcast();
//         break;
//     }
//   }

//   void advancePhase() {
//     final next = GamePhase.values[state.phase.index + 1];
//     state = state.copyWith(phase: next);

//     if (next == GamePhase.roleReveal) _assignRoles();
//     _broadcast();
//   }

//   void _assignRoles() {
//     final players = List<Player>.from(state.players)..shuffle();
//     players[0] = players[0].copyWith(role: Role.spy);
//     for (int i = 1; i < players.length; i++) {
//       players[i] = players[i].copyWith(role: Role.security);
//     }
//     state = state.copyWith(players: players);

//     // Send each player their role as a PRIVATE targeted message
//     for (final p in players) {
//       serverManager.sendTo(p.id, {
//         'type': 'role_assigned',
//         'role': p.role!.name,
//         'task': _generateTask(p.role!),
//       });
//     }
//   }

//   void _broadcast() {
//     serverManager.broadcast({'type': 'state_update', ...state.toJson()});
//   }
// }

// final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
//   final serverManager = ref.watch(serverManagerProvider);
//   return GameStateNotifier(serverManager);
// });