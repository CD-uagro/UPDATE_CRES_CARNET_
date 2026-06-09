import 'dart:convert';
import 'dart:io' show HttpDate;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Cliente REST mínimo para Azure Cosmos DB (API SQL)
/// - Maneja firma HMAC y cabeceras
/// - Reintenta automáticamente con 4 variantes de firma para evitar 401
class CosmosClient {
  final String accountEndpoint;
  final String masterKeyBase64;
  final String databaseId;
  final String containerId;
  final String partitionKeyPath;

  CosmosClient({
    required this.accountEndpoint,
    required this.masterKeyBase64,
    required this.databaseId,
    required this.containerId,
    required this.partitionKeyPath,
  });

  Uri _uri(String path) => Uri.parse('$accountEndpoint$path');

  String _rfc1123Now() => HttpDate.format(DateTime.now().toUtc());

  String _mkAuth({
    required String verb,
    required String resourceType,
    required String resourceLink,
    required String dateRfc1123,
    required bool urlEncodeAuth,
  }) {
    final toSign =
        '${verb.toLowerCase()}\n${resourceType.toLowerCase()}\n$resourceLink\n${dateRfc1123.toLowerCase()}\n\n';

    final key = base64Decode(masterKeyBase64);
    final sig = Hmac(sha256, key).convert(utf8.encode(toSign));
    final base = 'type=master&ver=1.0&sig=${base64Encode(sig.bytes)}';
    return urlEncodeAuth ? Uri.encodeComponent(base) : base;
  }

  Map<String, String> _baseHeaders({
    required String verb,
    required String resourceType,
    required String resourceLink,
    required String dateRfc1123,
    String? contentType,
    required bool urlEncodeAuth,
  }) {
    final auth = _mkAuth(
      verb: verb,
      resourceType: resourceType,
      resourceLink: resourceLink,
      dateRfc1123: dateRfc1123,
      urlEncodeAuth: urlEncodeAuth,
    );
    final h = <String, String>{
      'x-ms-date': dateRfc1123,
      'x-ms-version': '2018-12-31',
      'Authorization': auth,
      'Accept': 'application/json',
    };
    if (contentType != null) h['Content-Type'] = contentType;
    return h;
  }

  /// Intenta la misma petición con 4 variantes de firma para esquivar 401.
  Future<http.Response> _sendWithAuthFallbacks({
    required String verb,
    required String resourceType,
    required String resourceLinkExact,
    required String path,
    String? contentType,
    Map<String, String>? extraHeaders,
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final date = _rfc1123Now();
    final resourceLinkLower = resourceLinkExact.toLowerCase();

    // (linkExact, urlEnc), (linkLower, urlEnc), (linkExact, raw), (linkLower, raw)
    final variants = <({String link, bool urlEnc})>[
      (link: resourceLinkExact, urlEnc: true),
      (link: resourceLinkLower, urlEnc: true),
      (link: resourceLinkExact, urlEnc: false),
      (link: resourceLinkLower, urlEnc: false),
    ];

    http.Response? last;
    for (final v in variants) {
      final headers = _baseHeaders(
        verb: verb,
        resourceType: resourceType,
        resourceLink: v.link,
        dateRfc1123: date,
        contentType: contentType,
        urlEncodeAuth: v.urlEnc,
      );
      if (extraHeaders != null) headers.addAll(extraHeaders);

      try {
        late http.Response r;
        final uri = _uri(path);
        if (verb == 'GET') {
          r = await http.get(uri, headers: headers).timeout(timeout);
        } else if (verb == 'POST') {
          r = await http
              .post(uri, headers: headers, body: body)
              .timeout(timeout);
        } else {
          throw UnsupportedError('Verb $verb');
        }

        // 200/201/404 nos interesan directo. Si 401 probamos la siguiente variante.
        if (r.statusCode != 401) return r;
        last = r; // guarda el último 401 por si agotamos intentos
      } catch (e) {
        rethrow; // errores de red reales
      }
    }

    // Si todas las variantes devolvieron 401, devolvemos el último como error
    throw Exception(
        'Cosmos ${verb.toLowerCase()} 401 after fallbacks: ${last?.body}');
  }

  // ==================== OPERACIONES ====================

  Future<Map<String, dynamic>> read({
    required String id,
    String? partitionKeyValue,
  }) async {
    final docLink = 'dbs/$databaseId/colls/$containerId/docs/$id';
    final path = '/$docLink';

    final extra = <String, String>{};
    if (partitionKeyValue != null) {
      extra['x-ms-documentdb-partitionkey'] = jsonEncode([partitionKeyValue]);
    }

    final r = await _sendWithAuthFallbacks(
      verb: 'GET',
      resourceType: 'docs',
      resourceLinkExact:
          docLink, // usamos EXACTO; el fallback prueba lower también
      path: path,
      extraHeaders: extra,
    );

    if (r.statusCode != 200) {
      throw Exception('Cosmos read ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> upsert({
    required Map<String, dynamic> doc,
    required String partitionKeyValue,
  }) async {
    final collLink = 'dbs/$databaseId/colls/$containerId';
    final path = '/$collLink/docs';

    final extra = <String, String>{
      'x-ms-documentdb-is-upsert': 'True',
      'x-ms-documentdb-partitionkey': jsonEncode([partitionKeyValue]),
    };

    final r = await _sendWithAuthFallbacks(
      verb: 'POST',
      resourceType: 'docs',
      resourceLinkExact: collLink,
      path: path,
      contentType: 'application/json',
      extraHeaders: extra,
      body: jsonEncode(doc),
    );

    if (r.statusCode != 201 && r.statusCode != 200) {
      throw Exception('Cosmos upsert ${r.statusCode}: ${r.body}');
    }
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// Query cross-partition (no mandamos header de partition key).
  Future<Map<String, dynamic>> query({
    required String query,
    Map<String, dynamic>? parameters,
    int maxItemCount = 100,
    String? continuation,
  }) async {
    final collLink = 'dbs/$databaseId/colls/$containerId';
    final path = '/$collLink/docs';

    final extra = <String, String>{
      'x-ms-documentdb-isquery': 'True',
      'x-ms-documentdb-query-enablecrosspartition': 'true',
      'x-ms-max-item-count': '$maxItemCount',
    };
    if (continuation != null && continuation.isNotEmpty) {
      extra['x-ms-continuation'] = continuation;
    }

    final params = (parameters ?? {});
    final body = jsonEncode({
      'query': query,
      'parameters': params.entries
          .map((e) => {'name': '@${e.key}', 'value': e.value})
          .toList(),
    });

    final r = await _sendWithAuthFallbacks(
      verb: 'POST',
      resourceType: 'docs',
      resourceLinkExact: collLink,
      path: path,
      contentType: 'application/query+json',
      extraHeaders: extra,
      body: body,
    );

    if (r.statusCode != 200) {
      throw Exception('Cosmos query ${r.statusCode}: ${r.body}');
    }
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    data['_continuation'] = r.headers['x-ms-continuation'];
    return data;
  }
}
