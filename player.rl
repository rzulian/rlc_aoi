import collections.vector
import bounded_arg
import range
import serialization.print

import building

using BuildingArgType = BInt<0, 18>
# using NUM_WORKSHOPS = 9
# using NUM_GUILDS = 4
# using NUM_SCHOOLS = 3

cls Player:
    BInt<0,50> tools
    BInt<0,50> coins
    BInt<0,10> workshops
    BInt<0,5> guilds
    BInt<0,4> schools
    BInt<0,2> palaces
    BInt<0,2> universities


    BoundedVector<Building, 18> buildings
   
    fun score() -> Float:
        let score = 0.0
        score = float(self.coins.value) * 1.0 + float(self.tools.value) * 3.0
        return score

    fun update_income() -> Void:
        let coin_income = [0,2,4,6,8]
        let tool_income = [1,2,3,4,5,5,6,7,8,9]
        self.coins = self.coins + coin_income[ 4 - self.guilds.value]
        self.tools = self.tools + tool_income[ 9 - self.workshops.value]

    fun can_pay_building(BuildingType building_type) -> Bool :
        return self.coins >= building_type.coin_cost() and self.tools >= building_type.tool_cost()
    
    fun pay_building(BuildingType building_type) -> Void :
        self.coins = self.coins - building_type.coin_cost()
        self.tools = self.tools - building_type.tool_cost()
         
    fun can_build_workshop() -> Bool :
        return self.workshops.value > 0 and self.can_pay_building( BuildingType::workshop)
    
    fun can_build_guild() -> Bool :
        return self.guilds.value > 0 and self.workshops.value < 9 and self.can_pay_building( BuildingType::guild)

    fun can_build_school() -> Bool :
        return self.schools.value > 0 and self.guilds.value < 4 and self.can_pay_building( BuildingType::school)
    
    fun build_workshop() -> Void :
        self.workshops = self.workshops - 1
        self.pay_building(BuildingType::workshop)

    fun build_free_workshop() -> Void :
        self.workshops = self.workshops - 1

    fun build_guild() -> Void :
        self.guilds = self.guilds - 1
        self.workshops = self.workshops + 1
        self.pay_building(BuildingType::guild)

    fun build_school() -> Void :
        self.schools = self.schools - 1
        self.guilds = self.guilds + 1
        self.pay_building(BuildingType::school)
        
fun make_player() -> Player:
    let player : Player
    player.coins = 15
    player.tools = 3
    player.workshops = 9
    player.guilds = 4
    player.schools = 3
    return player

fun pretty_print(Player player):
    print(player.coins.value)



fun test_player_coin_income() -> Bool:
    let player = make_player()
    player.build_workshop()
    player.build_guild()
    player.update_income()
    return player.coins == 12

fun test_player_tool_income() -> Bool:
    let player = make_player()
    player.build_workshop()
    player.update_income()
    return player.tools == 4



