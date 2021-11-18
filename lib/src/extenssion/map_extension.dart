extension MapExt on Map {
  bool hasKey(String key) {
    try {
      final _ = [key];
      return true;
    } catch (e) {
      return false;
    }
  }
}