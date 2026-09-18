import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_42_companion/main.dart';
import 'package:little_42_companion/theme.dart';
import 'package:little_42_companion/models/user_profile.dart';
import 'package:little_42_companion/widgets/projects_card.dart';
import 'package:little_42_companion/widgets/skills_radar_chart.dart';

UserProfile _fakeProfile() {
  return UserProfile(
    id: 1,
    displayName: 'Jane Doe',
    firstName: 'Jane',
    login: 'jadoe',
    email: 'jadoe@student.42.fr',
    avatarUrl: null,
    campus: 'Paris, France',
    level: 5.42,
    levelInt: 5,
    levelPercent: 42,
    wallet: 100,
    correctionPoints: 3,
    skills: const [
      {'name': 'Unix', 'level': 10.0},
      {'name': 'Web', 'level': 8.0},
      {'name': 'Graphics', 'level': 6.0},
    ],
    projects: [
      ProjectItem(
        name: 'Libft',
        status: 'finished',
        finalMark: 100,
        validated: true,
        updatedAt: DateTime(2025, 1, 2),
        createdAt: DateTime(2025, 1, 1),
      ),
      ProjectItem(
        name: 'Minishell',
        status: 'finished',
        finalMark: 0,
        validated: false,
        updatedAt: DateTime(2025, 2, 2),
        createdAt: DateTime(2025, 2, 1),
      ),
    ],
    lastThreeProjects: const [],
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('Login affiche le CTA 42', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    await tester.pumpAndSettle();
    expect(find.text('Se connecter avec 42'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
  });

  testWidgets('ProjectsCard : recherche fermee par defaut', (WidgetTester tester) async {
    final profile = _fakeProfile();
    await tester.pumpWidget(_wrap(ProjectsCard(allProjects: profile.projects)));
    await tester.pumpAndSettle();
    expect(find.text('Libft'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('ProjectsCard : loupe ouvre la recherche et filtre', (WidgetTester tester) async {
    final profile = _fakeProfile();
    await tester.pumpWidget(_wrap(ProjectsCard(allProjects: profile.projects)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'libf');
    await tester.pumpAndSettle();
    expect(find.text('Libft'), findsOneWidget);
    expect(find.text('Minishell'), findsNothing);
  });

  testWidgets('ProjectsCard filtre Valides', (WidgetTester tester) async {
    final profile = _fakeProfile();
    await tester.pumpWidget(_wrap(ProjectsCard(allProjects: profile.projects)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Valides'));
    await tester.pumpAndSettle();
    expect(find.text('Libft'), findsOneWidget);
    expect(find.text('Minishell'), findsNothing);
  });

  testWidgets('Competences : hauteur fixe quelle que soit la recherche', (WidgetTester tester) async {
    final profile = _fakeProfile();
    await tester.pumpWidget(_wrap(Column(children: [
      ProjectsCard(allProjects: profile.projects),
      const SizedBox(height: 12),
      SkillsRadarChart(skills: profile.skills),
    ])));
    await tester.pumpAndSettle();

    final before = tester.getSize(find.byType(SkillsRadarChart));

    // Ouvre la recherche et filtre : la carte competences ne doit pas bouger.
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'libf');
    await tester.pumpAndSettle();

    final after = tester.getSize(find.byType(SkillsRadarChart));
    // La carte ne bouge pas quand on filtre les projets au-dessus.
    expect(after.height, equals(before.height));
  });
}
