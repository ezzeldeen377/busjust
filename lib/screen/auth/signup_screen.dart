import 'package:bus_just/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:bus_just/services/auth_service.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:bus_just/models/user.dart';

class SignUpScreen extends StatefulWidget {
  final UserRole userType;

  const SignUpScreen({super.key, required this.userType});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1877F2), Color(0xFF0099FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 50),
                  Image.asset(
                    'assets/images/logobus.png',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sign up as ${widget.userType.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 40),
              _buildTextField(
                controller: usernameController,
                icon: Icons.person,
                label: 'Username',
                hint: 'Enter your username',
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: emailController,
                icon: Icons.email,
                label: 'Email',
                hint: 'Enter your email',
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: passwordController,
                icon: Icons.lock,
                label: 'Password',
                hint: 'Enter your password',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: confirmPasswordController,
                icon: Icons.lock_outline,
                label: 'Confirm Password',
                hint: 'Confirm your password',
                obscureText: true,
              ),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red[100], fontSize: 14),
                  ),
                ),
              const SizedBox(height: 30),
              _buildSignUpButton(),
              const SizedBox(height: 20),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
     ) ) );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    bool obscureText = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          labelText: label,
          labelStyle: TextStyle(color: Colors.blue[700]?.withOpacity(0.8)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.blue[700], size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1877F2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: const Text(
        'Already have an account? Login',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white70,
        ),
      ),
    );
  }

  void _handleSignUp() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Basic validation
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields';
        isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        errorMessage = 'Passwords do not match';
        isLoading = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = 'Password must be at least 6 characters long';
        isLoading = false;
      });
      return;
    }

    try {
      final userCredential = await AuthService.instance.signUpWithEmailAndPassword(
        email: email,
        password: password,
        userType: widget.userType.name,
      );

      if (userCredential?.user != null) {
        final user = UserModel(
          id: userCredential!.user!.uid,
          fullName: username,
          email: email,
          role: widget.userType 
        );

        await FirestoreService.instance.saveUserData(user);
      }

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Registration successful!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context,Routes.login);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        setState(() {
          isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override 
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
