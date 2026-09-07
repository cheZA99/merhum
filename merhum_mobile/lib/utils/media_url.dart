import '../config/api_config.dart';

/// The API stores photos as paths like /uploads/photos/x.jpg, so they need the host in front.
String? mediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$apiBaseUrl$path';
}
