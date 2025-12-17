import action
import enum_utils
import scenario
import player

const NUM_PALACE_TILE_KIND = 18

enum PalaceTileKind:
    none
    power5_tool2
    spades2
    pt3
    power2_upgrade_to_guild
    pt5
    pt6
    pt7
    pt8
    pt9
    pt10
    pt11
    pt12
    pt13
    pt14
    pt15
    pt16
    power2_vp10

    fun equal(PalaceTileKind other) -> Bool:
        return self.value == other.value

cls PalaceTiles:
    BInt<0,2>[NUM_PALACE_TILE_KIND] tiles

    fun get(PalaceTileKind kind) -> ref Int:
        return self.tiles[kind.value].value

    fun draw_palace_tile(PalaceTileKind kind) :
        self.tiles[kind.value] = self.tiles[kind.value] - 1

    fun has_palace_tile(PalaceTileKind kind) -> Bool:
        return self.tiles[kind.value] > 0

fun apply_palace_tile_immediate_bonus(Player player, PalaceTileKind kind):
    if kind == PalaceTileKind::power2_vp10:
        player.gain_vp(10)
    else if kind == PalaceTileKind::power2_upgrade_to_guild:
        player.palace_upgrade_to_guild = true

fun apply_palace_tile_income_bonus(Player player):
        if  player.palace == PalaceTileKind::power2_upgrade_to_guild:
            player.add_power_income(2)
            player.palace_upgrade_to_guild = true
        else if  player.palace == PalaceTileKind::power2_vp10:
            player.add_power_income(2)

fun apply_palace_tile_pass_bonus(Player player):
        return

fun make_palace_tiles(Scenario scenario)->PalaceTiles:
    let tiles : PalaceTiles
    for kind in range(PalaceTileKind::none):
            tiles[kind] = 0
    #TODO standard and test
    return make_scenario_1_palace_tiles(tiles)

fun make_scenario_1_palace_tiles(PalaceTiles tiles) -> PalaceTiles:
    tiles[PalaceTileKind::power2_upgrade_to_guild] = 1
    tiles[PalaceTileKind::power2_vp10] = 1
    return tiles


fun test_scenario_std()->Bool:
    let tiles = make_palace_tiles(Scenario::test)
    assert(tiles[PalaceTileKind::power2_upgrade_to_guild] == 1, "available")
    tiles.draw_palace_tile(PalaceTileKind::power2_upgrade_to_guild)
    assert(tiles[PalaceTileKind::power2_upgrade_to_guild] == 0, "not available")
    return true