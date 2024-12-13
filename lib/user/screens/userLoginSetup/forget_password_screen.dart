import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../../services/user/firebase_user_auth.dart';
import 'dart:math';

import '../../../login_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});
  //const ForgetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final UserAuthServices _authServices = UserAuthServices();

  String? userId;
  bool otpSent = false;
  bool isOtpValid = false;
  bool otpVerified = false;
  Timer? resendTimer;
  int resendTimeout = 60;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String? generatedOtp;

  bool isLoadingCheckUser = false;
  bool isLoadingChangePassword = false;

  String generateOtp() {
    final random = Random();
    return (random.nextInt(900000) + 100000).toString();
  }

  void startResendTimer() {
    resendTimeout = 60;
    setState(() {});
    resendTimer?.cancel();
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimeout > 0) {
        setState(() {
          resendTimeout--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> checkUserExistence() async {
    final identifier = identifierController.text.trim();
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid identifier'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isLoadingCheckUser = true;
    });

    try {
      final foundUserId = await _authServices.checkUserExistence(identifier);

      if (foundUserId != null) {
        setState(() {
          userId = foundUserId;
          otpSent = true;
          generatedOtp = generateOtp();
          print(generatedOtp);
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User found. OTP sent to registered contact.'),
          backgroundColor: Colors.green,
        ));
        startResendTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User not found. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoadingCheckUser = false;
      });
    }
  }

  Future<void> verifyOtp() async {
    if (otpController.text.trim() == generatedOtp) {
      setState(() {
        otpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('OTP verified successfully'),
        backgroundColor: Colors.green,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invalid OTP'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> changePassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter all password fields'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Passwords do not match'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isLoadingChangePassword = true;
    });

    try {
      await _authServices.updatePassword(
          userId!, newPassword); // Update password using UserAuthServices
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password changed successfully'),
        backgroundColor: Colors.green,
      ));
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to change password: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        isLoadingChangePassword = false;
      });
    }
  }

  InputDecoration _inputDecorationWithEye(
      String label, IconData icon, bool isVisible, VoidCallback onPressed) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      prefixIcon: Icon(icon, color: Colors.white),
      suffixIcon: IconButton(
        icon: Icon(
          isVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.white,
        ),
        onPressed: onPressed,
      ),
      fillColor: Colors.black.withOpacity(0.3),
      filled: true,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white, width: 2),
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

  void resendOtp() {
    setState(() {
      generatedOtp = generateOtp();
      print(generatedOtp);
      resendTimeout = 60;
    });
    startResendTimer();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('OTP resent successfully'),
      backgroundColor: Colors.green,
    ));
  }

  @override
  void dispose() {
    resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/defaults/registration.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Forgot Password',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    if (!otpSent) ...[
                      SizedBox(
                        width: 350,
                        child: TextFormField(
                          controller: identifierController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                              "Username, email, phone, or Aadhaar",
                              Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            isLoadingCheckUser ? null : checkUserExistence,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoadingCheckUser
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Check User',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ] else if (!otpVerified) ...[
                      SizedBox(
                        width: 350,
                        child: Pinput(
                          controller: otpController,
                          length: 6,
                          showCursor: true,
                          defaultPinTheme: PinTheme(
                            height: 56,
                            width: 56,
                            textStyle: const TextStyle(
                                fontSize: 22, color: Colors.black),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreenAccent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Verify OTP'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: resendTimeout == 0 ? resendOtp : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 92, 51),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              resendTimeout == 0
                                  ? 'Resend OTP'
                                  : 'Resend in $resendTimeout s',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: 350,
                        child: TextFormField(
                          controller: newPasswordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecorationWithEye(
                              "New Password", Icons.lock, isPasswordVisible,
                              () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          }),
                          obscureText: !isPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 350,
                        child: TextFormField(
                          controller: confirmPasswordController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecorationWithEye(
                              "Confirm Password",
                              Icons.lock,
                              isConfirmPasswordVisible, () {
                            setState(() {
                              isConfirmPasswordVisible =
                                  !isConfirmPasswordVisible;
                            });
                          }),
                          obscureText: !isConfirmPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed:
                            isLoadingChangePassword ? null : changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoadingChangePassword
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Change Password',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
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
