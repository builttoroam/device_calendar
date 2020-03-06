import 'package:flutter/material.dart';
import 'dart:async';

import 'package:dual_screen/dual_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDualScreenDevice;
  bool _isAppSpanned;
  bool _isAppSpannedStream;

  @override
  void initState() {
    super.initState();
    DualScreen.isAppSpannedStream().listen(
      (data) => setState(() => _isAppSpannedStream = data),
    );
  }

  Future<void> _updateDualScreenInfo() async {
    bool isDualDevice = await DualScreen.isDualScreenDevice;
    bool isAppSpanned = await DualScreen.isAppSpanned;

    if (!mounted) return;

    setState(() {
      _isDualScreenDevice = isDualDevice;
      _isAppSpanned = isAppSpanned;
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text('Dual screen device example'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Dual device: ${_isDualScreenDevice ?? 'Unknown'}'),
                SizedBox(height: 8),
                Text('App spanned: ${_isAppSpanned ?? 'Unknown'}'),
                SizedBox(height: 8),
                RaisedButton(
                  child: Text('Manually determine dual device and app spanned'),
                  onPressed: () => _updateDualScreenInfo(),
                ),
                SizedBox(height: 64),
                Text('App spanned stream: ${_isAppSpannedStream ?? 'Unknown'}'),
              ],
            ),
          ),
        ),
      );
}
