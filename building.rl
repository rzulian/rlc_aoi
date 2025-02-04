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
        if self.is_builded:
            return incomes[self.building_type.value]
        return 0




fun test_coin_cost() -> Bool:
    let workshop : Building
    workshop.building_type = BuildingType::workshop
    workshop.is_builded = false

    return workshop.coin_cost() == 2 

fun test_coin_income() -> Bool:
    let guild : Building
    guild.building_type = BuildingType::guild
    guild.is_builded = true

    return guild.coin_income() == 2 

    
        
