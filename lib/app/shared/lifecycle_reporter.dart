import 'package:flutter/widgets.dart';

/// Meldet das Wiedererscheinen der App/des Tabs (Page Visibility → `resumed`)
/// an einen Callback.
///
/// Bewusst als Widget umgesetzt und nicht im Bloc: So bleibt der Bloc frei von
/// [WidgetsBinding] und in reinen Unit-Tests (ohne initialisiertes Binding)
/// konstruierbar. Platziert wird das Widget innerhalb des Bloc-Scopes, damit
/// [onResume] typischerweise ein Event am Bloc auslöst.
///
/// Zweck: Nach dem Hintergrund-Throttling der Timer rechnet der Bloc die
/// Restzeit sofort aus dem Ziel-Zeitpunkt neu, statt auf den nächsten Tick zu
/// warten.
class LifecycleReporter extends StatefulWidget {
  const LifecycleReporter({
    super.key,
    required this.onResume,
    required this.child,
  });

  final VoidCallback onResume;
  final Widget child;

  @override
  State<LifecycleReporter> createState() => _LifecycleReporterState();
}

class _LifecycleReporterState extends State<LifecycleReporter>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.onResume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
