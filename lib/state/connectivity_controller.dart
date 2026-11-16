import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Real-time network status. Note: this reports whether a network interface
/// is up, not whether the internet is reachable, so online features still
/// handle request errors themselves.
class ConnectivityController extends ChangeNotifier {
  ConnectivityController._();

  bool _online = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOnline => _online;

  static bool _isOnline(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);

  static Future<ConnectivityController> load() async {
    final c = ConnectivityController._();
    final connectivity = Connectivity();
    c._online = _isOnline(await connectivity.checkConnectivity());
    c._sub = connectivity.onConnectivityChanged.listen((r) {
      final online = _isOnline(r);
      if (online != c._online) {
        c._online = online;
        c.notifyListeners();
      }
    });
    return c;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
