import 'package:flutter/foundation.dart';

/// Selected bottom-navigation tab: 0 Today, 1 History, 2 Settings.
class NavController extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void go(int i) {
    if (i == _index) return;
    _index = i;
    notifyListeners();
  }
}
