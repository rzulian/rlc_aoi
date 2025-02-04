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

    fun update_income() -> Void:
        for building in self.buildings:
            if building.is_builded:
                self.coins = self.coins + building.coin_income()


fun make_player() -> Player:
    let player : Player
    player.coins = 15
    player.tools = 3
    let i=0

    while i < 9:
        let building = make_building (BuildingType::workshop)
        player.buildings.append(building)
        i = i + 1

    let i=0
    while i < 4:
        let building = make_building (BuildingType::guild)
        player.buildings.append(building)
        i = i + 1

    let i=0
    while i < 3:
        let building = make_building (BuildingType::school)
        player.buildings.append(building)
        i = i + 1
    player.buildings.append(make_building(BuildingType::palace))
    player.buildings.append(make_building(BuildingType::university))
    
    return player

fun test_coin_income() -> Bool:
    let player = make_player()
    player.buildings[9].is_builded = true
    player.update_income()
    return player.coins == 17
