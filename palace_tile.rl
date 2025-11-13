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

    fun get(PalaceTileKind kind) -> ref Int:
        return self.tiles[kind.value].value

    fun draw_palace_tile(PalaceTileKind kind) :
        self.tiles[kind.value] = self.tiles[kind.value] - 1

    fun has_palace_tile(PalaceTileKind kind) -> Bool:
        return self.tiles[kind.value] > 0

fun make_palace_tiles()->PalaceTiles:
    let tiles : PalaceTiles
    for kind in range(PalaceTileKind::power5_tool2):
            tiles[kind] = 0
    tiles[PalaceTileKind::power2_upgrade_to_guild] = 1
    tiles[PalaceTileKind::power2_vp10] = 1
    return tiles


fun test_scenario_std()->Bool:
    let tiles = make_palace_tiles()
    assert(tiles[PalaceTileKind::power2_upgrade_to_guild] == 1, "available")
    tiles.draw_palace_tile(PalaceTileKind::power2_upgrade_to_guild)
    assert(tiles[PalaceTileKind::power2_upgrade_to_guild] == 0, "not available")
    return true