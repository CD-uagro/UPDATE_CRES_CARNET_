import 'package:flutter/material.dart';

import '../../data/multitenant_api_service.dart';

class TemporaryPasswordChangeScreen extends StatefulWidget {
  final MultitenantApiService api;
  final VoidCallback? onPasswordChanged;

  const TemporaryPasswordChangeScreen({
    super.key,
    required this.api,
    this.onPasswordChanged,
  });

  @override
  State<TemporaryPasswordChangeScreen> createState() =>
      _TemporaryPasswordChangeScreenState();
}

class _TemporaryPasswordChangeScreenState
    extends State<TemporaryPasswordChangeScreen> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _error = 'La nueva contrasena no coincide.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.api.changeTemporaryPassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      widget.onPasswordChanged?.call();
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contrasena actualizada. Inicia sesion nuevamente.'),
        ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contrasena temporal')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tu contrasena temporal debe cambiarse antes de continuar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _currentPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contrasena actual',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contrasena',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nueva contrasena',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _changePassword,
                  child: const Text('Cambiar contrasena'),
                ),
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
