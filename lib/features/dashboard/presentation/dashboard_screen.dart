import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Startbildschirm. Wird ab M2 zum „Heute-Cockpit" mit Tasks, Terminen
/// und Inbox-Zähler ausgebaut — hier zunächst ein Platzhalter für das
/// Routing-Grundgerüst.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: const Center(child: Text('Dashboard — folgt in M2')),
    );
  }
}
