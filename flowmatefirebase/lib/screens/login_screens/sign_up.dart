import 'package:flowmatefirebase/models/levels_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_screen.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/auth_button.dart';
import 'widgets/animated_background.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'users',
  );

  ///  Sign Up Function
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final user = userCredential.user;

      if (user != null) {
        final userData = {
          'userId': user.uid,
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': DateTime.now().toIso8601String(),
        };

        await _dbRef.child(user.uid).set(userData);
        await _dbRef.child(user.uid).child('concepts').set({
          "C": ConceptsLevels.conceptsByLanguage["C"],
          "PYTHON": ConceptsLevels.conceptsByLanguage["PYTHON"],
          "JAVA": ConceptsLevels.conceptsByLanguage["JAVA"],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong";
      if (e.code == "email-already-in-use")
        message = "This email is already registered";
      else if (e.code == "weak-password")
        message = "Password must be at least 6 characters";
      else if (e.code == "invalid-email")
        message = "Invalid email format";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e, st) {
      print("Signup failed: $e\n$st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Join the CodeForge community!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    _buildSignUpForm(),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _usernameController,
            labelText: 'Username',
            icon: Icons.person_outline,
            validator:
                (value) => value!.isEmpty ? 'Please enter a username' : null,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
            icon: Icons.email_outlined,
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Please enter a valid email';
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
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            icon: Icons.lock_outline,
            isPassword: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed:
                  () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          AuthButton(
            isLoading: _isLoading,
            text: 'SIGN UP',
            onPressed: _signUp,
          ),
        ],
      ),
    );
  }
}
