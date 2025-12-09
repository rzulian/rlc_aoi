import bounded_arg
import collections.vector
import range
import discipline
import enum_range
import scenario
import player_action
import player

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
        self.tiles[kind.value].required_books = [0,0,0,0,5]

    fun draw_innovation_tile(InnovationTileKind kind):
        self.tiles[kind.value].available = false

fun apply_innovation_tile_immediate_bonus(Player player, InnovationTileKind kind) -> Void:
    if kind == InnovationTileKind::colleges:
        player.gain_vp(player.schools.value * 5)
    else if kind == InnovationTileKind::libraries:
        let high1 = 0
        let high2 = 0
        for i in range(4):
            if player.discipline_level[i].value >= high1:
                high2 = high1
                high1 = player.discipline_level[i].value
            else if player.discipline_level[i] >= high2:
                high2 = player.discipline_level[i].value
        player.gain_vp(high1 + high2)
    else if kind == InnovationTileKind::steam_power:
        if player.terraforming_track_level<2:
            player.upgrade_terraforming(false)
        if player.sailing_track_level<3:
            player.upgrade_sailing(false)
        if player.scholars.value > 0:
            player.gain_scholar(1)
    else if kind == InnovationTileKind::professors:
        player.special_action_professors = true
    return

fun apply_innovation_tile_income_bonus(Player player):
    for kind in player.innovation_tiles:
        if  kind == InnovationTileKind::professors:
            player.special_action_professors = true


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