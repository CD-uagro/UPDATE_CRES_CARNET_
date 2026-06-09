import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_service.dart';
import '../ui/brand.dart' as brand;
import '../ui/widgets/promocion_salud_section.dart';
import 'dashboard_screen.dart';
import 'form_screen.dart';
import 'nueva_nota_screen.dart';
import 'vaccination_screen.dart';

/// Pantalla independiente para gestión de Promoción de Salud.
/// Rediseño visual SASU 2.5; conserva el formulario y envío existentes.
class PromocionSaludScreen extends StatefulWidget {
  final dynamic db;
  const PromocionSaludScreen({super.key, this.db});

  @override
  State<PromocionSaludScreen> createState() => _PromocionSaludScreenState();
}

class _PromocionSaludScreenState extends State<PromocionSaludScreen> {
  static const String _observatoryUrl = String.fromEnvironment(
    'SASU_OBSERVATORIO_URL',
    defaultValue: '',
  );

  bool _loadingCampaigns = true;
  List<Map<String, dynamic>> _promociones = [];

  @override
  void initState() {
    super.initState();
    _loadPromociones();
  }

  Future<void> _loadPromociones() async {
    final list = await ApiService.getPromocionesSalud();
    if (!mounted) return;
    setState(() {
      _promociones = list;
      _loadingCampaigns = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brand.UAGroColors.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          return Row(
            children: [
              if (desktop) _buildSidebar(),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _InstitutionalWaves(
                        width: desktop ? 430 : constraints.maxWidth * .68,
                      ),
                    ),
                    SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          desktop ? 24 : 16,
                          24,
                          desktop ? 28 : 16,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!desktop) ...[
                              _buildMobileTopBar(),
                              const SizedBox(height: 18),
                            ],
                            _buildHeader(desktop),
                            const SizedBox(height: 24),
                            _buildKpiStrip(),
                            const SizedBox(height: 16),
                            _buildCategoryChips(),
                            const SizedBox(height: 16),
                            if (desktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 11,
                                    child: _buildCampaignsPanel(),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    flex: 9,
                                    child: PromocionSaludSection(),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildCampaignsPanel(),
                                  const SizedBox(height: 16),
                                  const PromocionSaludSection(),
                                ],
                              ),
                            const SizedBox(height: 16),
                            _buildBottomPanels(desktop),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 14),
      child: Row(
        children: [
          brand.maybeUAGroLogo(size: 40),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'SASU - Promoción de Salud',
              style: TextStyle(
                color: brand.UAGroColors.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final items = [
      (Icons.home_outlined, 'Inicio', false),
      (Icons.folder_shared_outlined, 'Expedientes', false),
      (Icons.search_rounded, 'Buscar carnet / notas', false),
      (Icons.badge_outlined, 'Crear Carnet', false),
      (Icons.note_add_outlined, 'Nueva Nota', false),
      (Icons.campaign_outlined, 'Promoción de Salud', true),
      (Icons.vaccines_outlined, 'Vacunación', false),
      (Icons.assessment_outlined, 'Reportes', false),
      (Icons.monitor_heart_outlined, 'Observatorio SASU', false),
      (Icons.settings_outlined, 'Configuración', false),
    ];

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF061B45), Color(0xFF082F75)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  brand.maybeUAGroLogo(size: 44),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'UNIVERSIDAD AUTÓNOMA\nDE GUERRERO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SASU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Sistema de Atención\nen Salud Universitaria',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white12),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _sidebarItem(
                      icon: item.$1,
                      label: item.$2,
                      active: item.$3,
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sistema en línea',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 5,
                          backgroundColor: Color(0xFF1ED760),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Última sincronización:',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '07/06/2026 10:45 a. m.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    const Icon(
                      Icons.cloud_sync_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'v2.5.0',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF147B45) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: Colors.white.withValues(alpha: .18), width: 1)
            : null,
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: active ? 4 : 0,
            height: 42,
            decoration: const BoxDecoration(
              color: brand.UAGroColors.red,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(999),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: () => _handleSidebarTap(label),
                hoverColor: Colors.white.withValues(alpha: .08),
                splashColor: Colors.white.withValues(alpha: .10),
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(icon, color: Colors.white, size: 22),
                title: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSidebarTap(String label) {
    switch (label) {
      case 'Inicio':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardScreen(db: widget.db)),
        );
        return;
      case 'Expedientes':
      case 'Buscar carnet / notas':
      case 'Nueva Nota':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NuevaNotaScreen(db: widget.db)),
        );
        return;
      case 'Crear Carnet':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FormScreen(db: widget.db)),
        );
        return;
      case 'Promoción de Salud':
        return;
      case 'Vacunación':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VaccinationScreen()),
        );
        return;
      case 'Reportes':
      case 'Configuración':
        _showSnack('Módulo en desarrollo');
        return;
      case 'Observatorio SASU':
        _openObservatory();
        return;
    }
  }

  Future<void> _openObservatory() async {
    if (_observatoryUrl.trim().isEmpty) {
      _showSnack('Observatorio SASU pendiente de vinculación');
      return;
    }
    final uri = Uri.tryParse(_observatoryUrl);
    if (uri == null) {
      _showSnack('Observatorio SASU pendiente de vinculación');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showSnack('Observatorio SASU pendiente de vinculación');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildHeader(bool desktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Promoción de Salud',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: brand.UAGroColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Campañas universitarias, acciones preventivas y seguimiento comunitario',
                style: TextStyle(
                  color: Color(0xFF31415F),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (desktop) ...[
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            color: brand.UAGroColors.blue,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              'DR',
              style: TextStyle(
                color: brand.UAGroColors.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dr. Administrador',
                style: TextStyle(
                  color: brand.UAGroColors.blue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'CRES Llano Largo',
                style: TextStyle(color: brand.UAGroColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildKpiStrip() {
    final stats = _PromotionStats.from(_promociones);
    final kpis = [
      _KpiData(
        Icons.campaign_outlined,
        '${stats.active}',
        'Campañas activas',
        'En curso actualmente',
        const Color(0xFF1A9D4F),
      ),
      _KpiData(
        Icons.groups_2_outlined,
        NumberFormat.decimalPattern().format(stats.participants),
        'Participantes registrados',
        'Total registrado',
        const Color(0xFF0C62C9),
      ),
      _KpiData(
        Icons.account_balance_outlined,
        '${stats.schools}',
        'Facultades / escuelas',
        'Alcanzadas',
        const Color(0xFF7B2CBF),
      ),
      _KpiData(
        Icons.monitor_heart_outlined,
        '${stats.actions}',
        'Acciones realizadas',
        'Este semestre',
        const Color(0xFFE66A00),
      ),
      _KpiData(
        Icons.calendar_month_outlined,
        '${stats.upcoming}',
        'Próximas actividades',
        'Programadas',
        const Color(0xFF008197),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 1060
            ? (constraints.maxWidth - 64) / 5
            : constraints.maxWidth >= 660
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final kpi in kpis)
              SizedBox(
                width: itemWidth,
                child: _kpiCard(kpi),
              ),
          ],
        );
      },
    );
  }

  Widget _kpiCard(_KpiData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 12),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: brand.UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    color: brand.UAGroColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final chips = [
      (Icons.psychology_outlined, 'Salud mental', const Color(0xFF8E24AA)),
      (Icons.apple_outlined, 'Nutrición', const Color(0xFF1A9D4F)),
      (Icons.directions_run, 'Actividad física', const Color(0xFF0C62C9)),
      (Icons.favorite_outline, 'Salud sexual', const Color(0xFFE53058)),
      (
        Icons.shield_outlined,
        'Prevención de adicciones',
        const Color(0xFF7B2CBF)
      ),
      (Icons.bloodtype_outlined, 'Donación', const Color(0xFFD81B60)),
      (Icons.vaccines_outlined, 'Vacunación', const Color(0xFF008197)),
      (
        Icons.diversity_3_outlined,
        'Salud comunitaria',
        const Color(0xFFE66A00)
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(
              color: brand.UAGroColors.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
          for (final chip in chips)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFE1E6F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip.$1, color: chip.$3, size: 17),
                  const SizedBox(width: 8),
                  Text(
                    chip.$2,
                    style: const TextStyle(
                      color: brand.UAGroColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCampaignsPanel() {
    final campaigns = _promociones.map(_Campaign.from).toList();

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFF1A9D4F),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Campañas y acciones',
                  style: TextStyle(
                    color: brand.UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              SizedBox(
                width: 230,
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Buscar campaña...',
                    suffixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF7F9FF),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: const BorderSide(color: Color(0xFFD7DDEB)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                label: const Text('Todos los estados'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingCampaigns)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (campaigns.isEmpty)
            _emptyCampaignCard()
          else
            ListView.separated(
              itemCount: campaigns.length > 4 ? 4 : campaigns.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _campaignTile(campaigns[index]),
            ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pageButton(Icons.chevron_left, false),
              _pageNumber('1', true),
              _pageNumber('2', false),
              _pageNumber('3', false),
              _pageButton(Icons.chevron_right, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCampaignCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E6F0)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFE8F7EE),
            child: Icon(Icons.campaign_outlined, color: Color(0xFF1A9D4F)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'No hay campañas registradas todavía.',
              style: TextStyle(
                color: brand.UAGroColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignTile(_Campaign campaign) {
    final color = _categoryColor(campaign.category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(_categoryIcon(campaign.category), color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: brand.UAGroColors.blue,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  campaign.category,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  campaign.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4C5B74),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 168,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusPill(campaign.status),
                const SizedBox(height: 6),
                Text(
                  campaign.dateLabel,
                  style: const TextStyle(
                    color: brand.UAGroColors.blue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Responsable',
                  style: TextStyle(
                    color: brand.UAGroColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  campaign.responsible,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF31415F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _showSnack('Detalle de promoción pendiente.'),
            child: const Text('Ver detalle'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: brand.UAGroColors.blue),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'detail', child: Text('Ver detalle')),
            ],
            onSelected: (_) => _showSnack('Detalle de promoción pendiente.'),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final lower = status.toLowerCase();
    final color = lower.contains('program')
        ? const Color(0xFFE66A00)
        : lower.contains('final')
            ? const Color(0xFF68758E)
            : const Color(0xFF1A9D4F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _pageButton(IconData icon, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: IconButton.outlined(
        onPressed: null,
        icon: Icon(icon, size: 17),
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _pageNumber(String value, bool active) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? brand.UAGroColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFD7DDEB)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: active ? Colors.white : brand.UAGroColors.blue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBottomPanels(bool desktop) {
    final notes = _notesPanel();
    final activity = _activityPanel();
    if (!desktop) {
      return Column(
        children: [
          notes,
          const SizedBox(height: 14),
          activity,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: notes),
        const SizedBox(width: 16),
        Expanded(child: activity),
      ],
    );
  }

  Widget _notesPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 12).copyWith(
        border: Border.all(color: const Color(0xFFCFE0FF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF0C62C9), size: 20),
              SizedBox(width: 8),
              Text(
                'Notas importantes',
                style: TextStyle(
                  color: Color(0xFF0C62C9),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('• Los envíos a alumnos específicos no requieren autorización.'),
          SizedBox(height: 8),
          Text(
              '• Las promociones masivas requieren autorización del supervisor.'),
          SizedBox(height: 8),
          Text('• Revisa el calendario antes de programar nuevas actividades.'),
        ],
      ),
    );
  }

  Widget _activityPanel() {
    final rows = _promociones.take(3).map(_Campaign.from).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_available_outlined,
                  color: Color(0xFF1A9D4F), size: 20),
              SizedBox(width: 8),
              Text(
                'Actividad reciente',
                style: TextStyle(
                  color: Color(0xFF147B45),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const Text(
              'Sin actividad reciente registrada.',
              style: TextStyle(color: brand.UAGroColors.onSurfaceVariant),
            )
          else
            for (final row in rows) ...[
              Row(
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF147B45))),
                  Expanded(child: Text('${row.name} fue registrada')),
                  Text(
                    row.shortDate,
                    style: const TextStyle(
                      color: brand.UAGroColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE3E8F2)),
      boxShadow: [
        BoxShadow(
          color: brand.UAGroColors.blue.withValues(alpha: .06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Color _categoryColor(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('mental') || lower.contains('psico')) {
      return const Color(0xFF8E24AA);
    }
    if (lower.contains('nutric')) return const Color(0xFF1A9D4F);
    if (lower.contains('física') || lower.contains('fisica')) {
      return const Color(0xFF0C62C9);
    }
    if (lower.contains('don')) return const Color(0xFFD81B60);
    if (lower.contains('vacun')) return const Color(0xFF008197);
    return const Color(0xFF1A9D4F);
  }

  IconData _categoryIcon(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('mental') || lower.contains('psico')) {
      return Icons.psychology_outlined;
    }
    if (lower.contains('nutric')) return Icons.apple_outlined;
    if (lower.contains('física') || lower.contains('fisica')) {
      return Icons.directions_run;
    }
    if (lower.contains('don')) return Icons.bloodtype_outlined;
    if (lower.contains('vacun')) return Icons.vaccines_outlined;
    return Icons.volunteer_activism_outlined;
  }
}

class _Campaign {
  final String name;
  final String category;
  final String description;
  final String responsible;
  final String status;
  final String dateLabel;
  final String shortDate;

  const _Campaign({
    required this.name,
    required this.category,
    required this.description,
    required this.responsible,
    required this.status,
    required this.dateLabel,
    required this.shortDate,
  });

  factory _Campaign.from(Map<String, dynamic> data) {
    String text(String key, String fallback) {
      final value = data[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallback : value;
    }

    final category = text('categoria', 'Salud comunitaria');
    final program = text('programa', 'Programa universitario');
    final department = text('departamento', 'SASU');
    final link = text('link', 'Acción preventiva universitaria.');
    final created = DateTime.tryParse(
      (data['createdAt'] ?? data['fecha'] ?? data['timestamp'] ?? '')
          .toString(),
    );
    final date = created == null
        ? 'Sin fecha'
        : DateFormat('dd/MM/yyyy').format(created);
    final short =
        created == null ? 'Hoy' : DateFormat('dd/MM/yyyy').format(created);
    final rawStatus = text('estado', 'En curso');

    return _Campaign(
      name: text('nombre', '$category $program'),
      category: category,
      description: link,
      responsible: department,
      status: rawStatus,
      dateLabel: date,
      shortDate: short,
    );
  }
}

class _PromotionStats {
  final int active;
  final int participants;
  final int schools;
  final int actions;
  final int upcoming;

  const _PromotionStats({
    required this.active,
    required this.participants,
    required this.schools,
    required this.actions,
    required this.upcoming,
  });

  factory _PromotionStats.from(List<Map<String, dynamic>> promociones) {
    final uniqueSchools = promociones
        .map(
            (e) => (e['programa'] ?? e['departamento'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final participants = promociones
        .where((e) => (e['matricula'] ?? '').toString().trim().isNotEmpty)
        .length;
    final upcoming = promociones.where((e) {
      final status = (e['estado'] ?? '').toString().toLowerCase();
      return status.contains('program');
    }).length;

    return _PromotionStats(
      active: promociones.isEmpty ? 0 : promociones.length,
      participants: participants,
      schools: uniqueSchools.length,
      actions: promociones.length,
      upcoming: upcoming,
    );
  }
}

class _KpiData {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final Color color;

  const _KpiData(
    this.icon,
    this.value,
    this.title,
    this.subtitle,
    this.color,
  );
}

class _InstitutionalWaves extends StatelessWidget {
  final double width;

  const _InstitutionalWaves({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * .34,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: width,
              height: width * .30,
              decoration: BoxDecoration(
                color: brand.UAGroColors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(width * .42),
                ),
              ),
            ),
          ),
          Positioned(
            right: width * .05,
            top: width * .17,
            child: Container(
              width: width * .86,
              height: width * .07,
              decoration: BoxDecoration(
                color: brand.UAGroColors.red,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: width * .03,
            top: width * .04,
            child: Container(
              width: width * .68,
              height: width * .15,
              decoration: BoxDecoration(
                color: const Color(0xFF0B8FDB).withValues(alpha: .80),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(width * .32),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
