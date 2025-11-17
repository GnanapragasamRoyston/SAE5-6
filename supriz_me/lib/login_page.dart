import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  bool isHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF6F91), // rose
              Color(0xFF845EC2), // violet
              Color(0xFF2196F3), // bleu
              Color(0xFF00C9A7), // turquoise
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  // Titre
                  Text(
                    "Surpriz'Me",
                    style: GoogleFonts.bebasNeue(
                      fontSize: 58,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Connectez-vous pour continuer",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Champ Email
                  _buildTextField(
                    controller: emailCtrl,
                    label: "Email",
                    icon: Icons.email,
                    isPassword: false,
                  ),

                  const SizedBox(height: 20),

                  // Champ Mot de passe
                  _buildTextField(
                    controller: passwordCtrl,
                    label: "Mot de passe",
                    icon: Icons.lock,
                    isPassword: true,
                    obscure: isHidden,
                    toggleVisibility: () {
                      setState(() => isHidden = !isHidden);
                    },
                  ),

                  const SizedBox(height: 40),

                  // Bouton de connexion
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // Logique de connexion à mettre ici
                      },
                      child: Text(
                        "SE CONNECTER",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lien inscription
                  GestureDetector(
                    onTap: () {
                      // Navigation vers la page d'inscription plus tard
                    },
                    child: Text(
                      "Pas encore de compte ? Inscrivez-vous",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget champ de texte réutilisable
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isPassword,
    bool obscure = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.25),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          onPressed: toggleVisibility,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
