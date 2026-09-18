import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_42_companion/main.dart';
import 'package:little_42_companion/theme.dart';
import 'package:little_42_companion/models/user_profile.dart';
import 'package:little_42_companion/widgets/projects_card.dart';

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
    skills: const [],
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

void main() {
  testWidgets('Login affiche le CTA 42', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(isLoggedIn: false));
    await tester.pumpAndSettle();
    expect(find.text('Se connecter avec 42'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
  });

  testWidgets('ProjectsCard filtre par recherche', (WidgetTester tester) async {
    final profile = _fakeProfile();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: ProjectsCard(allProjects: profile.projects)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Libft'), findsOneWidget);
    expect(find.text('Minishell'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'libf');
    await tester.pumpAndSettle();
    expect(find.text('Libft'), findsOneWidget);
    expect(find.text('Minishell'), findsNothing);
  });

  testWidgets('ProjectsCard filtre Valides / En cours', (WidgetTester tester) async {
    final profile = _fakeProfile();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: ProjectsCard(allProjects: profile.projects)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Valides'));
    await tester.pumpAndSettle();
    expect(find.text('Libft'), findsOneWidget);
    expect(find.text('Minishell'), findsNothing);
  });
}
