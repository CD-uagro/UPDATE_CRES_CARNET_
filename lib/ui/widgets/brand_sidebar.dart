import 'package:flutter/material.dart';
import '../brand.dart';

/// Barra lateral de marca institucional UAGro
/// Diseño vertical con logo y separadores visuales
class BrandSidebar extends StatelessWidget {
  const BrandSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104, // Ancho fijo entre 96-112px según especificación
      decoration: const BoxDecoration(
        color: UAGroColors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Espaciado superior
          const SizedBox(height: 24),

          // Logo institucional UAGro
          maybeUAGroLogo(size: 56),

          const SizedBox(height: 16),

          // Texto institucional
          const Text(
            'UAGro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Medicina',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 24),

          // Separador decorativo
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: UAGroColors.gold,
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          const SizedBox(height: 24),

          // Indicadores visuales (decorativos)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIndicator(Colors.white60, 8),
                const SizedBox(height: 12),
                _buildIndicator(UAGroColors.gold, 6),
                const SizedBox(height: 12),
                _buildIndicator(Colors.white30, 4),
              ],
            ),
          ),

          // Espaciado inferior
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Construye un indicador visual decorativo
  Widget _buildIndicator(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Barra lateral variante con color rojo institucional
/// Para usar en pantallas de alerta o estados especiales
class BrandSidebarRed extends StatelessWidget {
  const BrandSidebarRed({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      decoration: const BoxDecoration(
        color: UAGroColors.red,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Logo con fondo blanco para contraste
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: maybeUAGroLogo(size: 40),
          ),

          const SizedBox(height: 16),

          const Text(
            'UAGro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Medicina',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.8,
            ),
          ),

          const Spacer(),

          // Indicador de alerta
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high,
              color: Colors.white,
              size: 18,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
