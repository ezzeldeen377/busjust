import 'package:bus_just/router/routes.dart';
import 'package:bus_just/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:bus_just/services/auth_service.dart';

class LoginScreen extends StatefulWidget {

  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();  // Add form key
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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
            child: Form(  // Wrap with Form widget
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    Image.asset(
                      'assets/images/logobus.png',
                      height: 120,
                      width: 120,
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),
              const Text(
                'Email Address',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: emailController,
                icon: Icons.email,
                hint: 'Enter your email',
                obscureText: false,
                color: Colors.blueAccent,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: passwordController,
                icon: Icons.lock,
                hint: 'Enter your password',
                obscureText: true,
                color: Colors.blueAccent,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // زر تسجيل الدخول
              _buildLoginButton(),

              const SizedBox(height: 10),

              _buildForgotPasswordButton(),

              const SizedBox(height: 10),

              // Don't have an account link
              // TextButton(
              //   onPressed: () {
              //     Navigator.pushNamed(context, Routes.control);
              //   },
              //   child: const Text(
              //     "Don't have an account? Create one",
              //     style: TextStyle(
              //       color: Colors.white,
              //       fontSize: 16,
              //       fontWeight: FontWeight.bold
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
        )) ) );
  }

  // بناء حقل النصوص (البريد وكلمة السر)
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool obscureText,
    required Color color,
    String? Function(String?)? validator,  // Add validator parameter
  }) {
    return TextFormField(  // Change TextField to TextFormField
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        labelStyle: TextStyle(color: color.withOpacity(0.8)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: color, size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
      ),
    );
  }

  // بناء زر تسجيل الدخول
  Widget _buildLoginButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
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
                    'Log In',
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

  // بناء زر "هل نسيت كلمة السر؟"
  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: isLoading ? null : _handleForgotPassword,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: const Text(
        'Forgot Password?',
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

  void _handleLogin() async {
    if (!mounted) return;
    
    if (!_formKey.currentState!.validate()) {  // Add form validation
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userCredential = await AuthService.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      
      if (userCredential?.user != null) {
        final userData = await FirestoreService.instance.getUserData(userCredential!.user!.uid);
        
        if (!mounted) return;
        if (userData != null) {
          Navigator.pushReplacementNamed(context, Routes.home, arguments: userData); // Pass UserModel to home screen
        } else {
          setState(() {
            errorMessage = 'Failed to fetch user data';
          });
        }
      }}
     catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()),backgroundColor: Colors.redAccent,),
        
      );
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleForgotPassword() async {
    if (!mounted) return;
    if (emailController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email address';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await AuthService.instance.resetPassword(emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent. Please check your inbox.'),backgroundColor: Colors.green,),
      );
    } catch (e) {
      if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()),backgroundColor: Colors.redAccent,),
        
      );
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
