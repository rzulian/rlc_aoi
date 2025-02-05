import bounded_arg
import collections.vector

enum BuildingType:
    workshop:
        Int tool_cost = 1
        Int coin_cost = 2
    guild:
        Int tool_cost = 2
        Int coin_cost = 3
    palace:
        Int tool_cost = 4
        Int coin_cost = 6
    school:
        Int tool_cost = 3
        Int coin_cost = 5
    university:
        Int tool_cost = 5
        Int coin_cost = 8

    fun equal(BuildingType other) -> Bool:
        return self.value == other.value


cls Building:
    BuildingType building_type
    Bool is_builded

fun make_building(BuildingType building_type) -> Building:
    let building : Building
    building.building_type = building_type
    building.is_builded = false
    return building

fun test_coin_cost() -> Bool:
    let workshop = make_building( BuildingType::workshop )
    return workshop.building_type.coin_cost() == 2 

fun test_tool_cost() -> Bool:
    let workshop = make_building( BuildingType::workshop )
    return workshop.building_type.tool_cost() == 1

    
        
