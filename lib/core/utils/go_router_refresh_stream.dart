import 'dart:async';
import 'package:flutter/foundation.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final List<StreamSubscription<dynamic>> _subscriptions;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscriptions = [
      stream.asBroadcastStream().listen(
        (dynamic _) => notifyListeners(),
      )
    ];
  }

  // Constructor untuk multiple streams
  GoRouterRefreshStream.multiple(List<Stream<dynamic>> streams) {
    notifyListeners();
    _subscriptions = streams.map((stream) {
      return stream.asBroadcastStream().listen(
        (dynamic _) => notifyListeners(),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
