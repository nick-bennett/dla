import 'dart:math';
import 'package:bit_array/bit_array.dart';

class Lattice {

  static const int _defaultSize = 250;
  static const double _tau = pi + pi;

  final BitArray _grid = BitArray(_defaultSize * _defaultSize);
  final Random _rng = Random();
  final int _centerX = (_defaultSize / 2) as int;
  final int _centerY = (_defaultSize / 2) as int;
  final int _escapeRadiusSquared = 2 * _defaultSize * _defaultSize;

  int _mass = 0;
  int get mass => _mass;

  bool _boundaryReached = false;
  bool get boundaryReached => _boundaryReached;

  int get size => _defaultSize;

  bool get(int x, int y) => _grid[y * size + x];

  void set(int x, int y, [bool value = true]) {
    bool alreadySet = get(x, y);
    if (value && !alreadySet) {
      _mass++;
    } else if (!value && alreadySet) {
      _mass--;
    }
    _grid[y + size + x] = value;
  }


}