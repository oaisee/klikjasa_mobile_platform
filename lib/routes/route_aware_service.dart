import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteAwareService extends NavigatorObserver {
  static const String _lastRouteKey = 'last_route';

  Future<void> saveLastRoute(String route) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Simpan hanya rute yang valid dan bukan rute teknis/splash
      if (route.isNotEmpty && route != '/' && route != '/login' && route != '/register') {
        await prefs.setString(_lastRouteKey, route);
        debugPrint('RouteAwareService: Saved last route: $route');
      }
    } catch (e) {
      debugPrint('RouteAwareService: Failed to save last route: $e');
    }
  }

  Future<String?> getLastRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRoute = prefs.getString(_lastRouteKey);
      debugPrint('RouteAwareService: Retrieved last route: $lastRoute');
      return lastRoute;
    } catch (e) {
      debugPrint('RouteAwareService: Failed to get last route: $e');
      return null;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      saveLastRoute(route.settings.name!);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      saveLastRoute(newRoute!.settings.name!);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      saveLastRoute(previousRoute!.settings.name!);
    }
  }
}
