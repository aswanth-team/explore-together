import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'admin/screens/admin_screen.dart';
import 'user/screens/profileScreen/settingScreen/help/help_screen.dart';
import 'user/screens/userLoginSetup/forget_password_screen.dart';
import 'user/screens/userLoginSetup/registration_screen.dart';
import 'user/screens/userManageScreens/temporarly_removed_screen.dart';
import 'user/screens/user_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordHidden = true;

  String? identifierError;
  String? passwordError;
  bool _isLoading = false;

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      prefixIcon: Icon(icon, color: Colors.white),
      fillColor: Colors.black.withOpacity(0.3),
      filled: true,
    );
  }

/*
  void loginHandle() async {
    setState(() {
      identifierError = null;
      passwordError = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('username', isEqualTo: identifier)
          .get();

      if (adminSnapshot.docs.isEmpty) {
        adminSnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('email', isEqualTo: identifier)
            .get();
      }

      if (adminSnapshot.docs.isEmpty) {
        adminSnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('phoneno', isEqualTo: identifier)
            .get();
      }

      if (adminSnapshot.docs.isEmpty) {
        adminSnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('aadharno', isEqualTo: identifier)
            .get();
      }

      if (adminSnapshot.docs.isNotEmpty) {
        final adminData =
            adminSnapshot.docs.first.data() as Map<String, dynamic>;
        final adminEmail = adminData['email'];
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: password,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminScreen()),
        );
        return;
      }
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('username', isEqualTo: identifier)
          .get();

      if (userSnapshot.docs.isEmpty) {
        userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .where('email', isEqualTo: identifier)
            .get();
      }

      if (userSnapshot.docs.isEmpty) {
        userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .where('phoneno', isEqualTo: identifier)
            .get();
      }

      if (userSnapshot.docs.isEmpty) {
        userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .where('aadharno', isEqualTo: identifier)
            .get();
      }

      if (userSnapshot.docs.isEmpty) {
        setState(() {
          identifierError = 'User not found. Please recheck or sign up.';
          _isLoading = false;
        });
        return;
      }
      final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
      final userEmail = userData['email'];
      final isRemoved = userData['isRemoved'] ?? false;

      if (isRemoved) {
        setState(() {
          identifierError = 'Your account has been temporarily removed.';
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showTemporaryRemovedPopup(context);
        });
        return;
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-credential') {
          passwordError = 'Incorrect password.';
        } else if (e.code == 'user-not-found') {
          identifierError = 'User not found. Please recheck or sign up.';
        } else {
          identifierError = 'Authentication failed: ${e.message}';
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        identifierError = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  } 
  
  
  
  
  
    void loginHandle() async {
    setState(() {
      identifierError = null;
      passwordError = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('username', isEqualTo: identifier)
          .get();

      if (adminSnapshot.docs.isEmpty) {
        adminSnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('email', isEqualTo: identifier)
            .get();
      }

      if (adminSnapshot.docs.isEmpty) {
        adminSnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('phoneno', isEqualTo: identifier)
            .get();
      }

      if (adminSnapshot.docs.isEmpty) {
        adminSnapshot = await FirebaseFirestore.instance
            .collection('admin')
            .where('aadharno', isEqualTo: identifier)
            .get();
      }

      if (adminSnapshot.docs.isNotEmpty) {
        final adminData =
            adminSnapshot.docs.first.data() as Map<String, dynamic>;
        final adminEmail = adminData['email'];
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: password,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminScreen()),
        );
        return;
      }
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('username', isEqualTo: identifier)
          .get();

      if (userSnapshot.docs.isEmpty) {
        userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .where('email', isEqualTo: identifier)
            .get();
      }

      if (userSnapshot.docs.isEmpty) {
        userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .where('phoneno', isEqualTo: identifier)
            .get();
      }

      if (userSnapshot.docs.isEmpty) {
        userSnapshot = await FirebaseFirestore.instance
            .collection('user')
            .where('aadharno', isEqualTo: identifier)
            .get();
      }

      if (userSnapshot.docs.isEmpty) {
        setState(() {
          identifierError = 'User not found. Please recheck or sign up.';
          _isLoading = false;
        });
        return;
      }
      final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
      final userEmail = userData['email'];
      final isRemoved = userData['isRemoved'] ?? false;

      if (isRemoved) {
        setState(() {
          identifierError = 'Your account has been temporarily removed.';
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showTemporaryRemovedPopup(context);
        });
        return;
      }

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail,
        password: password,
      );

      final userId = userCredential.user?.uid;
      if (userId != null) {
        final playerId = OneSignal.User.pushSubscription.id;
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .set({'onId': playerId}, SetOptions(merge: true));
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-credential') {
          passwordError = 'Incorrect password.';
        } else if (e.code == 'user-not-found') {
          identifierError = 'User not found. Please recheck or sign up.';
        } else {
          identifierError = 'Authentication failed: ${e.message}';
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        identifierError = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }*/

  void loginHandle() async {
    setState(() {
      identifierError = null;
      passwordError = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final identifier = identifierController.text.trim();
    final password = passwordController.text.trim();

    try {
      QuerySnapshot? userSnapshot;
      Map<String, dynamic>? userData;
      String? userEmail;
      bool isAdmin = false;

      for (final field in ['username', 'email', 'phoneno', 'aadharno']) {
        final adminQuery = await FirebaseFirestore.instance
            .collection('admin')
            .where(field, isEqualTo: identifier)
            .get();

        if (adminQuery.docs.isNotEmpty) {
          isAdmin = true;
          userSnapshot = adminQuery;
          break;
        }

        final userQuery = await FirebaseFirestore.instance
            .collection('user')
            .where(field, isEqualTo: identifier)
            .get();

        if (userQuery.docs.isNotEmpty) {
          userSnapshot = userQuery;
          break;
        }
      }

      if (userSnapshot == null || userSnapshot.docs.isEmpty) {
        setState(() {
          identifierError = 'User not found. Please recheck or sign up.';
          _isLoading = false;
        });
        return;
      }

      userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
      userEmail = userData['email'];

      if (!isAdmin && (userData['isRemoved'] ?? false)) {
        setState(() {
          identifierError = 'Your account has been temporarily removed.';
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showTemporaryRemovedPopup(context);
        });
        return;
      }

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: userEmail!,
        password: password,
      );

      // final userId = userCredential.user?.uid;
      //  if (userId != null) {
      //    final playerId = OneSignal.User.pushSubscription.id;
      //     await FirebaseFirestore.instance
      //          .collection('user')
      //          .doc(userId)
      //          .set({'onId': playerId}, SetOptions(merge: true));
      //    }

      final userId = userCredential.user?.uid;
      if (!isAdmin && userId != null) {
        final playerId = OneSignal.User.pushSubscription.id;

        // Get the document for the user
        final userDocRef =
            FirebaseFirestore.instance.collection('user').doc(userId);
        final userDocSnapshot = await userDocRef.get();

        // Check if the 'onId' field exists and if it's a list, otherwise initialize an empty list
        List<String> existingPlayerIds = [];
        if (userDocSnapshot.exists) {
          final userData = userDocSnapshot.data();
          existingPlayerIds = List<String>.from(userData?['onId'] ?? []);
        }

        // Add the new playerId to the list if it's not already present
        if (!existingPlayerIds.contains(playerId)) {
          existingPlayerIds.add(playerId!);
        }

        // Update the user document with the new 'onId' list
        await userDocRef
            .set({'onId': existingPlayerIds}, SetOptions(merge: true));
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              isAdmin ? const AdminScreen() : const UserScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'invalid-credential':
            passwordError = 'Incorrect password.';
            break;
          case 'user-not-found':
            identifierError = 'User not found. Please recheck or sign up.';
            break;
          default:
            identifierError = 'Authentication failed: ${e.message}';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        identifierError = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void showTemporaryRemovedPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const TemporaryRemovedPopup();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/system/bg/login.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16.0,
            right: 16.0,
            child: IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: 'Help',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MainHelpPage()),
                );
              },
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Stack(
                      children: [
                        Text(
                          'Explore Together',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 1.0
                              ..color = Colors.white,
                          ),
                        ),
                        Text(
                          'Explore Together',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  Colors.blueAccent,
                                  Color.fromARGB(255, 109, 221, 255)
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (identifierError != null)
                            Text(
                              identifierError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          if (passwordError != null)
                            Text(
                              passwordError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          const SizedBox(height: 5),
                          SizedBox(
                            width: 350,
                            child: TextFormField(
                              controller: identifierController,
                              decoration: _inputDecoration(
                                'Username, email, phone, or Aadhaar',
                                Icons.person,
                              ),
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your Username, email, phone, or Aadhaar';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 350,
                            child: TextFormField(
                              controller: passwordController,
                              obscureText: _isPasswordHidden,
                              decoration: _inputDecoration(
                                'Password',
                                Icons.lock,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordHidden
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordHidden = !_isPasswordHidden;
                                    });
                                  },
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                } else if (value.length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgetPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _isLoading ? null : loginHandle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 10,
                              ),
                              elevation: 10,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.0,
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegistrationScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: 'Don\'t have an account? ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Signup',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
