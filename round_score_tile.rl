import bounded_arg
import collections.vector
import range
import discipline
import player_action
import scenario

const NUM_ROUND_SCORE_TILES_KIND = 1

enum Resource:
    tool
    coin
    power
    scholar
    book
    spade

    fun equal(Resource other) -> Bool:
        return self.value == other.value

enum RoundScoreTileKind:
    rs_none:
        Discipline discipline = Discipline::law
        Int steps = 0
    rs_tile1:
        Discipline discipline = Discipline::law
        Int steps = 2
    rs_tile2:
        Discipline discipline = Discipline::law
        Int steps = 3
    rs_tile3:
        Discipline discipline = Discipline::law
        Int steps = 3
    rs_tile8:
        Discipline discipline = Discipline::law
        Int steps = 3
    rs_tile12:
        Discipline discipline = Discipline::banking
        Int steps = 3

    fun equal(RoundScoreTileKind other) -> Bool:
        return self.value == other.value

    fun action_bonus(Action action) -> Int:
        # vp bonus for a specific action for this round score tile
        if self == RoundScoreTileKind::rs_tile1 and action == Action::innovation_tile:
            return 5
        if self == RoundScoreTileKind::rs_tile2 and action == Action::guild:
            return 3
        if (self == RoundScoreTileKind::rs_tile3 or self == RoundScoreTileKind::rs_tile12) and action == Action::workshop:
            return 2
        if self == RoundScoreTileKind::rs_tile8 and action == Action::sailing_terraforming:
            return 3
        return 0

    fun end_round_bonus(Resource resource) -> Int:
        # resource bonus for a specific resource for this round score tile
        if self == RoundScoreTileKind::rs_tile1 and resource == Resource::power:
            return 3
        if self == RoundScoreTileKind::rs_tile2 and  resource == Resource::book:
            return 1
        if (self == RoundScoreTileKind::rs_tile3 or self == RoundScoreTileKind::rs_tile8)  and resource == Resource::scholar:
            return 1
        if self == RoundScoreTileKind::rs_tile12 and resource == Resource::power:
            return 4
        return 0

enum FinalRoundScoreTileKind:
    frs_none
    frs_school
    frs_guild
    frs_workshop_border
    frs_workshop

    fun equal(FinalRoundScoreTileKind other) -> Bool:
        return self.value == other.value

    fun action_bonus(Action action) -> Int:
        # vp bonus for a specific action this round score tile
        if self == FinalRoundScoreTileKind::frs_school and action == Action::school:
            return 4
        if self == FinalRoundScoreTileKind::frs_guild and action == Action::guild:
            return 3
        if (self == FinalRoundScoreTileKind::frs_workshop_border) and action == Action::workshop_on_border:
            return 3
        if (self == FinalRoundScoreTileKind::frs_workshop) and action == Action::workshop:
            return 2
        return 0


cls RoundScoreDisplay:
    RoundScoreTileKind[6] round_score_spaces
    FinalRoundScoreTileKind final_round_score_tile

    fun get(Int id) -> ref RoundScoreTileKind:
        return self.round_score_spaces[id]

    fun can_assign_final_round_score_tile( FinalRoundScoreTileKind kind)->Bool:
        let is_final_round_tile_workshop =  (kind == FinalRoundScoreTileKind::frs_workshop_border or kind == FinalRoundScoreTileKind::frs_workshop_border)
        let is_round_6_action_bonus_workshop = self.round_score_spaces[5] == RoundScoreTileKind::rs_tile3 or self.round_score_spaces[5] == RoundScoreTileKind::rs_tile12
        return !(is_final_round_tile_workshop and is_round_6_action_bonus_workshop)

    fun assign_final_round_score_tile( FinalRoundScoreTileKind kind):
        self.final_round_score_tile = kind

fun make_round_score_display(Scenario scenario) -> RoundScoreDisplay:
    if scenario == Scenario::test:
        return make_test_round_score_display()
    else if scenario == Scenario::sc1:
        return make_scenario1_round_score_display()
    return make_default_round_score_display()

fun make_scenario1_round_score_display() -> RoundScoreDisplay:
    #TODO implement initial assignment
    let display : RoundScoreDisplay
    return display


fun make_default_round_score_display() -> RoundScoreDisplay:
    #TODO implement initial assignment
    let display : RoundScoreDisplay
    return display

fun make_test_round_score_display() -> RoundScoreDisplay:
    let display : RoundScoreDisplay
    display[0] = RoundScoreTileKind::rs_tile1
    display[1] = RoundScoreTileKind::rs_tile2
    display[2] = RoundScoreTileKind::rs_tile3
    display.assign_final_round_score_tile(FinalRoundScoreTileKind::frs_school)
    return display

fun test_setup_round_score()->Bool:
    let display = make_round_score_display(Scenario::test)
    assert(display[1] == RoundScoreTileKind::rs_tile2, "tile on round 2")
    return true

fun test_can_assign_final_round_score()->Bool:
    let display = make_round_score_display(Scenario::test)
    display[5] = RoundScoreTileKind::rs_tile12
    assert(!display.can_assign_final_round_score_tile(FinalRoundScoreTileKind::frs_workshop_border), "workshop bonus on round 6 with action workshop bonus")
    assert(display.can_assign_final_round_score_tile(FinalRoundScoreTileKind::frs_school), "school bonus on round 6 with action workshop bonus")
    return true