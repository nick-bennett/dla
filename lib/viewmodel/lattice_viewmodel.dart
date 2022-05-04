import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import '../service/lattice_repository.dart';

class LatticeViewModel {
  LatticeViewModel()
      : _pointStreamController = StreamController<Point<int>>(),
        _sizeStreamController = StreamController<int>(),
        _runningStreamController = StreamController<bool>(),
        _massStreamController = StreamController<int>(),
        _exceptionStreamController = StreamController<Exception>(),
        _receivePort = ReceivePort() {
    _running = false;
    _receivePort.listen(_listen);
    Isolate.spawn(LatticeRepository.start, _receivePort.sendPort);
  }

  final StreamController<Point<int>> _pointStreamController;
  final StreamController<int> _sizeStreamController;
  final StreamController<bool> _runningStreamController;
  final StreamController<int> _massStreamController;
  final StreamController<Exception> _exceptionStreamController;
  final ReceivePort _receivePort;
  late final SendPort _sendPort;

  late bool _running;

  Stream<Point<int>> get pointStream => _pointStreamController.stream;

  Stream<int> get sizeStream => _sizeStreamController.stream;

  Stream<bool> get runningStream => _runningStreamController.stream;

  Stream<int> get massStream => _massStreamController.stream;

  Stream<Exception> get exceptionStream => _exceptionStreamController.stream;

  void reset() => _sendPort.send({ControlMessageKey.reset: null});

  void seed(Point point) => _sendPort.send({ControlMessageKey.seed: point});

  void pause() => _runningStreamController.add(_running = false);

  void resume() {
    _runningStreamController.add(_running = true);
    accumulate();
  }

  void accumulate() => _sendPort.send({ControlMessageKey.accumulate: null});

  void _listen(dynamic message) {
    (message as Map<StateMessageKey, Object?>).entries.forEach((entry) {
      switch (entry.key) {
        case StateMessageKey.sendPort:
          _sendPort = entry.value as SendPort;
          break;
        case StateMessageKey.size:
          _sizeStreamController.add(entry.value as int);
          break;
        case StateMessageKey.point:
          _pointStreamController.add(entry.value as Point<int>);
          if (_running) {
            accumulate();
          }
          break;
        case StateMessageKey.mass:
          _massStreamController.add(entry.value as int);
          break;
        case StateMessageKey.error:
          _exceptionStreamController.add(entry.value as Exception);
          pause();
          break;
      }
    });
  }
}
