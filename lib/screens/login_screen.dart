import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _handleGoogleLogin() {
    setState(() {
      _isLoading = true;
    });

    // Simula a autenticação por 1.5 segundos
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pushNamedAndRemoveUntil(context, '/level_select', (route) => false);
      }
    });
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
              Color(0xFF020617),
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo compacta no topo
                    const Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 24),
                    Text(
                      'CLOROQUINILDO',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.greenAccent.shade400,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Text(
                      'TOWER DEFENSE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white60,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card de Login
                    Container(
                      width: 380,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'FAZER LOGIN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Salve seu progresso na nuvem e jogue em qualquer dispositivo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Botão Continuar com Google ou Loader
                          _isLoading
                              ? const CircularProgressIndicator(color: Colors.cyanAccent)
                              : GestureDetector(
                                  onTap: _handleGoogleLogin,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Logo G simulada
                                        Container(
                                          width: 18,
                                          height: 18,
                                          margin: const EdgeInsets.only(right: 10),
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: Colors.transparent,
                                          ),
                                          child: const Icon(
                                            Icons.g_mobiledata_rounded,
                                            color: Colors.blueAccent,
                                            size: 26,
                                          ),
                                        ),
                                        const Text(
                                          'Continuar com Google',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white12)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('ou', style: TextStyle(color: Colors.white30, fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: Colors.white12)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Vantagens de login
                          _buildBenefitRow(
                            icon: Icons.cloud_done_outlined,
                            text: 'Salve seu progresso na nuvem e jogue em qualquer dispositivo.',
                          ),
                          const SizedBox(height: 12),
                          _buildBenefitRow(
                            icon: Icons.verified_user_outlined,
                            text: 'Participe de eventos, rankings e ganhe recompensas exclusivas.',
                          ),

                          const SizedBox(height: 24),
                          // Botão Jogar Offline / Sem Login
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(context, '/level_select', (route) => false);
                            },
                            child: Text(
                              'Jogar sem fazer Login',
                              style: TextStyle(
                                color: Colors.cyanAccent.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Termos de Uso
                    Text(
                      'Ao continuar, você concorda com nossos\nTermos de Uso e Política de Privacidade.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
