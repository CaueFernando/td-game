import 'package:flutter/material.dart';
import 'dart:math' as math;

class PresentationScreen extends StatefulWidget {
  const PresentationScreen({super.key});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    // Efeito de flutuação suave do avatar
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF020617), // Azul profundo escuro
              Color(0xFF0F172A),
              Color(0xFF1E1B4B), // Roxo/azul escuro cósmico
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Flex(
                      direction: isLandscape ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Coluna da Esquerda / Superior (Logotipo e Slogan)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Coroa dourada
                            const Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 40),
                            const SizedBox(height: 4),
                            // Título "CLOROQUINILDO" com efeito neon
                            Text(
                              'CLOROQUINILDO',
                              style: TextStyle(
                                fontSize: isLandscape ? 36 : 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.greenAccent.shade400,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(color: Colors.greenAccent.shade700, blurRadius: 15),
                                  const Shadow(color: Colors.black, offset: Offset(2, 2)),
                                ],
                              ),
                            ),
                            // Subtítulo "TOWER DEFENSE"
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                              ),
                              child: const Text(
                                'TOWER DEFENSE',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 4.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Frase de impacto inferior
                            Text(
                              'DEFENDA. RESISTA. SOBREVIVA.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.cyanAccent.withOpacity(0.7),
                                letterSpacing: 3.0,
                              ),
                            ),
                          ],
                        ),

                        // Coluna do Meio (Avatar Flutuante)
                        AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, math.sin(_floatController.value * 2 * math.pi) * 10),
                              child: child,
                            );
                          },
                          child: Container(
                            height: isLandscape ? 180 : 200,
                            width: isLandscape ? 180 : 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: Image.asset(
                                'assets/images/cloroquinildo_avatar.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback se a imagem falhar
                                  return Container(
                                    color: Colors.green.shade800,
                                    child: const Icon(Icons.person_rounded, size: 80, color: Colors.white),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        // Coluna da Direita / Inferior (Botões de Ação)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botão Principal JOGAR
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: Container(
                                width: 220,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.amberAccent, Colors.orangeAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.black, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amberAccent.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chevron_left_rounded, color: Colors.black, size: 22),
                                      Text(
                                        ' JOGAR ',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, color: Colors.black, size: 22),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Botões secundários: Login Google & Configurações
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Login
                                _buildGlassButton(
                                  icon: Icons.login_rounded,
                                  label: 'LOGIN',
                                  onTap: () => Navigator.pushNamed(context, '/login'),
                                ),
                                const SizedBox(width: 12),
                                // Config
                                _buildGlassButton(
                                  icon: Icons.settings_rounded,
                                  label: 'CONFIGS',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Configurações em breve! Taokey?'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
