# dual_screen

A Flutter plugin to determine whether the device supports dual screen and whether the app is currently spanned across both screen.

## Usage

```import 'package:dual_screen/dual_screen.dart';```

Determine whether the app is run on a dual screen device

```bool isDualDevice = await DualScreen.isDualScreenDevice;```

Determine whether the app is currently spanned across both screens

```bool isAppSpanned = await DualScreen.isAppSpanned;```

Subscribing to app spanned across both screen stream

```DualScreen.isAppSpannedStream().listen((data) => setState(() => _isAppSpannedStream = data));```


## Getting Started

See the example directory for a complete sample app

## Issues and feedback

Please file issues, bugs, or feature requests in our github issue tracker.
