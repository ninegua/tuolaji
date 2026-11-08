/// Scoring, kitty multiplier, and level progression (RULES.md §10).
///
/// `compute` and `kittyMultiplier` are ported from `simulator.js`
/// (`computeResult` / `kittyMultiplier`). Level progression awards the full
/// gained levels (1/2/3 by the attackers' points); any gain that would carry a
/// team past A overflows into the next epoch.
import Card "Card";
import Nat "mo:core/Nat";
import Combo "Combo";

module {
  public type TeamRole = { #Bankers; #Attackers };

  public type Outcome = {
    points : Nat;
    winner : TeamRole;
    gain : Nat; // levels the winning team rises
  };

  public let MAX_LEVEL : Nat = 14; // A

  /// Attacker points -> outcome (winner, points, and levels won). Wording is
  /// deliberately left to the frontend: role words like "defender" are
  /// viewer-relative and belong to the presentation layer.
  public func compute(attackerPoints : Nat) : Outcome {
    if (attackerPoints == 0) {
      { points = attackerPoints; winner = #Bankers; gain = 3 };
    } else if (attackerPoints < 40) {
      { points = attackerPoints; winner = #Bankers; gain = 2 };
    } else if (attackerPoints < 80) {
      { points = attackerPoints; winner = #Bankers; gain = 1 };
    } else if (attackerPoints < 120) {
      { points = attackerPoints; winner = #Attackers; gain = 0 };
    } else {
      let levels = Nat.sub(attackerPoints, 80) / 40;
      { points = attackerPoints; winner = #Attackers; gain = levels };
    };
  };

  /// Kitty multiplier from the final lead's structure: ×8 tractor, ×4 pair,
  /// ×2 pure singles.
  public func kittyMultiplier(lead : Combo.Lead) : Nat {
    var hasTractor = false;
    var hasPair = false;
    for (c in lead.components.vals()) {
      switch (c.kind) {
        case (#Tractor) { hasTractor := true };
        case (#Pair) { hasPair := true };
        case (#Single) {};
      };
    };
    if (hasTractor) { 8 } else if (hasPair) { 4 } else { 2 };
  };

  /// Total point value of a set of cards.
  public func pointsOf(cards : [Card.Card]) : Nat {
    var sum = 0;
    for (c in cards.vals()) { sum += Card.pointValue(c) };
    sum;
  };

  /// The winning team's new level after the levels gained (RULES.md §10:
  /// 1/2/3 by the attackers' points). Any gain that would carry the team past
  /// A overflows into the next epoch: the ladder wraps, so K + 2 -> 2,
  /// A + 1 -> 2, A + 2 -> 3, and A + 3 -> 4 (RULES.md §12).
  public func advanceLevel(currentLevel : Nat, outcome : Outcome) : Nat {
    let raw = currentLevel + outcome.gain;
    if (raw > MAX_LEVEL) {
      nextEpochLevel(currentLevel, outcome.gain)
    } else {
      raw
    };
  };

  /// The level a partnership restarts the next epoch at after winning a deal
  /// at `playedLevel`: the gained levels wrap around the 2..A ladder, so
  /// K +2 restarts at 2, and A +1/+2/+3 at 2/3/4 (RULES.md §12).
  public func nextEpochLevel(playedLevel : Nat, gain : Nat) : Nat {
    // Levels run 2..A, so there are 13 rungs; `+ 11` is `- 2 (mod 13)`, which
    // shifts into 0-based before wrapping and avoids a runtime Nat subtraction.
    ((playedLevel + gain + 11) % 13) + 2;
  };
}
