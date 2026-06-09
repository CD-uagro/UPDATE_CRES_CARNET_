// lib/security/auth_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _kSalt = 'pwd_salt';
  static const _kHash = 'pwd_hash';
  static const _kIters = 'pwd_iters';
  static const _kVer = 'pwd_kdf_version';

  static const int _defaultIterations = 150000;
  static const int _kdfVersion = 1;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  bool _orgMode = false;
  late List<int> _orgSalt;
  late List<int> _orgHash;
  int _orgIters = _defaultIterations;

  AuthService() {
    _tryLoadOrgConfig();
  }

  void _tryLoadOrgConfig() {
    final candidates = <String>[
      pathJoin(Directory.current.path, 'cres_pwd.json'),
      () {
        try {
          final exeDir = File(Platform.resolvedExecutable).parent.path;
          return pathJoin(exeDir, 'cres_pwd.json');
        } catch (_) {
          return '';
        }
      }(),
    ].where((p) => p.isNotEmpty).toList();

    for (final p in candidates) {
      final f = File(p);
      if (f.existsSync()) {
        try {
          final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
          final saltB64 = (m['salt'] as String?)?.trim();
          final hashB64 = (m['hash'] as String?)?.trim();
          final iters = int.tryParse('${m['iters'] ?? _defaultIterations}');
          if (saltB64 != null && hashB64 != null && iters != null) {
            _orgSalt = base64Decode(saltB64);
            _orgHash = base64Decode(hashB64);
            _orgIters = iters;
            _orgMode = true;
            // ignore: avoid_print
            print('🔒 AuthService: ORG MODE activo con archivo ${f.path}');
            return;
          }
        } catch (e) {
          // ignore: avoid_print
          print('AuthService: error leyendo cres_pwd.json: $e');
        }
      }
    }
    _orgMode = false;
  }

  String pathJoin(String a, String b) {
    if (a.endsWith('\\') || a.endsWith('/')) return '$a$b';
    final sep = Platform.pathSeparator;
    return '$a$sep$b';
  }

  Future<bool> isPasswordSet() async {
    if (_orgMode) return true;
    final hash = await _storage.read(key: _kHash);
    final salt = await _storage.read(key: _kSalt);
    return hash != null && salt != null;
  }

  Future<void> setupPassword(String password) async {
    if (_orgMode) {
      throw StateError(
          'Modo organización activo: la contraseña se define en cres_pwd.json');
    }
    final salt = _randomBytes(16);
    final key = await _deriveKey(password, salt, _defaultIterations);
    await _storage.write(key: _kSalt, value: base64Encode(salt));
    await _storage.write(key: _kHash, value: base64Encode(key));
    await _storage.write(key: _kIters, value: _defaultIterations.toString());
    await _storage.write(key: _kVer, value: _kdfVersion.toString());
  }

  Future<bool> verifyPassword(String password) async {
    if (_orgMode) {
      final key = await _deriveKey(password, _orgSalt, _orgIters);
      return _constTimeEquals(_orgHash, key);
    }
    final saltB64 = await _storage.read(key: _kSalt);
    final hashB64 = await _storage.read(key: _kHash);
    final itersStr = await _storage.read(key: _kIters);
    if (saltB64 == null || hashB64 == null || itersStr == null) return false;

    final salt = base64Decode(saltB64);
    final iters = int.tryParse(itersStr) ?? _defaultIterations;
    final key = await _deriveKey(password, salt, iters);
    return _constTimeEquals(base64Decode(hashB64), key);
  }

  Future<bool> changePassword(String current, String next) async {
    if (_orgMode) return false;
    if (!await verifyPassword(current)) return false;
    await setupPassword(next);
    return true;
  }

  Future<void> wipe() async {
    if (_orgMode) return;
    await _storage.delete(key: _kSalt);
    await _storage.delete(key: _kHash);
    await _storage.delete(key: _kIters);
    await _storage.delete(key: _kVer);
  }

  List<int> _randomBytes(int length) {
    final r = Random.secure();
    return List<int>.generate(length, (_) => r.nextInt(256));
  }

  Future<List<int>> _deriveKey(
      String password, List<int> salt, int iterations) async {
    final algo =
        Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256);
    final secretKey = await algo.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return await secretKey.extractBytes();
  }

  bool _constTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
