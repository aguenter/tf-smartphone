import '../model/workout.dart';

/// Liefert den Workout-Katalog für die Home-Screen-Auswahl.
///
/// TODO: Katalog aus Supabase laden, sobald das Datenmodell steht (siehe
/// doc/0-Architecture.md). Aktuell liefert der Service den statischen
/// 9-Kacheln-Katalog aus dem UX-Konzept (ux/ux.md, Abschnitt 3).
class WorkoutService {
  Future<List<Workout>> fetchCatalog() async {
    return const [
      Workout(
        id: 'ganzkoerper-blitz',
        name: 'Ganzkörper-Blitz',
        description:
            'Klassiker-Mix für den ganzen Körper – perfekt zum Reinschnuppern.',
        isUnlocked: true,
      ),
      Workout(
        id: 'kraft-fokus',
        name: 'Kraft-Fokus',
        description:
            'Startet mit den Beinen – für alle, die es unten herum wissen wollen.',
        isUnlocked: true,
      ),
      Workout(
        id: 'rumpf-power',
        name: 'Rumpf-Power',
        description: 'Bauch zuerst – bringt die Körpermitte in Schwung.',
        isUnlocked: true,
      ),
      Workout(
        id: 'cardio-sprint',
        name: 'Cardio-Sprint',
        description:
            'Kurz, knackig, außer Atem – reine Ausdauer-Challenge fürs Team.',
        isUnlocked: false,
      ),
      Workout(
        id: 'bauch-beine-po',
        name: 'Bauch-Beine-Po',
        description:
            'Der Klassiker aus dem Kursraum, jetzt als Gruppen-Challenge.',
        isUnlocked: false,
      ),
      Workout(
        id: 'oberkoerper-fokus',
        name: 'Oberkörper-Fokus',
        description: 'Arme, Brust, Schultern – wer hält am längsten durch?',
        isUnlocked: false,
      ),
      Workout(
        id: 'team-battle',
        name: 'Team-Battle',
        description:
            'Zwei Gruppen, ein Screen – wer sammelt mehr Wiederholungen?',
        isUnlocked: false,
      ),
      Workout(
        id: 'mobility-stretch',
        name: 'Mobility & Stretch',
        description: 'Ruhiger Ausklang zum Runterkommen nach dem Kurs.',
        isUnlocked: false,
      ),
      Workout(
        id: 'eigene-workouts',
        name: 'Eigene Workouts erstellen',
        description:
            'Stelle dein eigenes Workout aus beliebigen Übungen zusammen.',
        isUnlocked: false,
      ),
    ];
  }
}
