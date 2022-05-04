import 'dart:math';

import 'package:bit_array/bit_array.dart';

class Lattice {
  Lattice([int size = 255])
      : _rng = Random() {
    int _halfSize = size >> 1; // Shift right for truncating division by 2.
    _size = size | 1; // Make sure that _size is odd, by adding 1 if necessary.
    _center = Point<int>(_halfSize, _halfSize);
    _bounds = MutableRectangle<int>(0, 0, size - 1, size - 1);
    _extent = MutableRectangle<int>(-1, -1, 0, 0);
    _grid = BitArray(size * size);
    _escapeDistanceSquared = 2 * size * size;
  }

  final Random _rng;
  late final int _size;
  late final Point<int> _center;
  late final MutableRectangle<int> _bounds;
  late final MutableRectangle<int> _extent;
  late final BitArray _grid;
  late final int _escapeDistanceSquared;

  static const double _tau = pi + pi;
  static const int _startBuffer = 10;

  int get mass => _mass;
  int _mass = 0;

  bool get boundaryReached => _boundaryReached;
  bool _boundaryReached = false;

  int get size => _size;

  double _extentMagnitude = 0;

  bool get(Point<int> point) => _grid[point.y * _size + point.x];

  void set(Point<int> point, [bool value = true]) {
    bool alreadySet = get(point);
    if (value && !alreadySet) {
      if (_mass++ == 0) {
        _extent.left = point.x - 1;
        _extent.top = point.y - 1;
        _extent.width = 2;
        _extent.height = 2;
      } else {
        _extent.extend(point);
      }
      _extentMagnitude = max(_extentMagnitude, point.distanceTo(_center));
    } else if (!value && alreadySet) {
      _mass--;
    }
    _grid[point.y * _size + point.x] = value;
  }

  Point<int> accumulate() {
    if (_mass == 0) {
      throw NoSeedException();
    }
    if (_boundaryReached) {
      throw BoundaryReachedException();
    }
    Point<int>? point;
    bool accumulated = false;
    do {
      double theta = _rng.nextDouble() * _tau;
      Point<int> p = Point<int>(
          (_center.x + (_extentMagnitude + _startBuffer) * cos(theta)).round(),
          (_center.y - (_extentMagnitude + _startBuffer) * sin(theta)).round());
      while (!_isEscaped(p)) {
        if (_extent.containsPoint(p) && _isAdjacentToAggregate(p)) {
          accumulated = true;
          set(p);
          _boundaryReached = _isOnBoundary(p);
          point = p;
          break;
        }
        p += _DirectionExtension.random(_rng).offset;
      }
    } while (!accumulated);
    return point as Point<int>;
  }

  void clear() {
    _grid.clearAll();
    _mass = 0;
    _boundaryReached = false;
  }

  bool _isEscaped(Point<int> point) =>
      point.squaredDistanceTo(_center) > _escapeDistanceSquared;

  bool _isOnLattice(Point<int> point) => _bounds.containsPoint(point);

  bool _isOnBoundary(Point<int> point) =>
      point.x == 0 ||
      point.x == _size - 1 ||
      point.y == 0 ||
      point.y == _size - 1;

  bool _isAdjacentToAggregate(Point<int> point) {
    bool adjacent = false;
    for (Direction dir in Direction.values) {
      Point<int> neighbor = point + dir.offset;
      if (_isOnLattice(neighbor) && _grid[neighbor.y * _size + neighbor.x]) {
        adjacent = true;
        break;
      }
    }
    return adjacent;
  }
}

enum Direction { north, east, south, west }

class NoSeedException implements Exception {
  NoSeedException([this._message = _defaultMessage]);

  final String _message;

  static const String _defaultMessage =
      'Lattice contains no seed points; no accumulation possible.';

  String get message => _message;

  @override
  String toString() => _message;
}

class BoundaryReachedException implements Exception {
  BoundaryReachedException([this._message = _defaultMessage]);

  final String _message;

  static const String _defaultMessage =
      'Aggregate has reached the lattice boundary; no further accumulation possible.';

  String get message => _message;

  @override
  String toString() => _message;
}

extension _DirectionExtension on Direction {
  int get offsetX {
    int offset;
    switch (this) {
      case Direction.east:
        offset = 1;
        break;
      case Direction.west:
        offset = -1;
        break;
      default:
        offset = 0;
        break;
    }
    return offset;
  }

  int get offsetY {
    int offset;
    switch (this) {
      case Direction.south:
        offset = 1;
        break;
      case Direction.north:
        offset = -1;
        break;
      default:
        offset = 0;
        break;
    }
    return offset;
  }

  Point<int> get offset => Point(offsetX, offsetY);

  static Direction random(Random rng) =>
      Direction.values[rng.nextInt(Direction.values.length)];
}

extension _RectangleExtension on MutableRectangle {
  void extend<T extends num>(Point<T> point) {
    if (point.x <= left) {
      left = point.x - 1;
    } else if (point.x >= right) {
      width = point.x - left + 1;
    }
    if (point.y <= top) {
      top = point.y - 1;
    } else if (point.y >= bottom) {
      height = point.y - top + 1;
    }
  }
}
