import collections.vector
import math.numeric
import range
import action
import enum_utils
import player

const NUM_CITY_TILE_KIND = 7

enum CityTileKind:
    VP8_1SCHOLAR:
        Int[8] bonus = [8, 0, 0, 0, 1, 0, 0, 0] # vp, tool, coin, power, scholar, book, spade, discipline,
    VP7_DISCIPLINE:
        Int[8] bonus = [7, 0, 0, 0, 0, 0, 0, 1]
    VP4_3TOOLS:
        Int[8] bonus = [4, 3, 0, 0, 0, 0, 0, 0]
    VP8_8POWERS:
        Int[8] bonus = [8, 0, 0, 8, 0, 0, 0, 0]
    VP6_6COINS:
        Int[8] bonus = [6, 0, 6, 0, 0, 0, 0, 0]
    VP5_2BOOKS:
        Int[8] bonus = [5, 0, 0, 0, 0, 2, 0, 0]
    VP5_2SPADES:
        Int[8] bonus = [5, 0, 0, 0, 0, 0, 2, 0]

    fun equal(CityTileKind other) -> Bool:
        return self.value == other.value

cls CityTiles:
    BInt<0,4>[NUM_CITY_TILE_KIND] tiles

    fun get(CityTileKind kind) -> ref Int:
        return self.tiles[kind.value].value

    fun draw_city_tile(CityTileKind kind) :
        self.tiles[kind.value] = self.tiles[kind.value] - 1

    fun has_city_tile(CityTileKind kind) -> Bool:
        return self.tiles[kind.value] > 0

fun apply_city_tile_immediate_bonus(Player player, CityTileKind kind):
        player.gain_vp(kind.bonus()[0])
        player.gain_tool(kind.bonus()[1])
        player.gain_coin(kind.bonus()[2])
        player.gain_power(kind.bonus()[3])
        player.gain_scholar(kind.bonus()[4])
        player.add_book_income(kind.bonus()[5])
        player.gain_spade(kind.bonus()[6])
        player.add_one_level_discipline_income(kind.bonus()[7])

fun make_city_tiles() -> CityTiles:
    let tiles : CityTiles
    for kind in range(CityTileKind::VP8_1SCHOLAR):
            tiles[kind] = 3
    return tiles


fun test_get_city_tile() -> Bool:
    let tiles = make_city_tiles()

    let kind = CityTileKind::VP8_8POWERS
    let num = tiles[kind]
    tiles.draw_city_tile(kind)
    assert((num - tiles[kind])==1, "got a city tile")
    tiles.draw_city_tile(kind)
    let has_tile? = tiles.has_city_tile(kind)
    assert( has_tile? , "last tile available")
    tiles.draw_city_tile(kind)

    let has_tile? = tiles.has_city_tile(kind)
    assert( !has_tile? , "no tile available")
    return true
