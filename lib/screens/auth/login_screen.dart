// lib/screens/auth/login_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../dashboard_screen.dart';
import '../../data/auth_service.dart';
import '../../data/db.dart' as app_db;
import '../../services/version_service.dart';

const Color _mockupBlue = Color(0xFF072B72);
const Color _mockupDeepBlue = Color(0xFF041D4D);
const Color _mockupRed = Color(0xFFC8102E);
const Color _mockupGold = Color(0xFFD49A19);
const Color _mockupSoftBlue = Color(0xFFEAF2FF);

class LoginScreen extends StatefulWidget {
  final app_db.AppDatabase db;

  const LoginScreen({super.key, required this.db});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedCampus = 'cres-llano-largo'; // Actualizado al nuevo formato
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Colores institucionales UAGro
  static const Color _azulMarino = Color(0xFF0F2A5A);
  static const Color _rojo = Color(0xFFC8102E);
  static const Color _dorado = Color(0xFFFFB81C);
  // 88 Instituciones UAGro - Sincronizado con backend
  final List<Map<String, String>> _campusList = [
    // CRES - Centros Regionales de Educación Superior (6)
    {'value': 'cres-cruz-grande', 'label': 'CRES Cruz Grande'},
    {'value': 'cres-zumpango', 'label': 'CRES Zumpango del Río'},
    {'value': 'cres-taxco-viejo', 'label': 'CRES Taxco el Viejo'},
    {'value': 'cres-huamuxtitlan', 'label': 'CRES Huamuxtitlán'},
    {'value': 'cres-llano-largo', 'label': 'CRES Llano Largo'},
    {'value': 'cres-tecpan', 'label': 'CRES Tecpan de Galeana'},

    // Clínicas Universitarias (4)
    {
      'value': 'clinica-chilpancingo',
      'label': 'Clínica Universitaria Chilpancingo'
    },
    {'value': 'clinica-acapulco', 'label': 'Clínica Universitaria Acapulco'},
    {'value': 'clinica-iguala', 'label': 'Clínica Universitaria Iguala'},
    {'value': 'clinica-ometepec', 'label': 'Clínica Universitaria Ometepec'},

    // Facultades (20)
    {
      'value': 'fac-gobierno',
      'label': 'Facultad de Ciencias Políticas y Gobierno'
    },
    {
      'value': 'fac-arquitectura',
      'label': 'Facultad de Arquitectura y Urbanismo'
    },
    {
      'value': 'fac-quimico',
      'label': 'Facultad de Ciencias Químico Biológicas'
    },
    {
      'value': 'fac-comunicacion',
      'label': 'Facultad de Ciencias de la Comunicación'
    },
    {
      'value': 'fac-derecho-chil',
      'label': 'Facultad de Derecho (Chilpancingo)'
    },
    {'value': 'fac-filosofia', 'label': 'Facultad de Filosofía y Letras'},
    {'value': 'fac-ingenieria', 'label': 'Facultad de Ingeniería'},
    {
      'value': 'fac-matematicas-centro',
      'label': 'Facultad de Matemáticas (Centro)'
    },
    {
      'value': 'fac-contaduria',
      'label': 'Facultad de Contaduría y Administración'
    },
    {'value': 'fac-derecho-aca', 'label': 'Facultad de Derecho (Acapulco)'},
    {'value': 'fac-ecologia', 'label': 'Facultad de Ecología Marina'},
    {'value': 'fac-economia', 'label': 'Facultad de Economía'},
    {'value': 'fac-enfermeria2', 'label': 'Facultad de Enfermería 2'},
    {'value': 'fac-matematicas-sur', 'label': 'Facultad de Matemáticas (Sur)'},
    {'value': 'fac-lenguas', 'label': 'Facultad de Lenguas Extranjeras'},
    {'value': 'fac-medicina', 'label': 'Facultad de Medicina'},
    {'value': 'fac-odontologia', 'label': 'Facultad de Odontología'},
    {'value': 'fac-turismo', 'label': 'Facultad de Turismo'},
    {
      'value': 'fac-agropecuarias',
      'label': 'Facultad de Ciencias Agropecuarias'
    },
    {
      'value': 'fac-matematicas-norte',
      'label': 'Facultad de Matemáticas (Norte)'
    },

    // Preparatorias (50)
    {'value': 'prep-1', 'label': 'Preparatoria 1'},
    {'value': 'prep-2', 'label': 'Preparatoria 2'},
    {'value': 'prep-3', 'label': 'Preparatoria 3'},
    {'value': 'prep-4', 'label': 'Preparatoria 4'},
    {'value': 'prep-5', 'label': 'Preparatoria 5'},
    {'value': 'prep-6', 'label': 'Preparatoria 6'},
    {'value': 'prep-7', 'label': 'Preparatoria 7'},
    {'value': 'prep-8', 'label': 'Preparatoria 8'},
    {'value': 'prep-9', 'label': 'Preparatoria 9'},
    {'value': 'prep-10', 'label': 'Preparatoria 10'},
    {'value': 'prep-11', 'label': 'Preparatoria 11'},
    {'value': 'prep-12', 'label': 'Preparatoria 12'},
    {'value': 'prep-13', 'label': 'Preparatoria 13'},
    {'value': 'prep-14', 'label': 'Preparatoria 14'},
    {'value': 'prep-15', 'label': 'Preparatoria 15'},
    {'value': 'prep-16', 'label': 'Preparatoria 16'},
    {'value': 'prep-17', 'label': 'Preparatoria 17'},
    {'value': 'prep-18', 'label': 'Preparatoria 18'},
    {'value': 'prep-19', 'label': 'Preparatoria 19'},
    {'value': 'prep-20', 'label': 'Preparatoria 20'},
    {'value': 'prep-21', 'label': 'Preparatoria 21'},
    {'value': 'prep-22', 'label': 'Preparatoria 22'},
    {'value': 'prep-23', 'label': 'Preparatoria 23'},
    {'value': 'prep-24', 'label': 'Preparatoria 24'},
    {'value': 'prep-25', 'label': 'Preparatoria 25'},
    {'value': 'prep-26', 'label': 'Preparatoria 26'},
    {'value': 'prep-27', 'label': 'Preparatoria 27'},
    {'value': 'prep-28', 'label': 'Preparatoria 28'},
    {'value': 'prep-29', 'label': 'Preparatoria 29'},
    {'value': 'prep-30', 'label': 'Preparatoria 30'},
    {'value': 'prep-31', 'label': 'Preparatoria 31'},
    {'value': 'prep-32', 'label': 'Preparatoria 32'},
    {'value': 'prep-33', 'label': 'Preparatoria 33'},
    {'value': 'prep-34', 'label': 'Preparatoria 34'},
    {'value': 'prep-35', 'label': 'Preparatoria 35'},
    {'value': 'prep-36', 'label': 'Preparatoria 36'},
    {'value': 'prep-37', 'label': 'Preparatoria 37'},
    {'value': 'prep-38', 'label': 'Preparatoria 38'},
    {'value': 'prep-39', 'label': 'Preparatoria 39'},
    {'value': 'prep-40', 'label': 'Preparatoria 40'},
    {'value': 'prep-41', 'label': 'Preparatoria 41'},
    {'value': 'prep-42', 'label': 'Preparatoria 42'},
    {'value': 'prep-43', 'label': 'Preparatoria 43'},
    {'value': 'prep-44', 'label': 'Preparatoria 44'},
    {'value': 'prep-45', 'label': 'Preparatoria 45'},
    {'value': 'prep-46', 'label': 'Preparatoria 46'},
    {'value': 'prep-47', 'label': 'Preparatoria 47'},
    {'value': 'prep-48', 'label': 'Preparatoria 48'},
    {'value': 'prep-49', 'label': 'Preparatoria 49'},
    {'value': 'prep-50', 'label': 'Preparatoria 50'},

    // Rectoría y Coordinaciones Regionales (8)
    {'value': 'rectoria', 'label': 'Rectoría'},
    {'value': 'coord-sur', 'label': 'Coordinación Regional Sur'},
    {'value': 'coord-centro', 'label': 'Coordinación Regional Centro'},
    {'value': 'coord-norte', 'label': 'Coordinación Regional Norte'},
    {
      'value': 'coord-costa-chica',
      'label': 'Coordinación Regional Costa Chica'
    },
    {
      'value': 'coord-costa-grande',
      'label': 'Coordinación Regional Costa Grande'
    },
    {'value': 'coord-montana', 'label': 'Coordinación Regional Montaña'},
    {
      'value': 'coord-tierra-caliente',
      'label': 'Coordinación Regional Tierra Caliente'
    },
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        campus: _selectedCampus,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Mostrar mensaje si es modo offline
        if (result['mode'] == 'offline' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.cloud_off, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Modo sin conexión: Los datos se sincronizarán cuando tengas internet'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Login exitoso - navegar al dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DashboardScreen(db: widget.db),
            ),
          );
        }
      } else {
        // Login fallido - mostrar error
        setState(() {
          _errorMessage = result['error'] ?? 'Error desconocido';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<String> _getVersionString() async {
    try {
      final versionService = VersionService();
      if (!versionService.isLoaded) {
        await versionService.loadVersion();
      }
      final info = versionService.versionInfo;
      if (info != null) {
        return '${info.version} (${info.buildNumber})';
      }
    } catch (e) {
      debugPrint('Error al obtener version: $e');
    }
    return 'Version no disponible';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 980;
          final height =
              math.max(constraints.maxHeight, isDesktop ? 720.0 : 980.0);

          return SingleChildScrollView(
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  const Positioned.fill(child: _InstitutionalBackground()),
                  Positioned(
                    top: isDesktop ? 42 : 26,
                    left: isDesktop ? 46 : 22,
                    right: isDesktop ? 380 : 22,
                    child: _UniversityHeader(compact: !isDesktop),
                  ),
                  if (isDesktop)
                    const Positioned(
                      top: 54,
                      right: 58,
                      child: _SupportBlock(),
                    ),
                  Positioned(
                    top: isDesktop ? 238 : 188,
                    left: isDesktop ? 205 : 24,
                    right: isDesktop ? 650 : 24,
                    child: _HeroBrand(compact: !isDesktop),
                  ),
                  Positioned(
                    top: isDesktop ? 172 : 482,
                    right: isDesktop ? 72 : 22,
                    left: isDesktop ? null : 22,
                    child: SizedBox(
                      width: isDesktop ? 520 : null,
                      child: _buildLoginCard(),
                    ),
                  ),
                  Positioned(
                    left: isDesktop ? 174 : 22,
                    right: isDesktop ? 130 : 22,
                    bottom: isDesktop ? 96 : 92,
                    child: _FeatureFooter(compact: !isDesktop),
                  ),
                  Positioned(
                    left: isDesktop ? 54 : 20,
                    right: isDesktop ? 38 : 20,
                    bottom: 16,
                    child: FutureBuilder<String>(
                      future: _getVersionString(),
                      builder: (context, snapshot) {
                        return _StatusFooter(
                          version: snapshot.data ?? 'Cargando version',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _buildIdentityPanel(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 22 : 34),
      decoration: BoxDecoration(
        color: _azulMarino,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
            compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Universidad Autónoma de Guerrero',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'CRES Llano Largo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 24 : 48),
          Text(
            'SASU',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 58,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sistema de Atención en Salud Universitaria',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: compact ? 20 : 24,
              fontWeight: FontWeight.w700,
              height: 1.16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 68,
            height: 4,
            decoration: BoxDecoration(
              color: _rojo,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Dirección de Innovación en la Gestión de la Salud Universitaria',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: compact ? WrapAlignment.center : WrapAlignment.start,
            children: const [
              _ModuleChip(icon: Icons.badge_outlined, label: 'Carnets'),
              _ModuleChip(icon: Icons.folder_open, label: 'Expedientes'),
              _ModuleChip(icon: Icons.description_outlined, label: 'Notas'),
              _ModuleChip(icon: Icons.campaign, label: 'Promoción'),
              _ModuleChip(icon: Icons.vaccines, label: 'Vacunación'),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 42),
            Row(
              children: [
                Icon(Icons.verified_user_outlined, color: _dorado, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Acceso seguro para la atención, registro y seguimiento de servicios universitarios de salud.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 18,
      shadowColor: _mockupDeepBlue.withValues(alpha: 0.24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        padding: const EdgeInsets.fromLTRB(52, 46, 52, 34),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: _mockupBlue,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: _mockupBlue.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(child: _UagroSeal(size: 44)),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            color: _mockupDeepBlue,
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Container(
                          width: 72,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _mockupRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
              TextFormField(
                controller: _usernameController,
                decoration:
                    _inputDecoration(label: 'Usuario', icon: Icons.person),
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa tu usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration(
                  label: 'Contraseña',
                  icon: Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: _azulMarino,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                enabled: !_isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedCampus,
                decoration: _inputDecoration(
                  label: 'Campus',
                  icon: Icons.location_city,
                ),
                isExpanded: true,
                items: _campusList.map((campus) {
                  return DropdownMenuItem<String>(
                    value: campus['value'],
                    child: Text(
                      campus['label']!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCampus = value!;
                        });
                      },
              ),
              const SizedBox(height: 34),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _rojo.withValues(alpha: 0.08),
                    border: Border.all(color: _rojo.withValues(alpha: 0.52)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: _rojo, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: _rojo),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: 68,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _mockupBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 8,
                    shadowColor: _mockupBlue.withValues(alpha: 0.36),
                  ),
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.lock_open, size: 20),
                  label: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined,
                      color: Colors.amber[700], size: 18),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Acceso seguro y confidencial',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _azulMarino),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _mockupDeepBlue.withValues(alpha: 0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _mockupDeepBlue.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _mockupBlue, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ModuleChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstitutionalBackground extends StatelessWidget {
  const _InstitutionalBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InstitutionalBackgroundPainter(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _mockupSoftBlue.withValues(alpha: 0.92),
              Colors.white,
            ],
          ),
        ),
      ),
    );
  }
}

class _InstitutionalBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    paint.color = const Color(0xFFE4ECF8).withValues(alpha: 0.48);
    for (var i = -1; i < 5; i++) {
      final dx = size.width * (0.22 + i * 0.18);
      final path = Path()
        ..moveTo(dx, 0)
        ..lineTo(dx + 180, 0)
        ..lineTo(dx - 60, size.height)
        ..lineTo(dx - 240, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }

    paint.color = const Color(0xFFD8E4F3).withValues(alpha: 0.28);
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.36),
      size.width * 0.18,
      paint,
    );
    paint.color = const Color(0xFFEEF4FB).withValues(alpha: 0.55);
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.28),
      size.width * 0.16,
      paint,
    );

    paint.color = const Color(0xFFCED9E8).withValues(alpha: 0.22);
    for (var i = 0; i < 4; i++) {
      final left = size.width * (0.38 + i * 0.13);
      final top = size.height * (0.08 + i * 0.035);
      final rect = Rect.fromLTWH(left, top, 190, 56);
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(-0.62);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: rect.width,
            height: rect.height,
          ),
          const Radius.circular(8),
        ),
        paint,
      );
      canvas.restore();
    }

    paint.color = const Color(0xFFB9C5D6).withValues(alpha: 0.24);
    final buildingTop = size.height * 0.48;
    final building = Path()
      ..moveTo(size.width * 0.48, size.height)
      ..lineTo(size.width * 0.48, buildingTop)
      ..lineTo(size.width * 0.66, buildingTop - 38)
      ..lineTo(size.width * 0.66, buildingTop + 44)
      ..lineTo(size.width * 0.95, buildingTop - 28)
      ..lineTo(size.width, buildingTop)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(building, paint);

    paint.color = const Color(0xFF8290A4).withValues(alpha: 0.18);
    for (var i = 0; i < 12; i++) {
      final x = size.width * 0.54 + i * 44;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, buildingTop + 42 + (i % 2) * 14, 24, 64),
          const Radius.circular(4),
        ),
        paint,
      );
    }

    paint.color = const Color(0xFF6B8B6B).withValues(alpha: 0.18);
    for (final center in [
      Offset(size.width * 0.62, size.height * 0.45),
      Offset(size.width * 0.72, size.height * 0.34),
      Offset(size.width * 0.11, size.height * 0.74),
    ]) {
      canvas.drawRect(
        Rect.fromLTWH(center.dx - 2, center.dy, 4, size.height * 0.2),
        paint,
      );
      for (var i = 0; i < 12; i++) {
        final angle = (math.pi * 2 / 12) * i;
        final end = Offset(
          center.dx + math.cos(angle) * 72,
          center.dy + math.sin(angle) * 36,
        );
        canvas.drawLine(center, end, paint..strokeWidth = 5);
      }
    }

    paint
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawRect(Offset.zero & size, paint);

    final blueWave = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.18, 0)
      ..cubicTo(size.width * 0.13, size.height * 0.12, size.width * 0.04,
          size.height * 0.16, size.width * 0.08, size.height * 0.32)
      ..cubicTo(size.width * 0.12, size.height * 0.48, 0, size.height * 0.52, 0,
          size.height * 0.68)
      ..close();
    paint.color = _mockupDeepBlue;
    canvas.drawPath(blueWave, paint);

    final redWave = Path()
      ..moveTo(size.width * 0.18, 0)
      ..cubicTo(size.width * 0.15, size.height * 0.08, size.width * 0.13,
          size.height * 0.16, size.width * 0.08, size.height * 0.25)
      ..cubicTo(size.width * 0.03, size.height * 0.34, size.width * 0.02,
          size.height * 0.43, 0, size.height * 0.51)
      ..lineTo(0, size.height * 0.44)
      ..cubicTo(size.width * 0.07, size.height * 0.31, size.width * 0.11,
          size.height * 0.23, size.width * 0.13, size.height * 0.12)
      ..cubicTo(size.width * 0.14, size.height * 0.07, size.width * 0.16,
          size.height * 0.03, size.width * 0.18, 0)
      ..close();
    paint.color = _mockupRed;
    canvas.drawPath(redWave, paint);

    final topRightLight = Path()
      ..moveTo(size.width * 0.78, 0)
      ..cubicTo(size.width * 0.86, size.height * 0.05, size.width * 0.91,
          size.height * 0.08, size.width, size.height * 0.04)
      ..lineTo(size.width, 0)
      ..close();
    paint.color = const Color(0xFFBFD5F2).withValues(alpha: 0.42);
    canvas.drawPath(topRightLight, paint);

    final topRightMid = Path()
      ..moveTo(size.width * 0.84, 0)
      ..cubicTo(size.width * 0.90, size.height * 0.06, size.width * 0.94,
          size.height * 0.10, size.width, size.height * 0.08)
      ..lineTo(size.width, 0)
      ..close();
    paint.color = const Color(0xFF2E5EA8).withValues(alpha: 0.18);
    canvas.drawPath(topRightMid, paint);

    final topRightDark = Path()
      ..moveTo(size.width * 0.91, 0)
      ..cubicTo(size.width * 0.95, size.height * 0.04, size.width * 0.97,
          size.height * 0.07, size.width, size.height * 0.06)
      ..lineTo(size.width, 0)
      ..close();
    paint.color = _mockupDeepBlue.withValues(alpha: 0.12);
    canvas.drawPath(topRightDark, paint);

    paint.color = Colors.white.withValues(alpha: 0.72);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UniversityHeader extends StatelessWidget {
  final bool compact;

  const _UniversityHeader({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        children: [
          const _UagroSeal(size: 72),
          const SizedBox(height: 12),
          _universityTexts(TextAlign.center),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _UagroSeal(size: 150),
        const SizedBox(width: 44),
        Expanded(child: _universityTexts(TextAlign.start)),
      ],
    );
  }

  Widget _universityTexts(TextAlign align) {
    return Column(
      crossAxisAlignment: align == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'UNIVERSIDAD AUTÓNOMA\nDE GUERRERO',
          textAlign: align,
          style: const TextStyle(
            color: _mockupDeepBlue,
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(width: 355, height: 2, color: _mockupGold),
        const SizedBox(height: 12),
        const Text(
          'Cuidamos la salud de nuestra comunidad universitaria',
          style: TextStyle(
            color: _mockupDeepBlue,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            height: 1.18,
          ),
        ),
      ],
    );
  }
}

class _UagroSeal extends StatelessWidget {
  final double size;

  const _UagroSeal({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _mockupBlue,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _mockupDeepBlue.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.account_balance, color: Colors.white, size: size * 0.48),
          Positioned(
            bottom: size * 0.18,
            child: Text(
              'UAGro',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportBlock extends StatelessWidget {
  const _SupportBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _mockupDeepBlue, width: 2),
          ),
          child:
              const Icon(Icons.question_mark, color: _mockupDeepBlue, size: 22),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soporte técnico',
              style: TextStyle(
                color: _mockupDeepBlue,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'innovasalud@uagro.mx',
              style: TextStyle(color: _mockupDeepBlue, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroBrand extends StatelessWidget {
  final bool compact;

  const _HeroBrand({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              compact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Container(
              width: compact ? 76 : 132,
              height: compact ? 76 : 132,
              decoration: BoxDecoration(
                color: _mockupBlue,
                borderRadius: BorderRadius.circular(compact ? 18 : 24),
                boxShadow: [
                  BoxShadow(
                    color: _mockupBlue.withValues(alpha: 0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                Icons.health_and_safety_outlined,
                color: Colors.white,
                size: compact ? 48 : 80,
              ),
            ),
            SizedBox(width: compact ? 18 : 38),
            Text(
              'SASU',
              style: TextStyle(
                color: _mockupBlue,
                fontSize: compact ? 58 : 96,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Sistema de Atención en\nSalud Universitaria',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: _mockupDeepBlue,
            fontSize: compact ? 22 : 30,
            height: 1.14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 26),
        Container(width: 66, height: 4, color: _mockupRed),
        const SizedBox(height: 26),
        Text(
          'Dirección de Innovación en la\nGestión de la Salud Universitaria',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: _mockupDeepBlue,
            fontSize: compact ? 17 : 22,
            height: 1.18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FeatureFooter extends StatelessWidget {
  final bool compact;

  const _FeatureFooter({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _FeatureItem(
        icon: Icons.groups,
        color: _mockupBlue,
        title: 'Integral',
        text: 'Gestión completa de\nexpedientes y servicios',
      ),
      const _FeatureItem(
        icon: Icons.monitor_heart,
        color: _mockupRed,
        title: 'Eficiente',
        text: 'Procesos ágiles para\nmejor atención',
      ),
      const _FeatureItem(
        icon: Icons.health_and_safety,
        color: _mockupGold,
        title: 'Confiable',
        text: 'Información segura\ny protegida',
      ),
      const _FeatureItem(
        icon: Icons.show_chart,
        color: _mockupBlue,
        title: 'Inteligente',
        text: 'Datos que generan\nmejores decisiones',
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 22,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _mockupDeepBlue.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: compact
          ? Wrap(spacing: 10, runSpacing: 10, children: items)
          : Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Expanded(child: items[i]),
                  if (i < items.length - 1)
                    Container(
                      width: 1,
                      height: 48,
                      color: _mockupDeepBlue.withValues(alpha: 0.13),
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                ],
              ],
            ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 25),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _mockupDeepBlue,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              text,
              style: const TextStyle(
                color: _mockupDeepBlue,
                fontSize: 10.5,
                height: 1.18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusFooter extends StatelessWidget {
  final String version;

  const _StatusFooter({required this.version});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final legal = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '© 2026 Universidad Autónoma de Guerrero',
              style: TextStyle(color: _mockupDeepBlue, fontSize: 12),
            ),
            SizedBox(width: 24),
            SizedBox(height: 20, child: VerticalDivider()),
            SizedBox(width: 24),
            Text(
              'Todos los derechos reservados',
              style: TextStyle(color: _mockupDeepBlue, fontSize: 12),
            ),
          ],
        );
        final status = Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _mockupDeepBlue.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: _mockupDeepBlue.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Wrap(
            spacing: 18,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_outlined,
                      color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Sistema en línea',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 22,
                color: _mockupDeepBlue.withValues(alpha: 0.22),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, color: _mockupDeepBlue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Última actualización: 08/06/2026',
                    style: TextStyle(color: _mockupDeepBlue, fontSize: 12),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 22,
                color: _mockupDeepBlue.withValues(alpha: 0.22),
              ),
              Text(
                'v$version',
                style: const TextStyle(
                  color: _mockupDeepBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );

        if (compact) {
          return Column(
            children: [
              status,
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: legal,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: legal),
            status,
          ],
        );
      },
    );
  }
}
