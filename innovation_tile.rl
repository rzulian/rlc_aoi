import bounded_arg
import collections.vector
import range
import discipline
import enum_range
import scenario
import player_action

const NUM_INNOVATION_TILES_KIND = 20

enum InnovationTileKind:
    none
    architecture
    census
    dummy1
    communications
    league_of_cities
    sewerage
    steam_power
    professors
    trading_routes
    colleges
    workshop
    guilds
    schools
    university
    palace
    monument
    libraries
    steel
    deus_ex_machina

    fun equal(InnovationTileKind other) -> Bool:
        return self.value == other.value

    fun action_bonus(Action action) -> Int:
        # vp bonus for a specific action for this innovation tile
        #TODO clean this action bonus
        if self == InnovationTileKind::dummy1 and action == Action::send_scholar:
            return 0
        return 0

cls InnovationTile:
    Bool in_play
    Bool available
    Int[5] required_books # first four for each discipline and last is total books

    fun total_books() -> Int:
        return self.required_books[4]


cls InnovationTiles:
    InnovationTile[NUM_INNOVATION_TILES_KIND] tiles

    fun get(InnovationTileKind kind) -> ref InnovationTile:
        return self.tiles[kind.value]

    fun make_available(InnovationTileKind kind):
        self.tiles[kind.value].available = true
        self.tiles[kind.value].in_play = true

    fun draw_innovation_tile(InnovationTileKind kind):
        self.tiles[kind.value].available = false


fun make_innovation_tile(InnovationTileKind kind)->InnovationTile:
    let tile : InnovationTile
    tile.in_play = false
    tile.available = false
    return tile

fun make_innovation_tiles(Scenario scenario)->InnovationTiles:
    let tiles : InnovationTiles
    for kind in range(InnovationTileKind::none):
        tiles[kind] = make_innovation_tile(kind)
    if scenario == Scenario::sc1:
        return make_scenario1_innovation_tiles(tiles)
    else if scenario == Scenario::test:
        return make_test_innovation_tiles(tiles)
    return make_default_innovation_tiles(tiles)

fun make_default_innovation_tiles(InnovationTiles tiles)->InnovationTiles:
        # this is the standard distribution of innovation tiles
        #TODO standard distribution
        #TODO populate display
        for kind in range(InnovationTileKind::none):
            tiles.make_available(kind)
        tiles[InnovationTileKind::none].in_play = false
        tiles[InnovationTileKind::dummy1].in_play = false
        return tiles

fun make_test_innovation_tiles(InnovationTiles tiles)->InnovationTiles:
        # this is the test distribution of round bonus tiles
        tiles.make_available(InnovationTileKind::dummy1)
        tiles[InnovationTileKind::dummy1].required_books = [2,0,0,0,5]
        return tiles

fun make_scenario1_innovation_tiles(InnovationTiles tiles)->InnovationTiles:
        # this is the scenario 1
        tiles.make_available(InnovationTileKind::professors)
        tiles.make_available(InnovationTileKind::libraries)
        tiles.make_available(InnovationTileKind::colleges)
        tiles.make_available(InnovationTileKind::steam_power)
        return tiles
