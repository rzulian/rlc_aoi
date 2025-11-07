import bounded_arg
import collections.vector
import range
import player

const NUM_COMPETENCY_TILES = 12

cls CompetencyTile:
    BInt<0, NUM_COMPETENCY_TILES> id

fun make_competency_tile(Int id ) -> CompetencyTile:
    let competency_tile : CompetencyTile
    competency_tile.id.value = id
    return competency_tile

fun make_competency_tiles() -> CompetencyTile[NUM_COMPETENCY_TILES] :
    let tiles : CompetencyTile[NUM_COMPETENCY_TILES]
    for i in range(NUM_COMPETENCY_TILES):
        let competency_tile = make_competency_tile( i )
        tiles[i]=competency_tile
    return tiles

