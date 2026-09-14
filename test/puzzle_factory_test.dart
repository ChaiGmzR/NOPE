import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nope/screens/focus_lock_screen.dart';

void main() {
  test('the pause gate contains ten different challenge kinds', () {
    final factory = PuzzleFactory(random: math.Random(42));
    final kinds = factory.shuffledKinds();

    expect(kinds, hasLength(10));
    expect(kinds.toSet(), containsAll(PuzzleKind.values));
  });

  test('every choice challenge includes its correct answer', () {
    final factory = PuzzleFactory(random: math.Random(7));
    final choiceKinds = PuzzleKind.values.where(
      (kind) => !factory.isMiniGame(kind),
    );

    for (final kind in choiceKinds) {
      for (var attempt = 0; attempt < 20; attempt++) {
        final challenge = factory.generate(kind);
        expect(challenge.options, hasLength(4), reason: kind.name);
        expect(
          challenge.options,
          contains(challenge.answer),
          reason: kind.name,
        );
        expect(challenge.options.toSet(), hasLength(4), reason: kind.name);
      }
    }
  });
}
