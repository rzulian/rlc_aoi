import action
import enum_utils
import enum_range

const NUM_PALACE_TILE_KIND = 17

enum PalaceTileKind:
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

    fun init():
        for kind in range(PalaceTileKind::power5_tool2):
            self.tiles[kind.value] = 0

    fun get(PalaceTileKind kind) -> ref Int:
        return self.tiles[kind.value].value

    fun draw_palace_tile(PalaceTileKind kind) :
        self.tiles[kind.value] = self.tiles[kind.value] - 1

    fun has_palace_tile(PalaceTileKind kind) -> Bool:
        return self.tiles[kind.value] > 0

    fun setup_scenario_std():
        self.tiles[PalaceTileKind::power2_upgrade_to_guild.value] = 1
        self.tiles[PalaceTileKind::power2_vp10.value] = 1

fun test_assign()->Bool:
    let tiles : PalaceTiles
    tiles[PalaceTileKind::power2_upgrade_to_guild] = 1
    assert(tiles[PalaceTileKind::power2_upgrade_to_guild] == 1, "available")
    tiles.draw_palace_tile(PalaceTileKind::power2_upgrade_to_guild)
    assert(tiles[PalaceTileKind::power2_upgrade_to_guild] == 0, "not available")
    return true

fun test_scenario_std()->Bool:
    let tiles : PalaceTiles
    tiles.setup_scenario_std()
    assert(tiles[PalaceTileKind::power2_upgrade_to_guild] == 1, "available")
    tiles.draw_palace_tile(PalaceTileKind::power2_upgrade_to_guild)
    assert(tiles[PalaceTileKind::power2_upgrade_to_guild] == 0, "not available")
    return true