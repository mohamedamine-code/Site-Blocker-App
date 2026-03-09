import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendBlocklistService {
  BackendBlocklistService._();

  static final BackendBlocklistService instance = BackendBlocklistService._();

  static const String _apiUrl =
      String.fromEnvironment('BLOCKLIST_API_URL', defaultValue: '');

  Future<Set<String>> fetchBlockedDomains() async {
    if (_apiUrl.trim().isEmpty) {
      return <String>{};
    }

    final uri = Uri.tryParse(_apiUrl.trim());
    if (uri == null) {
      return <String>{};
    }

    try {
      final response = await http
          .get(
            uri,
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return <String>{};
      }

      final body = jsonDecode(response.body);
      final rawDomains = _extractDomains(body);
      return rawDomains
          .map(_normalizeDomain)
          .where((domain) => domain.isNotEmpty)
          .toSet();
    } catch (_) {
      // Keep local blocking functional even if backend fails.
      return <String>{};
    }
  }

  Iterable<String> _extractDomains(dynamic payload) {
    if (payload is List) {
      return payload.map((item) => item.toString());
    }

    if (payload is Map<String, dynamic>) {
      final blockedDomains = payload['blockedDomains'];
      if (blockedDomains is List) {
        return blockedDomains.map((item) => item.toString());
      }

      final domains = payload['domains'];
      if (domains is List) {
        return domains.map((item) => item.toString());
      }

      final rules = payload['rules'];
      if (rules is List) {
        return rules
            .map((item) {
              if (item is Map<String, dynamic>) {
                return (item['domain'] ?? item['url'])?.toString();
              }
              return item?.toString();
            })
            .whereType<String>();
      }
    }

    return const <String>[];
  }

  String _normalizeDomain(String rawValue) {
    var value = rawValue.trim().toLowerCase();
    if (value.isEmpty) {
      return '';
    }

    if (value.startsWith('*.')) {
      value = value.substring(2);
    }

    if (!value.contains('://')) {
      value = 'https://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return '';
    }

    var host = uri.host.isNotEmpty ? uri.host : uri.path;
    host = host.trim().toLowerCase();
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }

    return host.trim().replaceAll(RegExp(r'\.+$'), '');
  }
}
