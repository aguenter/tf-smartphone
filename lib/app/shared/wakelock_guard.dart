import 'package:flutter/widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Hält den Bildschirm während der Nutzung wach (Screen Wake Lock API).
///
/// Umschließt die App und fordert den Wakelock beim Start an. Browser geben
/// den Wakelock automatisch frei, sobald der Tab in den Hintergrund wechselt
/// oder der Bildschirm gesperrt wird – deshalb wird er bei jedem `resumed`
/// erneut angefordert. Ohne dieses erneute Anfordern würde der Bildschirm nach
/// einmaligem Wegschalten dauerhaft ohne Wakelock laufen.
///
/// Auf Browsern ohne Wake-Lock-Unterstützung ist der Aufruf ein No-op (der
/// Fehler wird verschluckt, statt die App abstürzen zu lassen).
///
/// **iFrame-Einbettung:** Der Screen Wake Lock benötigt die Permission-Policy
/// `allow="screen-wake-lock"` am einbettenden `<iframe>`. Fehlt sie, bleibt der
/// Aufruf im eingebetteten Kontext wirkungslos.
class WakelockGuard extends StatefulWidget {
  const WakelockGuard({super.key, required this.child});

  final Widget child;

  @override
  State<WakelockGuard> createState() => _WakelockGuardState();
}

class _WakelockGuardState extends State<WakelockGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enable();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enable();
    }
  }

  void _enable() {
    // Fehler bewusst verschlucken: nicht unterstützte Browser (bzw. iFrames
    // ohne Permission-Policy) liefern eine Exception – der Timer läuft dann
    // ohne Wakelock weiter, statt die App scheitern zu lassen.
    WakelockPlus.enable().catchError((_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
