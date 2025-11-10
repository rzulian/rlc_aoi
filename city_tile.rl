import collections.vector
import math.numeric
import range
import action
import enum_utils

const NUM_CITY_TILES = 21
const NUM_CITY_TILE_TYPES = 7

using CityTileKindID = BInt<0, NUM_CITY_TILE_TYPES>

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

using CityTileVector = BoundedVector<CityTileKind, NUM_CITY_TILES>

cls CityTiles:
    CityTileVector tiles

    fun get_city_tile( CityTileKind city_tile_kind ) -> Bool:
        for i in range(self.tiles.size()):
            if self.tiles[i] == city_tile_kind:
                self.tiles.erase(i)
                return true
        return false

    fun has_city_tile( CityTileKind city_tile_kind ) -> Bool:
        for i in range(self.tiles.size()):
            if self.tiles[i] == city_tile_kind:
                return true
        return false

fun make_city_tiles() -> CityTiles:
    let city_tiles : CityTiles
    for city_tile_kind in enumerate(CityTileKind::VP8_1SCHOLAR):
        city_tiles.tiles.append(city_tile_kind)
        city_tiles.tiles.append(city_tile_kind)
        city_tiles.tiles.append(city_tile_kind)
    return city_tiles

fun test_get_city_tile() -> Bool:
    let tiles : CityTiles
    tiles = make_city_tiles()
    let num = tiles.tiles.size()
    tiles.get_city_tile(CityTileKind::VP8_8POWERS)
    assert(num - tiles.tiles.size()==1, "got a city tile")
    tiles.get_city_tile(CityTileKind::VP8_8POWERS)
    let has_tile? = tiles.has_city_tile(CityTileKind::VP8_8POWERS)
    let tile? = tiles.get_city_tile(CityTileKind::VP8_8POWERS)
    assert( tile? and has_tile? , "last tile available")
    let tile? = tiles.get_city_tile(CityTileKind::VP8_8POWERS)
    assert( !tile? , "no tile available")
    return true

