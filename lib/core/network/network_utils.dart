// lib/core/network/network_utils.dart
import 'package:network_info_plus/network_info_plus.dart';

Future<String?> getLocalIpAddress() async {
  final info = NetworkInfo();
  return await info.getWifiIP(); // e.g. "192.168.1.5"

}
// In your lobby screen widget:
final ip = await getLocalIpAddress();
final wsUrl = 'ws://$ip:8080/ws';
// Pass wsUrl to QrImageView(data: wsUrl)