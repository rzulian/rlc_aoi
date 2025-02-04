import bounded_arg
import collections.vector

enum Colour:
    white
    orange
    red
    green
    blue
    purple
    yellow

    fun equal(Colour hex_col) -> Bool:
        return self.value == hex_col.value

enum TerrainID:
    A1:
        Colour color = Colour::white

cls Terrain:
     TerrainID id

cls Board:
    Terrain[31] terrains
    
    fun add_terrain(TerrainID id):
        let terrain : Terrain
        terrain.id = id
        self.terrains[id.value] = terrain

fun make_board() -> Board:
    let board : Board
    board.add_terrain(TerrainID::A1)

    return board


