import bounded_arg
import collections.vector

enum BuildingType:
    workshop
    guild
    palace
    school
    university

    fun equal(BuildingType other) -> Bool:
        return self.value == other.value


cls Building:
    BuildingType building_type
    Bool is_builded

    
    fun coin_cost()-> Int:
        let costs = [2,3,6,5,8]
        return costs[self.building_type.value]

    fun coin_income()->Int:
        let incomes = [0,2,0,0,0]
        return incomes[self.building_type.value]


fun make_building(BuildingType building_type) -> Building:
    let building : Building
    building.building_type = building_type
    building.is_builded = false
    return building




fun test_coin_cost() -> Bool:
    let workshop = make_building( BuildingType::workshop )
    return workshop.coin_cost() == 2 

fun test_coin_income() -> Bool:
    let guild = make_building( BuildingType::guild )
    return guild.coin_income() == 2

    
        
