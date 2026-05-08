import 'package:geolocator/geolocator.dart';
import 'user_service.dart';

class LocationService {
  static final _userService = UserService();

  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  static Future<void> updateLocation(String uid) async {
    try {
      final granted = await requestPermission();
      if (!granted) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await _userService.updateLocation(uid, position.latitude, position.longitude);
    } catch (_) {
      // Location unavailable — silently skip
    }
  }
}
