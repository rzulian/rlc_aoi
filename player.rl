import collections.vector
import bounded_arg
import building

cls Player:
    BInt<0,50> tools
    BInt<0,50> coins
    BoundedVector<Building, 18> buildings
   
    fun score() -> Float:
        let score = 0.0
        return score

fun make_player() -> Player:
    let player : Player
    player.coins = 15
    player.tools = 3
    let i=0

    while i < 9:
        let building = make_building (BuildingType::workshop)
        player.buildings.append(building)
        i = i + 1
    
    return player



