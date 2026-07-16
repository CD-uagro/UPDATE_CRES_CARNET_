import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../data/db.dart' as db_data;
import '../../data/multitenant_api_service.dart';
import '../dashboard_screen.dart';
import 'temporary_password_change_screen.dart';

class MultitenantEntryScreen extends StatefulWidget {
  final db_data.AppDatabase db;
  final MultitenantApiService? api;

  const MultitenantEntryScreen({super.key, required this.db, this.api});

  @override
  State<MultitenantEntryScreen> createState() => _MultitenantEntryScreenState();
}

class _MultitenantEntryScreenState extends State<MultitenantEntryScreen> {
  final _institutionCode = TextEditingController(text: 'LOYOLA-DEMO-2026');
  final _username = TextEditingController();
  final _password = TextEditingController();
  late final MultitenantApiService _api;

  InstitutionBranding? _branding;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? MultitenantApiService();
  }

  @override
  void dispose() {
    _institutionCode.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final branding = await _api.resolveInstitution(_institutionCode.text);
      setState(() => _branding = branding);
    } catch (_) {
      setState(() => _error = 'No se pudo resolver la institucion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _api.login(
        institutionCode: _institutionCode.text,
        username: _username.text,
        password: _password.text,
      );
      if (!mounted) return;
      if (session.requiresPasswordChange) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TemporaryPasswordChangeScreen(api: _api),
          ),
        );
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(db: widget.db)),
      );
    } on MultitenantAuthException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Servidor no disponible.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.current.backendBaseUrl.trim().isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Configuracion incompleta: falta MULTITENANT_API_BASE_URL.',
          ),
        ),
      );
    }

    final branding = _branding;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  branding?.displayName ?? AppConfig.current.systemName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (branding?.demo == true)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Entorno demo', textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 24),
                TextField(
                  controller: _institutionCode,
                  decoration: const InputDecoration(
                    labelText: 'Codigo institucional',
                    hintText: 'LOYOLA-DEMO-2026',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : _resolve,
                  child: const Text('Continuar'),
                ),
                if (branding != null) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _username,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contrasena'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _branding = null),
                      child: const Text('Cambiar codigo institucional'),
                    ),
                  ),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: const Text('Iniciar sesion'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () {},
                    child: const Text('Recuperar acceso'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
