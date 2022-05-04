import 'dart:isolate';
import 'dart:math';

import '../model/lattice.dart';

class LatticeRepository {
  LatticeRepository(this._sendPort)
      : _receivePort = ReceivePort(),
        _lattice = Lattice() {
    _receivePort.listen(_listen);
    _sendPort.send({
      StateMessageKey.sendPort: _receivePort.sendPort,
      StateMessageKey.size: _lattice.size,
    });
  }

  final SendPort _sendPort;
  final ReceivePort _receivePort;
  final Lattice _lattice;

  static void start(dynamic message) {
    LatticeRepository(message as SendPort);
  }

  void _listen(dynamic message) {
    (message as Map<ControlMessageKey, Object?>).entries.forEach((entry) {
      switch (entry.key) {
        case ControlMessageKey.seed:
          _seed(entry.value as Point<int>);
          break;
        case ControlMessageKey.accumulate:
          _accumulate();
          break;
        case ControlMessageKey.reset:
          _clear();
          break;
      }
    });
  }

  void _seed(Point<int> point) {
    _lattice.set(point);
    _sendPort.send({
      StateMessageKey.point: point,
      StateMessageKey.mass: _lattice.mass,
    });
  }

  void _accumulate() {
    try {
      _sendPort.send({
        StateMessageKey.point: _lattice.accumulate(),
        StateMessageKey.mass: _lattice.mass,
      });
    } on Exception catch (e) {
      _sendPort.send({StateMessageKey.error: e});
    }
  }

  void _clear() {
    _lattice.clear();
    _sendPort.send({
      StateMessageKey.mass: 0,
      StateMessageKey.size: _lattice.size,
    });
  }
}

enum ControlMessageKey { seed, accumulate, reset }

enum StateMessageKey { sendPort, size, point, mass, error }
