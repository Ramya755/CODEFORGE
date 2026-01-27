import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flowmatefirebase/screens/login_screens/widgets/animated_background.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  late AnimationController _controller;

  String username = "";
  String email = "";
  String password = "";
  int totalCompletedLevels = 0;
  int totalLevels = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fetchUserData();
    _fetchProgressData();
  }

  void _fetchUserData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _dbRef.child("users/${user.uid}").get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          username = data['username']?.toString() ?? '';
          email = data['email']?.toString() ?? '';
        });
      }
    }
  }

  Map<String, Map<String, int>> languageProgress = {};
  // { "JAVA": {"completed": 4, "total": 10}, ... }

  void _fetchProgressData() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _dbRef.child("users/${user.uid}/concepts").get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        Map<String, Map<String, int>> temp = {};
        int globalCompleted = 0;
        int globalTotal = 0;

        data.forEach((language, topics) {
          int completed = 0;
          int total = 0;

          (topics as Map).forEach((topic, levels) {
            (levels as Map).forEach((level, levelData) {
              if (levelData['isCompleted'] == true) completed++;
              total++;
            });
          });

          temp[language] = {"completed": completed, "total": total};

          globalCompleted += completed;
          globalTotal += total;
        });

        setState(() {
          languageProgress = temp;
          totalCompletedLevels = globalCompleted;
          totalLevels = globalTotal;
        });
      }
    }
  }

 Future<void> _editProfile() async {
  final User? user = _auth.currentUser;
  if (user == null) return;

  final TextEditingController usernameController =
      TextEditingController(text: username);
  final TextEditingController emailController =
      TextEditingController(text: email);
  final TextEditingController passwordController = TextEditingController();

  await showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "New Password"),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                // Update Realtime Database username
                await _dbRef.child("users/${user.uid}").update({
                  "username": usernameController.text,
                  "email": emailController.text, // optional if you store email
                });

                // Update Firebase Auth email if changed
                if (emailController.text != email) {
                  await user.updateEmail(emailController.text);
                }

                // Update Firebase Auth password if entered
                if (passwordController.text.isNotEmpty) {
                  await user.updatePassword(passwordController.text);
                }

                // Update local state
                setState(() {
                  username = usernameController.text;
                  email = emailController.text;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Profile updated successfully."),
                    backgroundColor: Colors.green,
                  ),
                );

                Navigator.pop(context);
              } on FirebaseAuthException catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.message ?? "Update failed"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("Save"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      );
    },
  );
}

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      setState(() {
        username = '';
        email = '';
        password = '';
      });
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    TextEditingController pwd = TextEditingController();

    // Ask password again
    final entered = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Password"),
            content: TextField(
              controller: pwd,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Enter your password",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
    );

    if (entered != true) return;

    try {
      // Reauthenticate using password entered right now
      final credential = EmailAuthProvider.credential(
        email: email,
        password: pwd.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // Delete user data
      await _dbRef.child("users/${user.uid}").remove();
      await _dbRef.child("user_map/${user.uid}").remove();

      // Delete auth account
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account deleted successfully."),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Authentication error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// ---------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildCurvedAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: const AssetImage(
                              "assets/prof.png",
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildProfileItem("Username", username),
                        _buildProfileItem("Email", email),
                        const SizedBox(height: 20),
                        _buildProgressSummary(),
                        const SizedBox(height: 30),
                        _buildLanguageProgress(),
                        const SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildAnimatedBorderButton(
                              Icons.edit,
                              "Edit Profile",
                              _editProfile,
                            ),
                            _buildAnimatedBorderButton(
                              Icons.logout,
                              "Logout",
                              _logout,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: _buildAnimatedBorderButton(
                            Icons.delete,
                            "Delete Account",
                            _deleteAccount,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    double progress = totalLevels > 0 ? totalCompletedLevels / totalLevels : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Progress Summary",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Completed Levels",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      "$totalCompletedLevels / $totalLevels",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.greenAccent,
                  ),
                  minHeight: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Language Progress",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          ...languageProgress.entries.map((entry) {
            String lang = entry.key;
            int completed = entry.value["completed"]!;
            int total = entry.value["total"]!;
            double progress = total > 0 ? completed / total : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$lang   •   $completed / $total",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[800],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.greenAccent,
                      ),
                      minHeight: 10,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCurvedAppBar() {
    return ClipPath(
      clipper: CurveClipper(),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [Color(0xFF8A2BE2), Color(0xFF0a0a14)],
          ),
        ),
        child: Center(
          child: Text(
            "Profile",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey),
            ),
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBorderButton(
    IconData icon,
    String text,
    VoidCallback onPressed,
  ) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double borderWidth = 2 + sin(_controller.value * 2 * pi) * 2;

        return GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8A2BE2), Color(0xFF00BFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
