import bounded_arg
import collections.vector
import range
import discipline
import enum_range


const NUM_ROUND_SCORE_TILES_KIND = 12

enum ActionBonus:
    workshop
    guild
    school
    big
    spade
    science_step
    city
    sailing_terraforming
    innovation_tile

    fun equal(ActionBonus other) -> Bool:
        return self.value == other.value

enum RoundScoreTileKind:
    rs_tile1:
        Discipline discipline = Discipline::law
        Int steps = 2
        Int[6] end_round_bonus = [0, 0, 3, 0, 0, 0] # tool, coin, power, scholar, book, spade
        Int[9] action_bonus = [0, 0, 0, 0, 0, 0, 0, 0, 5] # workshop, guild, school, big, spade, science_step, city, sailing_terraforming, innovation_tile
    rs_tile2:
        Discipline discipline = Discipline::law
        Int steps = 3
        Int[8] end_round_bonus = [0, 0, 0, 0, 1, 0]
        Int[9] action_bonus = [0, 3, 0, 0, 0, 0, 0, 0, 0]
    rs_tile3:
        Discipline discipline = Discipline::law
        Int steps = 3
        Int[8] end_round_bonus = [0, 0, 0, 1, 0, 0]
        Int[9] action_bonus = [2, 0, 0, 0, 0, 0, 0, 0, 0]

    fun equal(RoundScoreTileKind other) -> Bool:
        return self.value == other.value

cls RoundScoreDisplay:
    RoundScoreTileKind[6] round_score_spaces

    fun get(Int id) -> ref RoundScoreTileKind:
        return self.round_score_spaces[id]

fun make_round_score_display() -> RoundScoreDisplay:
    let display : RoundScoreDisplay
    display[0] = RoundScoreTileKind::rs_tile1
    display[1] = RoundScoreTileKind::rs_tile2
    display[2] = RoundScoreTileKind::rs_tile3
    return display

fun test_setup_round_score()->Bool:
    let spaces = make_round_score_display()
    assert(spaces[1] == RoundScoreTileKind::rs_tile2, "tile on round 2")
    return true