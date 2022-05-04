import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../viewmodel/lattice_viewmodel.dart';

class DlaHomePage extends StatefulWidget {
  const DlaHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<DlaHomePage> createState() => _DlaHomePageState();
}

class _DlaHomePageState extends State<DlaHomePage> {
  _DlaHomePageState() : _viewModel = LatticeViewModel() {
    _listenToRunningStream();
    _listenToSizeStream();
    _listenToExceptionStream();
  }

  final LatticeViewModel _viewModel;
  late final Stream<bool> _runningStream;
  late final Stream<int> _sizeStream;
  late final Stream<Exception> _exceptionStream;

  bool _running = false;

  void _listenToRunningStream() {
    _runningStream = _viewModel.runningStream;
    _runningStream.listen((running) {
      if (running) {
        _resume();
      } else {
        _pause();
      }
    });
  }

  void _listenToSizeStream() {
    _sizeStream = _viewModel.sizeStream;
    _sizeStream.listen(
      (size) => _viewModel.seed(Point<int>(size >> 1, size >> 1)),
    );
  }

  void _listenToExceptionStream() {
    _exceptionStream = _viewModel.exceptionStream;
    _exceptionStream.listen(
      (exception) => Fluttertoast.showToast(
        msg: exception.toString(),
        toastLength: Toast.LENGTH_LONG,
      ),
    );
  }

  void _resume() {
    setState(() => _running = true);
  }

  void _pause() {
    setState(() => _running = false);
  }

  List<IconButton> _actions() {
    List<IconButton> icons = [];
    if (_running) {
      icons.add(IconButton(
        icon: const Icon(Icons.pause),
        onPressed: _viewModel.pause,
        tooltip: 'Pause accumulation of the aggregate',
      ));
    } else {
      icons.addAll([
        IconButton(
          icon: const Icon(Icons.restart_alt),
          onPressed: _viewModel.reset,
          tooltip: 'Clear aggregate & seed points',
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          onPressed: _viewModel.accumulate,
          tooltip: 'Add a single particle to the aggregate',
        ),
        IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: _viewModel.resume,
          tooltip: 'Begin or resume accumulation of the aggregate',
        ),
      ]);
    }
    return icons;
  }

  Widget _body() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StreamBuilder<Point<int>>(
            stream: _viewModel.pointStream,
            builder: _buildPointDisplay,
          ),
          StreamBuilder<int>(
            stream: _viewModel.massStream,
            builder: _buildMassDisplay,
          ),
        ],
      ),
    );
  }

  Widget _buildMassDisplay(context, event) {
    if (event.hasData) {
      int mass = event.data as int;
      return Text('Mass = $mass');
    } else {
      return const Text('No data');
    }
  }

  Widget _buildPointDisplay(context, event) {
    if (event.hasData) {
      Point p = event.data as Point;
      return Text('(${p.x}, ${p.y}) added to aggregate.');
    } else {
      return const Text('No data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: _actions(),
      ),
      body: _body(),
    );
  }
}
