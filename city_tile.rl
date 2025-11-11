import collections.vector
import math.numeric
import range
import action
import enum_utils
import enum_range

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

    fun init():
        for kind in range(CityTileKind::VP8_1SCHOLAR):
            self.tiles[kind.value] = 3

    fun get(CityTileKind kind) -> Int:
        return self.tiles[kind.value].value

    fun draw_city_tile(CityTileKind kind) :
        self.tiles[kind.value] = self.tiles[kind.value] - 1

    fun has_city_tile(CityTileKind kind) -> Bool:
        return self.tiles[kind.value] > 0

fun test_get_city_tile() -> Bool:
    let tiles : CityTiles

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
