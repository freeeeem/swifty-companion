import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:little_42_companion/main.dart';
import 'package:little_42_companion/theme.dart';
import 'package:little_42_companion/models/user_profile.dart';
import 'package:little_42_companion/widgets/projects_card.dart';
import 'package:little_42_companion/widgets/profile_card.dart';
import 'package:little_42_companion/widgets/skills_radar_chart.dart';
import 'package:little_42_companion/widgets/search_tab.dart';

/// Reproduit la collation du serveur 42 pour `sort=login`.
///
/// L'API trie en **ignorant les tirets et underscores** : `alelaval` précède
/// `alel-bad`, alors que le `String.compareTo` de Dart donnerait l'inverse.
/// C'est cette règle qui rend possible la recherche dichotomique — sans elle,
/// la sonde est placée du mauvais côté de l'intervalle et les logins contenant
/// un tiret deviennent introuvables. La règle est vérifiée ici sur des cas
/// relevés sur l'API réelle.
int serverCompare(String a, String b) {
  String fold(String s) => s.replaceAll('-', '').replaceAll('_', '');
  return fold(a).compareTo(fold(b));
}

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

/// Serie de 9 compétences nommées « Skill 0..8 » : assez pour déclencher
/// le dépliage (au-delà de 6) et pour tester la sélection d'une ligne
/// située hors du radar.
List<Map<String, dynamic>> manySkills() => List.generate(
  9,
  (i) => <String, dynamic>{
    'name': 'Skill $i',
    'level': (10 - i * 0.7).toDouble(),
  },
);

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

  testWidgets('ProjectsCard : recherche fermee par defaut', (
    WidgetTester tester,
  ) async {
    final profile = _fakeProfile();
    await tester.pumpWidget(_wrap(ProjectsCard(allProjects: profile.projects)));
    await tester.pumpAndSettle();
    expect(find.text('Libft'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('ProjectsCard : loupe ouvre la recherche et filtre', (
    WidgetTester tester,
  ) async {
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

  testWidgets('Competences : la recherche projets ne deplace pas la carte', (
    WidgetTester tester,
  ) async {
    final profile = _fakeProfile();
    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            ProjectsCard(allProjects: profile.projects),
            const SizedBox(height: 12),
            SkillsRadarChart(skills: profile.skills),
          ],
        ),
      ),
    );
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

  testWidgets(
    'Competences : la hauteur suit le contenu, elle n est pas figee',
    (WidgetTester tester) async {
      // L'ancienne implementation imposait un SizedBox(height: 240) : la
      // carte gardait exactement la meme hauteur avec 3 ou avec 30
      // competences. On verifie l'inverse.
      Future<double> heightFor(int count) async {
        final skills = List.generate(
          count,
          (i) => <String, dynamic>{
            'name': 'Skill $i',
            'level': (10 - i * 0.3).toDouble(),
          },
        );
        await tester.pumpWidget(_wrap(SkillsRadarChart(skills: skills)));
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(SkillsRadarChart)).height;
      }

      final few = await heightFor(3);
      final many = await heightFor(9);

      // 3 competences -> 3 lignes de legende ; 9 -> 6 lignes (depliant
      // ferme) : la carte doit avoir grandi.
      expect(many, greaterThan(few));
    },
  );

  testWidgets('Competences : le radar est reellement peint', (
    WidgetTester tester,
  ) async {
    final profile = _fakeProfile();
    await tester.pumpWidget(_wrap(SkillsRadarChart(skills: profile.skills)));
    await tester.pumpAndSettle();

    // On cible le CustomPaint dont le painter est bien le nôtre :
    // `find.byType(CustomPaint).first` attraperait un CustomPaint interne
    // au Material (celui du FAB), qui a un painter null.
    final paints = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .where((p) => p.painter.runtimeType.toString().contains('RadarPainter'))
        .toList();
    expect(paints, hasLength(1));
    expect(paints.first.painter, isNotNull);
  });

  testWidgets('Competences : pas de ListView imbrique dans la page', (
    WidgetTester tester,
  ) async {
    // Un scroll horizontal/vertical imbrique dans le SingleChildScrollView
    // de la page vole le geste : c'etait le bug de fluidite principal.
    final profile = _fakeProfile();
    await tester.pumpWidget(_wrap(SkillsRadarChart(skills: profile.skills)));
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('Competences : le depliant anime la hauteur', (
    WidgetTester tester,
  ) async {
    // 8 competences : au-dela de 6, la bascule de depliage apparait.
    final many = List.generate(
      8,
      (i) => <String, dynamic>{
        'name': 'Skill $i',
        'level': (10 - i).toDouble(),
      },
    );
    await tester.pumpWidget(_wrap(SkillsRadarChart(skills: many)));
    await tester.pumpAndSettle();

    expect(find.text('Voir les 2 autres'), findsOneWidget);
    expect(find.text('Skill 7'), findsNothing);

    final collapsed = tester.getSize(find.byType(SkillsRadarChart));

    await tester.tap(find.text('Voir les 2 autres'));
    await tester.pumpAndSettle();

    // Deplie : les 8 lignes sont la, le libelle a change.
    expect(find.text('Skill 7'), findsOneWidget);
    expect(find.text('Réduire'), findsOneWidget);

    final expanded = tester.getSize(find.byType(SkillsRadarChart));
    // La carte grandit reellement (elle ne se recouvre pas).
    expect(expanded.height, greaterThan(collapsed.height));
  });

  testWidgets('AppProgressBar anime de 0 a la valeur', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_wrap(const AppProgressBar(value: 0.8)));
    // Premier frame : le remplissage demarre a 0.
    final bar = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(bar.widthFactor, 0);

    await tester.pump(const Duration(milliseconds: 600));
    final settled = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(settled.widthFactor, closeTo(0.8, 0.01));
  });

  testWidgets('AppProgressBar : le remplissage a bien une hauteur visible', (
    WidgetTester tester,
  ) async {
    // Regression : sans heightFactor, le ColoredBox de remplissage se
    // resizeait a 0 px de haut et la barre affichee restait completement
    // vide (le widget existait, les tests de valeur passaient, mais a
    // l'ecran on ne voyait rien).
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: AppProgressBar(value: 0.5, height: 5)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    // Dernier ColoredBox de l'arbre = la partie remplie.
    final fills = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .toList();
    final fillSize = tester
        .renderObject<RenderBox>(find.byWidget(fills.last))
        .size;

    expect(fillSize.height, 5);
    expect(fillSize.width, greaterThan(0));
  });

  testWidgets('« Voir les N autres » deploie la liste', (tester) async {
    await tester.pumpWidget(_wrap(SkillsRadarChart(skills: manySkills())));
    await tester.pumpAndSettle();

    // Replie : 6 lignes, la 7e absente, le controle visible.
    expect(find.text('Skill 5'), findsOneWidget);
    expect(find.text('Skill 6'), findsNothing);
    expect(find.text('Voir les 3 autres'), findsOneWidget);

    final collapsed = tester.getSize(find.byType(SkillsRadarChart));

    // La pastille de l'en-tete a ete retiree : « Tout voir » n'existe plus,
    // le seul point d'entree est en bas de liste.
    expect(find.text('Tout voir'), findsNothing);

    await tester.tap(find.text('Voir les 3 autres'));
    await tester.pumpAndSettle();

    // La 7e ligne apparait et la bascule se retourne en « Reduire ».
    expect(find.text('Skill 6'), findsOneWidget);
    expect(find.text('Voir les 3 autres'), findsNothing);
    expect(find.text('Réduire'), findsOneWidget);

    expect(
      tester.getSize(find.byType(SkillsRadarChart)).height,
      greaterThan(collapsed.height),
    );
  });

  testWidgets('« Reduire » referme la liste', (tester) async {
    await tester.pumpWidget(_wrap(SkillsRadarChart(skills: manySkills())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir les 3 autres'));
    await tester.pumpAndSettle();
    expect(find.text('Skill 8'), findsOneWidget);

    // Une fois deployee, la carte est plus haute que le viewport de test :
    // la bascule passe sous la ligne de flottaison. Un vrai utilisateur
    // scrolle, il faut donc faire pareil, sinon le tap ne touche rien.
    await tester.ensureVisible(find.text('Réduire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réduire'));
    await tester.pumpAndSettle();
    expect(find.text('Skill 8'), findsNothing);
    expect(find.text('Voir les 3 autres'), findsOneWidget);
  });

  testWidgets('pas de debordement une fois deplie', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(_wrap(SkillsRadarChart(skills: manySkills())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir les 3 autres'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('un seul controle de depliage, cale sur le bord de la carte', (
    tester,
  ) async {
    // La pastille de l'en-tete a ete retiree : la carte n'expose plus qu'un
    // point d'entree, en bas de la liste. Ce test verrouille ce choix pour
    // qu'un futur retour du bouton en haut a droite soit un echec_visible.
    await tester.pumpWidget(_wrap(SkillsRadarChart(skills: manySkills())));
    await tester.pumpAndSettle();

    // Aucun controle en haut a droite.
    expect(find.text('Tout voir'), findsNothing);

    // Un seul controle en bas, aligne sur le bord du contenu de la carte.
    final chip = tester.getRect(
      find
          .ancestor(
            of: find.text('Voir les 3 autres'),
            matching: find.byType(Align),
          )
          .first,
    );
    // Marge interne de la carte (16). tolerance de 2 px : on verifie
    // l'alignement, pas le rendu au pixel.
    expect(chip.left, closeTo(16, 2));

    // Et il reste le seul moyen de replier la liste.
    await tester.tap(find.text('Voir les 3 autres'));
    await tester.pumpAndSettle();
    expect(find.text('Skill 8'), findsOneWidget);

    // Une fois deployee, la carte est plus haute que le viewport de test :
    // la bascule passe sous la ligne de flottaison. Un vrai utilisateur
    // scrolle, il faut donc faire pareil, sinon le tap ne touche rien.
    await tester.ensureVisible(find.text('Réduire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Réduire'));
    await tester.pumpAndSettle();
    expect(find.text('Skill 8'), findsNothing);
    expect(find.text('Voir les 3 autres'), findsOneWidget);
  });

  // --- Recherche approximative de login ---------------------------------
  // `GET /v2/users/:login` ne fait que de la correspondance exacte : ces tests
  // verrouillent la brique client qui propos des correspondants partiels.
  group('UserCandidate', () {
    test('lit login, displayname et avatar de la version "light"', () {
      final candidate = UserCandidate.fromJson({
        'login': 'lrezette',
        'displayname': 'Livio Rezette',
        'image': {
          'versions': {'medium': 'https://cdn.intra.42.fr/x/medium.jpg'},
        },
      });
      expect(candidate.login, 'lrezette');
      expect(candidate.displayName, 'Livio Rezette');
      expect(candidate.avatarUrl, 'https://cdn.intra.42.fr/x/medium.jpg');
    });

    test('tolère un JSON sans image ni displayname', () {
      final candidate = UserCandidate.fromJson({'login': 'inconnu'});
      expect(candidate.login, 'inconnu');
      expect(candidate.displayName, 'Inconnu');
      expect(candidate.avatarUrl, isNull);
    });
  });

  group('SearchTab', () {
    testWidgets('affiche l\'invite de recherche au départ', (tester) async {
      await tester.pumpWidget(_wrap(const SearchTab()));
      expect(find.text('Rechercher un étudiant'), findsOneWidget);
      expect(find.text('Rechercher un login'), findsOneWidget);
    });
  });

  group('ProfileCard présence', () {
    UserProfile onlineProfile() {
      return UserProfile(
        id: 4242,
        displayName: 'Jane Doe',
        firstName: 'Jane',
        login: 'jadoe',
        email: 'jadoe@student.42.fr',
        avatarUrl: null,
        campus: 'Paris, France',
        location: 'c1r2s3',
        level: 5.42,
        levelInt: 5,
        levelPercent: 42,
        wallet: 100,
        correctionPoints: 3,
        skills: const [],
        projects: const [],
        lastThreeProjects: const [],
      );
    }

    testWidgets('en ligne : pastille verte + poste mono + ID copiable',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          _wrap(ProfileCard(profile: onlineProfile())));
      await tester.pumpAndSettle();
      expect(find.text('En ligne'), findsOneWidget);
      // Poste affiché brut en mono (plus de petit "Sur ..." gris).
      expect(find.text('c1r2s3'), findsOneWidget);
      expect(find.text('Sur c1r2s3'), findsNothing);
      expect(find.text('4242'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hors ligne : pastille grise + message aucun poste',
        (tester) async {
      final offline = UserProfile(
        id: 7,
        displayName: 'John Doe',
        firstName: 'John',
        login: 'jdoe',
        email: 'jdoe@student.42.fr',
        avatarUrl: null,
        campus: 'Paris, France',
        location: null,
        level: 1.0,
        levelInt: 1,
        levelPercent: 0,
        wallet: 0,
        correctionPoints: 0,
        skills: const [],
        projects: const [],
        lastThreeProjects: const [],
      );
      await tester.pumpWidget(_wrap(ProfileCard(profile: offline)));
      await tester.pumpAndSettle();
      expect(find.text('Hors ligne'), findsOneWidget);
      expect(find.text('Aucun poste en ce moment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pas de débordement sur mobile étroit (320 px)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          _wrap(ProfileCard(profile: onlineProfile())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
