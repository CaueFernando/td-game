import 'package:flutter/material.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  bool _isWorld1Expanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF020617),
              Color(0xFF0F172A),
              Color(0xFF022329), // Detalhe azul petróleo neon
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Barra Superior de Recursos
              _buildTopBar(),
              const SizedBox(height: 8),

              // Título "SELECIONAR FASE"
              const Text(
                'SELECIONAR FASE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(color: Colors.cyanAccent, blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 2. Lista de Mundos / Fases (Scrollable)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Mundo 1 - Praça dos Três Podres (Aberto)
                    _buildWorld1Accordion(),
                    const SizedBox(height: 10),

                    // Mundo 2 - Deserto Radioativo (Bloqueado)
                    _buildLockedWorld('2. DESERTO RADIOATIVO'),
                    const SizedBox(height: 10),

                    // Mundo 3 - Base Alienígena (Bloqueado)
                    _buildLockedWorld('3. BASE ALIENÍGENA'),
                    const SizedBox(height: 10),

                    // Mundo 4 - Núcleo Inimigo (Bloqueado)
                    _buildLockedWorld('4. NÚCLEO INIMIGO'),
                    const SizedBox(height: 10),

                    // Mundo 5 - Invasão Final (Bloqueado)
                    _buildLockedWorld('5. INVASÃO FINAL'),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // 3. Menu de Navegação Inferior
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Energia
          Row(
            children: [
              _buildResourceBadge(
                icon: Icons.bolt,
                iconColor: Colors.amberAccent,
                text: '13/15',
                subtext: '05:32',
              ),
            ],
          ),
          
          // Pixcoins & Cristais
          Row(
            children: [
              _buildResourceBadge(
                icon: Icons.monetization_on,
                iconColor: Colors.amberAccent,
                text: '26,100',
                hasPlus: true,
              ),
              const SizedBox(width: 8),
              _buildResourceBadge(
                icon: Icons.diamond,
                iconColor: Colors.pinkAccent,
                text: '265',
                hasPlus: true,
              ),
            ],
          ),

          // Configurações
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configurações em breve!')),
              );
            },
            icon: const Icon(Icons.settings_rounded, color: Colors.cyanAccent),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.06),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceBadge({
    required IconData icon,
    required Color iconColor,
    required String text,
    String? subtext,
    bool hasPlus = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtext != null)
                Text(
                  subtext,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                  ),
                ),
            ],
          ),
          if (hasPlus) ...[
            const SizedBox(width: 6),
            Icon(Icons.add_circle, color: Colors.cyanAccent.withOpacity(0.8), size: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildWorld1Accordion() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF083344).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Cabeçalho do Mundo 1
          ListTile(
            onTap: () {
              setState(() {
                _isWorld1Expanded = !_isWorld1Expanded;
              });
            },
            leading: const Icon(Icons.public, color: Colors.greenAccent),
            title: const Text(
              '1. PRAÇA DOS TRÊS PODRES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            trailing: Icon(
              _isWorld1Expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.cyanAccent,
            ),
          ),

          // Se expandido, mostra a grade
          if (_isWorld1Expanded)
            Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  _buildLevelNode(1, stars: 3, isUnlocked: true),
                  _buildLevelNode(2, stars: 3, isUnlocked: false),
                  _buildLevelNode(3, stars: 3, isUnlocked: false),
                  _buildLevelNode(4, stars: 2, isUnlocked: false),
                  _buildLevelNode(5, stars: 1, isUnlocked: false),
                  _buildLevelNode(6, stars: 0, isUnlocked: false),
                  _buildLevelNode(7, stars: 0, isUnlocked: false),
                  _buildLevelNode(8, stars: 0, isUnlocked: false),
                  _buildLevelNode(9, stars: 0, isUnlocked: false),
                  _buildBossNode(10),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLevelNode(int num, {required int stars, required bool isUnlocked}) {
    // Para simplificar, o Level 1 é o único jogável que abre a partida
    final playable = num == 1;

    return InkWell(
      onTap: playable
          ? () {
              Navigator.pushNamed(context, '/game_play');
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nível $num ainda bloqueado no MVP!'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: playable
                  ? Colors.cyan.shade800.withOpacity(0.3)
                  : Colors.grey.shade900.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: playable ? Colors.cyanAccent : Colors.white10,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$num',
              style: TextStyle(
                color: playable ? Colors.white : Colors.white24,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Estrelas
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Icon(
                Icons.star,
                size: 10,
                color: index < stars
                    ? Colors.amber
                    : (playable ? Colors.white12 : Colors.transparent),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBossNode(int num) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.red.shade900.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.gavel_rounded, color: Colors.redAccent, size: 20),
        ),
        const SizedBox(height: 4),
        const Text(
          'BOSS',
          style: TextStyle(
            color: Colors.redAccent,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLockedWorld(String name) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: const Icon(Icons.public_off, color: Colors.white30),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.white30,
            letterSpacing: 0.8,
          ),
        ),
        trailing: const Icon(Icons.lock_outline, color: Colors.white30),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Colors.cyanAccent.withOpacity(0.12))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.shopping_cart_outlined, 'LOJA', false),
          _buildNavItem(Icons.shield_outlined, 'TORRES', false),
          _buildNavItem(Icons.home_filled, 'INÍCIO', true),
          _buildNavItem(Icons.calendar_month_outlined, 'EVENTOS', false),
          _buildNavItem(Icons.person_outline, 'PERFIL', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aba "$label" em breve!'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.cyanAccent : Colors.white38,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isSelected ? Colors.cyanAccent : Colors.white38,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
