import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// COPIE de `_SnapToItemScrollPhysics` (lib/widgets/slots_tab.dart).
///
/// La classe reelle est privee au fichier, donc inaccessible depuis un
/// test Dart separe. On duplique ici sa logique pour verrouiller le
/// comportement ; si la physique reelle evolue, cette copie doit suivre
/// (et les tests ci-dessous doivent toujours passer).
class Snap extends ScrollPhysics {
  final double itemExtent;
  const Snap({required this.itemExtent, super.parent});
  @override
  Snap applyTo(ScrollPhysics? a) =>
      Snap(itemExtent: itemExtent, parent: buildParent(a));
  @override
  Simulation? createBallisticSimulation(ScrollMetrics p, double v) {
    if (p.outOfRange) return super.createBallisticSimulation(p, v);
    if (!p.hasContentDimensions) return super.createBallisticSimulation(p, v);
    final current = p.pixels;
    final projected = current + v * 0.15;
    final target =
        (projected / itemExtent).round().clamp(0.0, double.infinity) *
        itemExtent;
    final clamped = target.clamp(p.minScrollExtent, p.maxScrollExtent);
    if ((clamped - current).abs() < 0.5) {
      return super.createBallisticSimulation(p, v);
    }
    return ScrollSpringSimulation(
      spring,
      current,
      clamped,
      v,
      tolerance: const Tolerance(velocity: 40, distance: 0.5),
    );
  }
}

FixedScrollMetrics m(double px, double max, {double min = 0}) =>
    FixedScrollMetrics(
      minScrollExtent: min,
      maxScrollExtent: max,
      pixels: px,
      viewportDimension: 800,
      devicePixelRatio: 1.0,
      axisDirection: AxisDirection.right,
    );

double settle(Simulation? s) => s!.x(8.0);

void main() {
  test(
    'repos entre deux cellules, vitesse nulle -> cellule la plus proche',
    () {
      final sim = Snap(
        itemExtent: 62,
        parent: const BouncingScrollPhysics(),
      ).createBallisticSimulation(m(30, 2000), 0);
      expect(
        sim,
        isNotNull,
        reason: 'ne doit pas rester fige entre deux cellules',
      );
      expect(settle(sim), closeTo(0, 1));
    },
  );
  test('lancer rapide -> cellule suivante', () {
    final sim = Snap(
      itemExtent: 62,
      parent: const BouncingScrollPhysics(),
    ).createBallisticSimulation(m(30, 2000), 900);
    expect(settle(sim), greaterThan(62));
  });
  test('borne max respectee', () {
    final sim = Snap(
      itemExtent: 62,
      parent: const BouncingScrollPhysics(),
    ).createBallisticSimulation(m(1990, 2000), 0);
    expect(settle(sim), lessThanOrEqualTo(2000));
  });
  test('bord inferieur : rebond delegue au parent (outOfRange)', () {
    final sim = Snap(
      itemExtent: 62,
      parent: const BouncingScrollPhysics(),
    ).createBallisticSimulation(m(-40, 2000), 0);
    expect(sim, isNotNull);
    // Le parent gere le retour elastique vers 0.
    expect(settle(sim), closeTo(0, 2));
  });
  test(
    'deja aligne -> aucune simulation, la position reste sur la cellule',
    () {
      // null = pas de simulation balistique : Flutter laisse la vue a 124,
      // ce qui est exactement la cellule alignee. C'est le comportement
      // voulu : on ne force aucun aller-retour quand rien a corriger.
      final sim = Snap(
        itemExtent: 62,
        parent: const BouncingScrollPhysics(),
      ).createBallisticSimulation(m(124, 2000), 0);
      expect(sim, isNull);
    },
  );
}
