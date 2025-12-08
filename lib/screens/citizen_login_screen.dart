import 'package:flutter/material.dart';

class CitizenLoginScreen extends StatelessWidget {
  const CitizenLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Login'),
      ),
      body: const Center(
        child: Text('Citizen Login Screen'),
      ),
    );
  }
}
