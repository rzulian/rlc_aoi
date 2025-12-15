import bounded_arg
import collections.vector
import range
import discipline
import scenario
import player
import player_action

const NUM_BOOK_ACTION_TILES_KIND = 7

enum BookActionTileKind:
    none:
        Int books = 0
    power:
        Int books = 1
    science_steps:
        Int books = 1
    points_guild:
        Int books = 2
    free_guild:
        Int books = 2
    coins:
        Int books = 2
    spades:
        Int books = 3

    fun equal(BookActionTileKind other) -> Bool:
        return self.value == other.value

cls BookActionTile:
    Bool in_play
    Bool available

cls BookActionTiles:
    BookActionTile[NUM_BOOK_ACTION_TILES_KIND] tiles

    fun get(BookActionTileKind kind) -> ref BookActionTile:
        return self.tiles[kind.value]

    fun make_available(BookActionTileKind kind):
        self.tiles[kind.value].available = true
        self.tiles[kind.value].in_play = true

    fun use(BookActionTileKind kind):
        self.tiles[kind.value].available = false

    fun reset(BookActionTileKind kind):
        self.tiles[kind.value].available = true

fun make_book_action_tile(BookActionTileKind kind)->BookActionTile:
    let tile : BookActionTile
    tile.in_play = false
    tile.available = false
    return tile

fun make_book_action_tiles(Scenario scenario)->BookActionTiles:
    let tiles : BookActionTiles
    for kind in range(BookActionTileKind::none):
        tiles[kind] = make_book_action_tile(kind)
    if scenario == Scenario::sc1:
        return make_scenario1_book_action_tiles(tiles)
    else if scenario == Scenario::test:
        return make_test_book_action_tiles(tiles)
    return make_default_book_action_tiles(tiles)

fun make_default_book_action_tiles(BookActionTiles tiles)->BookActionTiles:
        # this is the standard distribution of book action tiles
        #TODO standard distribution
        for kind in range(BookActionTileKind::none):
            tiles.make_available(kind)
        tiles[BookActionTileKind::none].in_play = false
        return tiles

fun make_test_book_action_tiles(BookActionTiles tiles)->BookActionTiles:
        # this is the test distribution of book_action tiles
        for kind in range(BookActionTileKind::none):
            tiles.make_available(kind)
        return tiles

fun make_scenario1_book_action_tiles(BookActionTiles tiles)->BookActionTiles:
        # this is the scenario 1
        tiles.make_available(BookActionTileKind::science_steps)
        tiles.make_available(BookActionTileKind::coins)
        tiles.make_available(BookActionTileKind::spades)
        return tiles

