# Calculateur de Deadlines - Système de Rythme (Pace System) 42

Ce document regroupe les règles de calcul, la distribution des jours et un exemple d'implémentation en Dart du système de rythme (Pace System) de l'école 42, basé sur le projet [deadlines42Public](https://github.com/LLuisPP/deadlines42Public).

---

## 1. Fonctionnement du Système de Rythme (Pace System)
Le Pace System est conçu pour donner aux étudiants des jalons (milestones) réguliers afin de valider le tronc commun (Common Core) dans un délai prédéfini (8, 12, 15, 18, 22 ou 24 mois).

* **Kickoff Date :** La date de début de ton cursus (récupérée via `begin_at` dans `cursus_users`).
* **Milestones (0 à 6) :** Les 7 étapes du tronc commun qui correspondent généralement aux cercles de progression.
* **Jours bonus :** Des jours supplémentaires accordés par le staff ou gagnés, qui s'ajoutent à un milestone spécifique.

---

## 2. Table de Distribution des Jours
Chaque rythme (Pace) attribue un nombre de jours précis pour chaque milestone.

| Milestone | Pace 8 mois | Pace 12 mois | Pace 15 mois | Pace 18 mois | Pace 22 mois | Pace 24 mois |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **M0** (Circle 0) | 8 jours | 13 jours | 18 jours | 24 jours | 30 jours | 45 jours |
| **M1** (Circle 1) | 24 jours | 35 jours | 42 jours | 48 jours | 58 jours | 73 jours |
| **M2** (Circle 2) | 22 jours | 33 jours | 41 jours | 49 jours | 60 jours | 60 jours |
| **M3** (Circle 3) | 36 jours | 53 jours | 67 jours | 80 jours | 98 jours | 128 jours |
| **M4** (Circle 4) | 51 jours | 77 jours | 96 jours | 115 jours | 141 jours | 141 jours |
| **M5** (Circle 5) | 71 jours | 107 jours | 134 jours | 162 jours | 197 jours | 197 jours |
| **M6** (Circle 6) | 32 jours | 47 jours | 59 jours | 70 jours | 86 jours | 86 jours |
| **Total** | **244 jours** | **366 jours** | **458 jours** | **549 jours** | **671 jours** | **730 jours** |

---

## 3. Logique de Calcul (Formule)
La date d'échéance de chaque milestone se calcule par addition **cumulative** de jours à partir de la date de Kickoff :

$$\text{Date Milestone } K = \text{Kickoff Date} + \sum_{i=0}^{K} (\text{Jours Milestone } i) + \text{Jours Bonus (sur le milestone actif)}$$

---

## 4. Exemple d'implémentation Dart / Flutter
Voici un code prêt à l'emploi en Dart si tu souhaites l'intégrer plus tard dans ton application.

```dart
class MilestoneDeadline {
  final int index;
  final DateTime deadline;

  MilestoneDeadline({required this.index, required this.deadline});
}

class PaceCalculator {
  // Table de distribution des jours par rythme (Pace)
  static const Map<int, List<int>> paceDistributions = {
    8:  [8, 24, 22, 36, 51, 71, 32],
    12: [13, 35, 33, 53, 77, 107, 47],
    15: [18, 42, 41, 67, 96, 134, 59],
    18: [24, 48, 49, 80, 115, 162, 70],
    22: [30, 58, 60, 98, 141, 197, 86],
    24: [45, 73, 60, 128, 141, 197, 86],
  };

  /// Calcule la liste des dates d'échéance pour tous les milestones
  /// [kickoffDate] : date de début de l'étudiant
  /// [chosenPace] : le rythme choisi (8, 12, 15, 18, 22, 24)
  /// [activeMilestone] : le milestone sur lequel l'étudiant se trouve (0 à 6)
  /// [bonusDays] : les jours bonus à ajouter au milestone actif
  static List<MilestoneDeadline> calculateDeadlines({
    required DateTime kickoffDate,
    required int chosenPace,
    required int activeMilestone,
    int bonusDays = 0,
  }) {
    final List<int>? selectedPaceDays = paceDistributions[chosenPace];
    if (selectedPaceDays == null) {
      throw ArgumentError("Pace non supporté : $chosenPace. Choisissez parmi 8, 12, 15, 18, 22, 24.");
    }

    List<MilestoneDeadline> results = [];
    int cumulativeDays = 0;

    for (int i = 0; i < 7; i++) {
      int daysForThisMilestone = selectedPaceDays[i];
      
      // Ajouter les jours bonus uniquement si on est sur le milestone actif
      if (i == activeMilestone) {
        daysForThisMilestone += bonusDays;
      }
      
      cumulativeDays += daysForThisMilestone;
      
      final DateTime deadlineDate = kickoffDate.add(Duration(days: cumulativeDays));
      results.add(MilestoneDeadline(index: i, deadline: deadlineDate));
    }

    return results;
  }
}
```

---

## 5. Comment l'utiliser avec l'API 42
Pour récupérer les variables nécessaires à l'appel de cette fonction :
1. **`kickoffDate`** : Prends la valeur de `begin_at` du cursus `42cursus` de l'étudiant :
   ```dart
   final mainCursus = profile.cursusUsers.firstWhere((c) => c.slug == '42cursus');
   final DateTime kickoff = mainCursus.beginAt;
   ```
2. **`activeMilestone`** : Tu peux l'estimer par rapport au niveau actuel de l'étudiant (ex: si niveau < 1.0 -> M0, si niveau < 2.0 -> M1, etc.).
