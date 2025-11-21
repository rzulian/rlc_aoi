import bounded_arg
import collections.vector
import range
import discipline
import enum_range
import scenario
import player_action

const NUM_ROUND_BONUS_TILES_KIND = 11

enum RoundBonusTileKind:
    none
    navigation
    send_scholar
    guild
    big
    spade_book
    bridge_book
    science_step
    science_steps_per_guild
    power_coins
    coins

    fun equal(RoundBonusTileKind other) -> Bool:
        return self.value == other.value

    fun action_bonus(Action action) -> Int:
        # vp bonus for a specific action for this round score tile
        if self == RoundBonusTileKind::send_scholar and action == Action::send_scholar:
            return 2
        if self == RoundBonusTileKind::guild and action == Action::guild:
            return 3
        if self == RoundBonusTileKind::big and action == Action::big:
            return 4
        return 0

cls RoundBonusTile:
    Bool in_play
    Bool available
    Int coin_bonus

cls RoundBonusTiles:
    RoundBonusTile[NUM_ROUND_BONUS_TILES_KIND] tiles

    fun get(RoundBonusTileKind kind) -> ref RoundBonusTile:
        return self.tiles[kind.value]

    fun make_available(RoundBonusTileKind kind):
        self.tiles[kind.value].available = true
        self.tiles[kind.value].in_play = true

    fun draw_round_bonus_tile(RoundBonusTileKind kind):
        self.tiles[kind.value].available = false

    fun return_round_bonus_tile(RoundBonusTileKind kind):
        self.tiles[kind.value].available = true

    fun get_coin_bonus(RoundBonusTileKind kind) -> Int:
        let coins = self.tiles[kind.value].coin_bonus
        self.tiles[kind.value].coin_bonus = 0
        return coins

    fun increment_coin_bonus(RoundBonusTileKind kind):
        self.tiles[kind.value].coin_bonus = self.tiles[kind.value].coin_bonus + 1

fun make_round_bonus_tile(RoundBonusTileKind kind)->RoundBonusTile:
    let tile : RoundBonusTile
    tile.in_play = false
    tile.available = false
    tile.coin_bonus = 0
    return tile

fun make_round_bonus_tiles(Scenario scenario)->RoundBonusTiles:
    if scenario == Scenario::sc1:
        return make_scenario_1_round_bonus_tiles()
    return make_standard_round_bonus_tiles()

fun make_standard_round_bonus_tiles()->RoundBonusTiles:
        # this is the standard distribution of round bonus tiles
        #TODO standard distribution
        let tiles : RoundBonusTiles
        for kind in range(RoundBonusTileKind::navigation):
            tiles[kind] = make_round_bonus_tile(kind)
            tiles.make_available(kind)
        #tile none is not in play - to be skipped in actions preconditions
        tiles[RoundBonusTileKind::none].in_play = false
        return tiles

fun make_scenario_1_round_bonus_tiles()->RoundBonusTiles:
        # this is the scenario 1
        let tiles : RoundBonusTiles
        for kind in range(RoundBonusTileKind::navigation):
            tiles[kind] = make_round_bonus_tile(kind)
        tiles.make_available(RoundBonusTileKind::send_scholar)
        tiles.make_available(RoundBonusTileKind::big)
        tiles.make_available(RoundBonusTileKind::spade_book)
        tiles.make_available(RoundBonusTileKind::coins)
        return tiles

