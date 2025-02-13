import collections.vector
import bounded_arg
import range
import serialization.print
import math.numeric

import building

using BuildingArgType = BInt<0, 18>
const NUM_WORKSHOPS = 9
const NUM_GUILDS = 4
const NUM_SCHOOLS = 3
const URP_SPADES = 3.75
const URP_BOOKS = 3.50
const URP_SCIENCE_STEP = 2.29

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
    BInt<0,6> cities
    BInt<0,6> spades
    BInt<0,4> terraformig_track_level
    Float URP
    Float last_phase_URP

    BoundedVector<Building, 18> buildings
    BInt<0,14>[4] discipline_level
    BInt<0,14>[4] books
   
    fun score(Int current_phase) -> Float:
        let score = 0.0
        # virtual income for remaining phases
        # print("PHASE=>"s + to_string(current_phase))
        # print(self)

        # phase 0 is setup, 6 phases to complete the game
        score = self.URP + self.last_phase_URP * float( 6 - current_phase )
        return score

    fun num_buildings() -> Int:
        let workshops_built = NUM_WORKSHOPS - self.workshops.value
        let guilds_built = NUM_GUILDS - self.guilds.value
        let schools_built = NUM_SCHOOLS - self.schools.value
        let palaces_built = 1 - self.palaces.value
        let universities_built = 1 - self.universities.value

        #one workshop is not in the first cluster
        return workshops_built -1  + guilds_built + schools_built + palaces_built + universities_built

    fun update_income() -> Void:
        let tool_income_by_workshops = [1,2,3,4,5,5,6,7,8,9]
        let coin_income_by_guilds = [0,2,4,6,8]
        let power_income_by_guilds = [0,1,2,4,6]

        let workshops_built = NUM_WORKSHOPS - self.workshops.value
        let guilds_built = NUM_GUILDS - self.guilds.value
        let schools_built = NUM_SCHOOLS - self.schools.value
        let palaces_built = 1 - self.palaces.value
        let universities_built = 1 - self.universities.value

        #one workshop is not in the first cluster
        let num_buildings = workshops_built + guilds_built + schools_built + palaces_built + universities_built
        let num_buildings_cluster1 = num_buildings - 1
        let power_buildings = workshops_built *BuildingType::workshop.power() + guilds_built*BuildingType::guild.power() + schools_built*BuildingType::school.power()+ palaces_built*BuildingType::palace.power() + universities_built*BuildingType::university.power()
        let power_buildings_cluster1 = power_buildings - BuildingType::workshop.power()
        let has_one_city = power_buildings_cluster1 >= 7 and ( num_buildings_cluster1>= 4 or (num_buildings_cluster1==3 and universities_built==1)) 
        let has_two_cities = power_buildings  >= 14 and ( num_buildings>= 8 or (num_buildings>=7 and universities_built==1))
        let cities = 0
        if has_one_city:
            cities = 1
        if has_two_cities:
            cities = 2 

        let tool_income = tool_income_by_workshops[ workshops_built ]
        let coin_income = coin_income_by_guilds[ guilds_built ]
        let power_income = power_income_by_guilds[ guilds_built ]
        let scholar_income = min( (schools_built) + (universities_built), self.scholars.value)

        self.coins = self.coins + coin_income
        self.tools = self.tools + tool_income
        self.gain_power(power_income)
        self.gain_scholar(scholar_income)

        
        let URP_competency_tile = float(self.competency_tiles.value) * 25.0 / 5.0
        let URP_palace_tile = float( palaces_built ) * 40.0 / 5.0

        # add city URp only for new founded cities
        self.URP = self.URP + float(cities - self.cities.value) * 13.0
        self.cities = cities

        self.last_phase_URP = float(power_income) * 0.5 + float(coin_income) * 1.0 + float(tool_income) * 3.0 + float(scholar_income) * 3.75 + URP_competency_tile + URP_palace_tile
        self.URP = self.URP + self.last_phase_URP

    fun gain_tool( Int num_tools):
        self.tools = self.tools + num_tools
    
    fun pay_tool( Int num_tools):
        self.tools = self.tools - num_tools

    fun gain_coin( Int num_coins):
        self.coins = self.coins + num_coins
    
    fun pay_coin( Int num_coins):
        self.coins = self.coins - num_coins

    fun gain_scholar( Int num_scholars):
        self.scholars_on_hand = self.scholars_on_hand + num_scholars
        self.scholars = self.scholars - num_scholars

    fun gain_book( Int discipline_id, Int num_books):
        self.books[discipline_id] = self.books[discipline_id] + num_books
        self.URP = self.URP + float(num_books)*URP_BOOKS

    fun gain_power(Int power):
        let to_bowl2 = min( power, self.powers[0].value )
        self.powers[0] = self.powers[0] - to_bowl2
        self.powers[1] = self.powers[1] + to_bowl2
        power = power - to_bowl2
        let to_bowl3 = min( power, self.powers[1].value )
        self.powers[1] = self.powers[1] - to_bowl3
        self.powers[2] = self.powers[2] + to_bowl3

    fun use_power(Int power):
        let power_bowl2 = min( power, self.powers[2].value )
        let power_bowl1 = (power - power_bowl2) * 2
        self.powers[2] = self.powers[2] - power_bowl2
        self.powers[1] = self.powers[1] - power_bowl1
        self.powers[0] = self.powers[0] + power

    fun sacrifice_power(Int power):
        self.powers[1] = self.powers[1] - 2*power
        self.powers[2] = self.powers[2] + power

    fun has_power(Int power) -> Bool:
        return self.powers[2] + self.powers[1].value / 2  >= power

    fun can_pay_building(BuildingType building_type) -> Bool :
        return self.coins >= building_type.coin_cost() and self.tools >= building_type.tool_cost()
    
    fun pay_building(BuildingType building_type) -> Void :
        self.pay_coin( building_type.coin_cost() )
        self.pay_tool( building_type.tool_cost() )

    fun spades_needed() -> Int:
        let cluster_spades = [0,1,1,2,2,3,3]
        return cluster_spades[self.num_buildings()]      
         
    fun can_build_workshop() -> Bool :
        return self.workshops > 0 and self.can_pay_building( BuildingType::workshop) and self.spades >= self.spades_needed()
    
    fun can_build_guild() -> Bool :
        return self.guilds > 0 and self.workshops < NUM_WORKSHOPS and self.can_pay_building( BuildingType::guild)

    fun can_build_school() -> Bool :
        return self.schools > 0 and self.guilds < NUM_GUILDS and self.can_pay_building( BuildingType::school)

    fun can_build_palace() -> Bool :
        return self.palaces > 0 and self.guilds < NUM_GUILDS and self.can_pay_building( BuildingType::palace)

    fun can_build_university() -> Bool :
        return self.universities > 0 and self.schools < NUM_SCHOOLS and self.can_pay_building( BuildingType::university)
    
    fun build_workshop() -> Void :
        #considering spade costs
        self.spades = self.spades - self.spades_needed()
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
    
    fun build_palace() -> Void :
        self.palaces = self.palaces - 1
        self.guilds = self.guilds + 1
        self.pay_building(BuildingType::palace)

    fun build_university() -> Void :
        self.universities = self.universities - 1
        self.schools = self.schools + 1
        self.pay_building(BuildingType::university)

    fun convert_scholars_to_tools( Int num_scholars) -> Void :
        self.gain_scholar( -1*num_scholars)
        self.gain_tool( num_scholars )
        
    fun convert_tools_to_coins( Int num_tools) -> Void :
        self.pay_tool( num_tools )
        self.gain_coin( num_tools )

    fun convert_tools_to_spades( Int num_spades) -> Void :
        self.pay_tool( num_spades * self.terraforming_cost() )
        self.spades = self.spades + num_spades

    fun convert_power_to_coins( Int num_power, Int num_coins) -> Void :
        self.use_power( num_power )
        self.gain_coin( num_coins )

    fun convert_power_to_tools(Int num_power, Int num_tools) -> Void :
        self.use_power( num_power )
        self.gain_tool( num_tools )

    fun convert_power_to_scholars( Int num_power, Int num_scholars) -> Void :
        self.use_power( num_power )
        self.gain_scholar( num_scholars )

    fun convert_power_to_spades( Int num_power, Int num_spades) -> Void :
        self.use_power( num_power )
        self.spades = self.spades + num_spades

    fun terraforming_cost() -> Int:
        # track level 1 -> 3 tools
        return 4 - self.terraformig_track_level.value

    fun can_get_competency_tile( Int discipline_id, Int level) -> Bool:
        #TODO check if player has already this competency tile
        return true

    fun get_competency_tile( Int discipline_id, Int level) -> Void:
        #TODO add the correct competency tile

        self.competency_tiles = self.competency_tiles + 1
        self.books[discipline_id] = self.books[discipline_id] + (2-level)
        self.gain_book(discipline_id, 2-level)

    fun can_upgrade_terraforming() -> Bool:
        return self.scholars_on_hand>0 and self.coins>=5 and self.tools>=1

    fun upgrade_terraforming() -> Void:
        self.scholars_on_hand = self.scholars_on_hand - 1
        self.pay_tool( 1 )
        self.coins = self.coins - 5
        self.terraformig_track_level = self.terraformig_track_level + 1
        if self.terraformig_track_level == 1:
            #TODO action for books
            self.gain_book(0, 2)
        if self.terraformig_track_level == 2:
            self.URP = self.URP + 6.0
            



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
    player.cities = 0
    player.spades = 0
    player.terraformig_track_level = 1 
    for i in range(4):
        player.discipline_level[i] = 0
        player.books[i] = 0
    return player

fun pretty_print(Player player):
    print(player.coins.value)

fun test_player_coin_income() -> Bool:
    let player = make_player()
    player.build_free_workshop()
    player.build_guild()
    player.update_income()
    return player.coins == 14

fun test_player_tool_income() -> Bool:
    let player = make_player()
    player.build_free_workshop()
    player.update_income()
    return player.tools == 5

fun test_gain_power() -> Bool:
    let player = make_player()
    player.powers[0] = 5
    player.powers[1] = 7
    
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
    player.convert_power_to_scholars(5,1)
    assert( player.powers[0] == 5 and player.powers[1] == 1 and player.powers[2] == 1 and player.scholars == 6 and player.scholars_on_hand == 1, "5power scholar")
    player.convert_power_to_coins(1, 1)
    assert( player.powers[0] == 6 and player.powers[1] == 1 and player.powers[2] == 0 and player.coins == 16 , "power to coin")
   
    return true

fun test_city_palace() -> Bool:
    let player = make_player()
    player.coins = 20
    player.tools = 20
    player.build_free_workshop()
    player.build_free_workshop()
    player.build_workshop()
    player.build_workshop()
    player.build_workshop()
    player.build_guild()
    player.build_guild()
    player.build_palace()
    player.update_income()
    return player.cities == 1

fun test_city_university() -> Bool:
    let player = make_player()
    player.coins = 20
    player.tools = 20
    player.build_free_workshop()
    player.build_free_workshop()
    player.build_workshop()
    player.build_workshop()
    player.build_guild()
    player.build_guild()
    player.build_guild()
    player.build_university()
    player.update_income()
    return player.cities == 1