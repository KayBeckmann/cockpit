import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_context.dart';

/// Globaler Kontext-Schalter (Privat / Arbeit / Alles).
///
/// Bereiche mit weicher Trennung (Aufgaben, Termine, Kontakte, Wiki,
/// Erinnerungen) filtern ihre Listen nach diesem Zustand; Finanzen
/// erzwingt die harte Trennung zusätzlich serverseitig (siehe ADR-0006).
class ContextSwitchNotifier extends Notifier<AppContext> {
  @override
  AppContext build() => AppContext.alles;

  void setContext(AppContext context) => state = context;
}

final contextSwitchProvider =
    NotifierProvider<ContextSwitchNotifier, AppContext>(
      ContextSwitchNotifier.new,
    );
