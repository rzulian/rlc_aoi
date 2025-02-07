import collections.vector
import bounded_arg
import range
import serialization.print

import building

using BuildingArgType = BInt<0, 18>
const NUM_WORKSHOPS = 9
const NUM_GUILDS = 4
const NUM_SCHOOLS = 3

cls Player:
    BInt<0,50> tools
    BInt<0,50> coins
    BInt<0,14>[3] powers
    BInt<0,10> workshops
    BInt<0,5> guilds
    BInt<0,4> schools
    BInt<0,2> palaces
    BInt<0,2> universities
    BInt<0,8> scholars
    BInt<0,8> scholars_on_hand
    BInt<0,10> competency_tiles
    Float URP
    Float last_phase_URP

    BoundedVector<Building, 18> buildings
   
    fun score(Int current_phase) -> Float:
        let score = 0.0
        # virtual income for remaining phases
        score = self.URP + self.last_phase_URP * float( 6 - current_phase )
        return score

    fun update_income() -> Void:
        let tool_income_by_workshops = [1,2,3,4,5,5,6,7,8,9]
        let coin_income_by_guilds = [0,2,4,6,8]
        let power_income_by_guilds = [0,1,2,4,6]

        let tool_income = tool_income_by_workshops[ NUM_WORKSHOPS - self.workshops.value]
        let coin_income = coin_income_by_guilds[ NUM_GUILDS - self.guilds.value]
        let power_income = power_income_by_guilds[ NUM_GUILDS - self.guilds.value]
        let scholar_income = min( (NUM_SCHOOLS - self.schools.value) + (1- self.universities.value), self.scholars.value)

        self.coins = self.coins + coin_income
        self.tools = self.tools + tool_income
        self.gain_power(power_income)
        self.gain_scholar(scholar_income)
        
        let URP_competency_tile = float(self.competency_tiles.value) * 25.0 / 5.0
        let URP_palace_tile = float( 1 - self.palaces.value ) * 40.0 / 5.0

        self.last_phase_URP = float(power_income) * 0.5 + float(coin_income) * 1.0 + float(tool_income) * 3.0 + float(scholar_income) * 3.75 + URP_competency_tile + URP_palace_tile
        self.URP = self.URP + self.last_phase_URP

    fun gain_scholar( Int num_scholars):
        self.scholars_on_hand = self.scholars_on_hand + num_scholars
        self.scholars = self.scholars - num_scholars

    fun gain_power(Int power):
        let to_bowl2 = min( power, self.powers[0].value )
        self.powers[0] = self.powers[0] - to_bowl2
        self.powers[1] = self.powers[1] + to_bowl2
        power = power - to_bowl2
        let to_bowl3 = min( power, self.powers[1].value )
        self.powers[1] = self.powers[1] - to_bowl3
        self.powers[2] = self.powers[2] + to_bowl3

    fun use_power(Int power):
        self.powers[2] = self.powers[2] - power
        self.powers[0] = self.powers[0] + power

    fun sacrifice_power(Int power):
        self.powers[1] = self.powers[1] - 2*power
        self.powers[2] = self.powers[2] + power

    fun can_pay_building(BuildingType building_type) -> Bool :
        return self.coins >= building_type.coin_cost() and self.tools >= building_type.tool_cost()
    
    fun pay_building(BuildingType building_type) -> Void :
        self.coins = self.coins - building_type.coin_cost()
        self.tools = self.tools - building_type.tool_cost()
         
    fun can_build_workshop() -> Bool :
        return self.workshops > 0 and self.can_pay_building( BuildingType::workshop)
    
    fun can_build_guild() -> Bool :
        return self.guilds > 0 and self.workshops < NUM_WORKSHOPS and self.can_pay_building( BuildingType::guild)

    fun can_build_school() -> Bool :
        return self.schools > 0 and self.guilds < NUM_GUILDS and self.can_pay_building( BuildingType::school)

    fun can_build_palace() -> Bool :
        return self.palaces > 0 and self.guilds < NUM_GUILDS and self.can_pay_building( BuildingType::palace)

    fun can_build_university() -> Bool :
        return self.universities > 0 and self.schools < NUM_SCHOOLS and self.can_pay_building( BuildingType::university)
    
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
        self.competency_tiles = self.competency_tiles + 1 
        self.guilds = self.guilds + 1
        self.pay_building(BuildingType::school)
    
    fun build_palace() -> Void :
        self.palaces = self.palaces - 1
        self.guilds = self.guilds + 1
        self.pay_building(BuildingType::palace)

    fun build_university() -> Void :
        self.universities = self.universities - 1
        self.competency_tiles = self.competency_tiles + 1 
        self.schools = self.schools + 1
        self.pay_building(BuildingType::university)

    fun convert_scholars_to_tools( Int num_scholars) -> Void :
        self.gain_scholar( -1*num_scholars)
        self.tools = self.tools + num_scholars
        
    fun convert_tools_to_coins( Int num_tools) -> Void :
        self.tools = self.tools - num_tools
        self.coins = self.coins + num_tools

    fun convert_power_to_coins( Int num_power) -> Void :
        self.use_power( num_power )
        self.coins = self.coins + num_power

    fun convert_3power_to_tool() -> Void :
        self.use_power( 3)
        self.tools = self.tools + 1

    fun convert_5power_to_scholar( ) -> Void :
        self.use_power( 5 )
        self.gain_scholar( 1 )


fun make_player() -> Player:
    let player : Player
    player.coins = 15
    player.tools = 3
    player.powers[0] = 5
    player.powers[1] = 7
    player.powers[2] = 0
    
    player.scholars = 7
    player.scholars_on_hand = 0
    player.workshops = NUM_WORKSHOPS
    player.guilds = NUM_GUILDS
    player.schools = NUM_SCHOOLS
    player.universities = 1
    player.palaces = 1
    player.competency_tiles = 0
    player.URP = 0.0
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

fun test_gain_power() -> Bool:
    let player = make_player()
    player.gain_power(3)
    assert( player.powers[0] == 2 and player.powers[1] == 10 and player.powers[2] == 0, "gain power bowl1->2")
    player.gain_power(2)
    assert( player.powers[0] == 0 and player.powers[1] == 12 and player.powers[2] == 0, "gain additional power bowl1-2 ")
    player.gain_power(5)
    assert( player.powers[0] == 0 and player.powers[1] == 7 and player.powers[2] == 5, "gain power bowl2->3")
    player.gain_power(10)
    assert( player.powers[0] == 0 and player.powers[1] == 0 and player.powers[2] == 12 , "gain more power than available")
    return true

fun test_convert_power() -> Bool:
    let player = make_player()
    player.powers[0] = 0
    player.powers[1] = 13
    player.powers[2] = 0
    player.sacrifice_power(6)
    assert( player.powers[0] == 0 and player.powers[1] == 1 and player.powers[2] == 6, "sacrifice")
    player.convert_5power_to_scholar()
    assert( player.powers[0] == 5 and player.powers[1] == 1 and player.powers[2] == 1 and player.scholars == 6 and player.scholars_on_hand == 1, "5power scholar")
    player.convert_power_to_coins(1)
    assert( player.powers[0] == 6 and player.powers[1] == 1 and player.powers[2] == 0 and player.coins == 16 , "power to coin")
   
    return true
