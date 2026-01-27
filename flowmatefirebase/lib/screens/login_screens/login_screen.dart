import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flowmatefirebase/screens/login_screens/forgot_password.dart';
import 'package:flowmatefirebase/screens/login_screens/sign_up.dart';
import 'package:flowmatefirebase/screens/login_screens/widgets/animated_background.dart';
import 'package:flowmatefirebase/screens/login_screens/widgets/auth_button.dart';
import 'package:flowmatefirebase/screens/login_screens/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    "users",
  );

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.clear();
    _passwordController.clear();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user == null) throw Exception("User not found");

      final snapshot = await _dbRef.child(user.uid).get();
      if (!snapshot.exists) throw Exception("User data missing in database");

      final value = snapshot.value;
      Map<String, dynamic> userData = {};

      if (value is Map) {
        userData = Map<String, dynamic>.from(value);
      } else {
        throw Exception("Unexpected user data format: ${value.runtimeType}");
      }

      final username = userData["username"] ?? "User";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, $username!'),
          backgroundColor: Colors.green,
        ),
      );

      _emailController.clear();
      _passwordController.clear();

      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => "No account found for this user.",
        'wrong-password' => "Incorrect password.",
        'invalid-email' => "Invalid email format.",
        _ => "Login failed. Try again.",
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildForm(),
                    const SizedBox(height: 20),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const Color primaryBlue = Color(0xFF00BFFF);
    const Color primaryPurple = Color(0xFF8A2BE2);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [primaryBlue, primaryPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.flash_on, color: Colors.white, size: 45),
            ),
            const SizedBox(height: 24),
            Text(
              'CODEFORGE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
                shadows: [
                  Shadow(blurRadius: 20.0, color: primaryBlue.withOpacity(0.7)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The Ultimate Educational Gaming Zone',
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email or username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                icon: Icons.lock_outline,
                isPassword: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              AuthButton(
                isLoading: _isLoading,
                text: 'LOGIN',
                onPressed: _login,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
            child: const Text('Forgot Password?'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }
}
