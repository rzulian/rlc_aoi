import bounded_arg
import collections.vector
import range


cls CompetencyTile:
    Int id
    String name


fun make_competency_tile(Int id, String name) -> CompetencyTile:
    let competency_tile : CompetencyTile
    competency_tile.id = id
    competency_tile.name = name
    return competency_tile

fun make_competency_tiles() -> BoundedVector<CompetencyTile, 13> :
    let tiles : BoundedVector<CompetencyTile,13> 
    for i in range(13):
        let competency_tile = make_competency_tile( i, to_string(i))
        tiles.append(competency_tile)
    return tiles

