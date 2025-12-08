import 'package:flutter/material.dart';

class CitizenSignUpScreen extends StatelessWidget {
  const CitizenSignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Sign Up'),
      ),
      body: const Center(
        child: Text('Citizen Sign Up Screen'),
      ),
    );
  }
}
