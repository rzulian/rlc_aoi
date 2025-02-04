import collections.vector
import bounded_arg
import building
import range

cls Player:
    BInt<0,50> tools
    BInt<0,50> coins
    BoundedVector<Building, 18> buildings
   
    fun score() -> Float:
        let score = 0.0
        return score

    fun update_income() -> Void:
        for building in self.buildings:
            if building.is_builded:
                self.coins = self.coins + building.coin_income()
                self.tools = self.tools + building.tool_income()


fun make_player() -> Player:
    let player : Player
    player.coins = 15
    player.tools = 3
    
    for i in range(9):
        let building = make_building (BuildingType::workshop)
        player.buildings.append(building)

    for i in range(4):
        let building = make_building (BuildingType::guild)
        player.buildings.append(building)
    
    for i in range(3):
        let building = make_building (BuildingType::school)
        player.buildings.append(building)
    
    player.buildings.append(make_building(BuildingType::palace))
    player.buildings.append(make_building(BuildingType::university))
    
    return player

fun test_player_coin_income() -> Bool:
    let player = make_player()
    player.buildings[9].is_builded = true
    player.update_income()
    return player.coins == 17

fun test_player_tool_income() -> Bool:
    let player = make_player()
    player.buildings[0].is_builded = true
    player.update_income()
    return player.tools == 4



