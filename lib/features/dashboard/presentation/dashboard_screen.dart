import 'package:flutter/material.dart';

/// Startbildschirm. Wird ab M2 zum „Heute-Cockpit" mit Tasks, Terminen
/// und Inbox-Zähler ausgebaut — hier zunächst eine einfache Übersicht
/// über das Skeleton.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Willkommen bei Cockpit.\n\n'
          'Das Heute-Cockpit mit Aufgaben, Terminen und Inbox-Zähler '
          'folgt in M2 — die Module sind über das Menü erreichbar.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
