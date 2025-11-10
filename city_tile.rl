import collections.vector
import math.numeric
import range
import action
import enum_utils

const NUM_CITY_TILE_KIND = 7

cls CityTileKindID:
    BInt<0, NUM_CITY_TILE_KIND> id

    fun get() -> Int:
        return self.id.value

    fun assign(Int value):
        self.id = value

fun city_tile_kind_id(Int id) -> CityTileKindID:
    let to_return :  CityTileKindID
    to_return = id
    return to_return

fun city_tile_kind(CityTileKindID id) -> CityTileKind:
    let to_return :  CityTileKind
    to_return.value = id.get()
    return to_return

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

    fun get( CityTileKindID id) -> Int:
        return self.tiles[ id.get() ].value

    fun get( CityTileKind city_tile_kind) -> Int:
        return self.tiles[ city_tile_kind.value ].value

    fun get_city_tile( CityTileKindID id) -> CityTileKind:
        self.tiles[id.get()] = self.tiles[id.get()] - 1
        return city_tile_kind(id)

    fun has_city_tile( CityTileKindID id ) -> Bool:
        return self.tiles[id.get()] > 0

fun make_city_tiles() -> CityTiles:
    let city_tiles : CityTiles
    for i in range( NUM_CITY_TILE_KIND ):
        city_tiles.tiles[i] = 3
    return city_tiles

fun test_get_city_tile() -> Bool:
    let tiles : CityTiles
    tiles = make_city_tiles()

    let id = city_tile_kind_id(CityTileKind::VP8_8POWERS.value)
    let num = tiles[id]
    tiles.get_city_tile(id)
    assert((num - tiles[id])==1, "got a city tile")
    tiles.get_city_tile(id)
    let has_tile? = tiles.has_city_tile(id)
    assert( has_tile? , "last tile available")
    tiles.get_city_tile(id)

    let has_tile? = tiles.has_city_tile(id)
    assert( !has_tile? , "no tile available")
    return true

