import bounded_arg
import collections.vector
import range

const NUM_COMPETENCY_TILES = 12

cls CompetencyTile:
    Int id
    String name


fun make_competency_tile(Int id, String name) -> CompetencyTile:
    let competency_tile : CompetencyTile
    competency_tile.id = id
    competency_tile.name = name
    return competency_tile

fun make_competency_tiles() -> CompetencyTile[NUM_COMPETENCY_TILES] :
    let tiles : CompetencyTile[NUM_COMPETENCY_TILES]
    for i in range(NUM_COMPETENCY_TILES):
        let competency_tile = make_competency_tile( i, to_string(i))
        tiles[i]=competency_tile
    return tiles

