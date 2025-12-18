
import 'dart:convert';
import 'package:html/dom.dart';

class ExtractorUtils {
  /// Matches a regex against a string and returns the first group.
  /// If [group] is provided, returns that group index.
  static String? searchRegex(
    RegExp regex,
    String content, {
    int group = 1,
    String? defaultResult,
  }) {
    final match = regex.firstMatch(content);
    if (match != null && match.groupCount >= group) {
      return match.group(group);
    }
    return defaultResult;
  }

  /// Parses a JSON string, handling potential cleanup if it's inside JS.
  static dynamic parseJson(String jsonStr) {
    try {
      return jsonDecode(jsonStr);
    } catch (e) {
      // Basic cleanup for JS objects not strictly JSON
      // This is a simplified version; complex JS parsing requires a real parser
      try {
        // Try to quote keys if they are unquoted (basic heuristic)
        final fixed = jsonStr.replaceAllMapped(
            RegExp(r'([{,]\s*)([a-zA-Z0-9_]+)\s*:'),
            (m) => '${m.group(1)}"${m.group(2)}":');
        return jsonDecode(fixed);
      } catch (_) {
        return null;
      }
    }
  }

  /// Parses an ISO 8601 duration string (e.g., PT1H2M3S) into seconds.
  static int? parseDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return null;
    
    // Handle PT format (ISO 8601)
    if (durationStr.startsWith('PT')) {
       final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
       final match = regex.firstMatch(durationStr);
       if (match != null) {
         final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
         final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
         final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
         return hours * 3600 + minutes * 60 + seconds;
       }
      return null; 
    }

    // Handle HH:MM:SS format
    final parts = durationStr.split(':').map(int.tryParse).toList();
    if (parts.any((p) => p == null)) return null;
    
    if (parts.length == 3) {
      return (parts[0]! * 3600) + (parts[1]! * 60) + parts[2]!;
    } else if (parts.length == 2) {
      return (parts[0]! * 60) + parts[1]!;
    }
    
    return int.tryParse(durationStr);
  }

  static String? determineExt(String? url) {
    if (url == null) return null;
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final dotIndex = path.lastIndexOf('.');
      if (dotIndex != -1 && dotIndex < path.length - 1) {
        final ext = path.substring(dotIndex + 1).toLowerCase();
        // Basic validation: ensure it's alphanumeric and reasonable length
        if (RegExp(r'^[a-z0-9]{1,5}$').hasMatch(ext)) {
          return ext;
        }
      }
    } catch (_) {}
    return null;
  }

  static String? unifiedTimestamp(String? dateStr) {
    if (dateStr == null) return null;
    // Basic implementation - tries to convert to YYYYMMDD
    return dateStr.replaceAll(RegExp(r'[-/.]'), '');
  }

  static int? intOrNone(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? floatOrNone(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  static String? getMetaContent(Document doc, String property) {
    // meta name=property content=...
    var meta = doc.querySelector('meta[name="$property"]');
    if (meta != null) return meta.attributes['content'];
    
    // meta property=property content=...
    meta = doc.querySelector('meta[property="$property"]');
    if (meta != null) return meta.attributes['content'];
    
    return null;
  }

  /// Clean up a URL (trim, remove fragment if not needed, etc)
  static String urlJoin(String base, String url) {
    // Basic implementation using Uri
    try {
      final baseUrl = Uri.parse(base);
      return baseUrl.resolve(url).toString();
    } catch (e) {
      return url;
    }
  }
}
