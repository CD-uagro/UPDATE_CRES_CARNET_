// lib/screens/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../security/auth_service.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  final Duration autoLock;
  const AuthGate({
    super.key,
    required this.child,
    this.autoLock = const Duration(minutes: 10),
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final _auth = AuthService();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();

  bool _hasPassword = false;
  bool _unlocked = false;
  bool _busy = true;
  String? _error;
  Timer? _idleTimer;

  // Ojitos
  bool _showPwd = false;
  bool _showPwd2 = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      _hasPassword = await _auth.isPasswordSet();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _resetIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pwd.dispose();
    _pwd2.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _lock();
    }
  }

  void _lock() {
    setState(() {
      _unlocked = false;
      _error = null;
    });
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.autoLock, _lock);
  }

  void _onUserActivity() {
    if (_unlocked) _resetIdleTimer();
  }

  Future<void> _createPassword() async {
    // En modo corporativo no se mostrará esta rama porque _hasPassword será true
    final p1 = _pwd.text.trim(), p2 = _pwd2.text.trim();
    if (p1.length < 8) {
      setState(
          () => _error = 'La contraseña debe tener al menos 8 caracteres.');
      return;
    }
    if (p1 != p2) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() => _error = null);
    await _auth.setupPassword(p1);
    setState(() {
      _hasPassword = true;
      _unlocked = true;
    });
    _resetIdleTimer();
  }

  Future<void> _login() async {
    final ok = await _auth.verifyPassword(_pwd.text.trim());
    if (!ok) {
      setState(() => _error = 'Contraseña incorrecta.');
      return;
    }
    setState(() {
      _error = null;
      _unlocked = true;
    });
    _resetIdleTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_unlocked) {
      return GestureDetector(
        onTap: _onUserActivity,
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _hasPassword ? Icons.lock_outline : Icons.shield_outlined,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasPassword ? 'Ingresar' : 'Crear contraseña',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    // Subtítulo profesional
                    Text(
                      'Sistema de atención en Salud',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Contraseña
                    TextField(
                      controller: _pwd,
                      obscureText: !_showPwd,
                      textInputAction: _hasPassword
                          ? TextInputAction.done
                          : TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _showPwd = !_showPwd),
                          icon: Icon(_showPwd
                              ? Icons.visibility_off
                              : Icons.visibility),
                          tooltip: _showPwd ? 'Ocultar' : 'Mostrar',
                        ),
                      ),
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: (_) => _hasPassword ? _login() : null,
                    ),

                    // Confirmación (solo al crear)
                    if (!_hasPassword) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pwd2,
                        obscureText: !_showPwd2,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                          border: OutlineInputBorder(),
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showPwd2 = !_showPwd2),
                            icon: Icon(_showPwd2
                                ? Icons.visibility_off
                                : Icons.visibility),
                            tooltip: _showPwd2 ? 'Ocultar' : 'Mostrar',
                          ),
                        ),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        onSubmitted: (_) => _createPassword(),
                      ),
                    ],

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _hasPassword ? _login : _createPassword,
                        icon: Icon(_hasPassword ? Icons.login : Icons.check),
                        label: Text(
                            _hasPassword ? 'Ingresar' : 'Guardar contraseña'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Desbloqueado
    return Listener(
      onPointerDown: (_) => _onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
