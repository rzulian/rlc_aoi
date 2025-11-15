import collections.vector
import bounded_arg
import range
import serialization.print
import math.numeric
import machine_learning

import building
import competency
import city_tile
import palace_tile

using BuildingArgType = BInt<0, 18>
const NUM_WORKSHOPS = 9
const NUM_GUILDS = 4
const NUM_SCHOOLS = 3
const NUM_PALACES = 1
const NUM_UNIVERSITIES = 1
const URP_POWER = 0.7
const URP_COIN = 1.0
const URP_TOOL = 2.5
const URP_SCHOLAR = 4.0
const URP_SPADE = 5.0
const URP_BOOK = 3.5
const URP_SCIENCE_STEP = 2.29
const URP_COMPETENCY_TILE = 10.0
const URP_PALACE = 40.0
const VP_CITY = 13

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
    BoundedVector<CompetencyTileKind, NUM_COMPETENCY_TILES_KIND> competency_tiles
    BoundedVector<CityTileKind, 6> city_tiles
    BInt<0,6> cities
    BInt<0,6> spades
    BInt<0,4> terraforming_track_level
    Int VP
    Float URP
    Float phase_production_URP
    Int coin_income
    Int tool_income
    Int power_income
    Int scholar_income
    Int vp_income
    Int science_step_income
    Int book_income
    Int city_income
    Int competency_tile_income
    Int palace_income
    Float urp_for_vp
    Int send_scholar_vp
    Bool palace_upgrade_to_guild

    BoundedVector<Building, 18> buildings
    BInt<0,14>[NUM_DISCIPLINES] discipline_level
    BInt<0,14>[NUM_DISCIPLINES] books
    PalaceTileKind palace
   
    fun score(Int current_phase) -> Float:
        let urp_for_production = [ 0.0, 3.0, 3.0, 2.6, 2.1, 1.5, 0.83]
        let score = 0.0
        # virtual income for remaining phases
        # print("PHASE=>"s + to_string(current_phase))
        # print(self)

        # phase 0 is setup, 6 phases to complete the game
        score = self.URP + urp_for_production[current_phase] * self.phase_production_URP
        return score

    fun num_buildings() -> Int:
        #one workshop is not in the first cluster
        return self.workshops.value + self.guilds.value + self.schools.value + self.palaces.value + self.universities.value - 1 
    
    fun power_buildings() -> Int:
        return self.workshops.value *BuildingType::workshop.power() + self.guilds.value*BuildingType::guild.power() + self.schools.value*BuildingType::school.power()+ self.palaces.value*BuildingType::palace.power() + self.universities.value*BuildingType::university.power()

    fun update_cities() -> Void:
        let cities = 0

        let power_buildings = self.power_buildings()
        let num_buildings_cluster1 = self.num_buildings()
        let power_buildings_cluster1 = power_buildings - BuildingType::workshop.power()
        let has_one_city = power_buildings_cluster1 >= 7 and ( num_buildings_cluster1>= 4 or (num_buildings_cluster1==3 and self.universities.value==1)) 
        let has_two_cities = power_buildings  >= 14 and ( num_buildings_cluster1 +1 >= 8 or (num_buildings_cluster1 + 1 >=7 and self.universities.value==1))
        if has_one_city:
            cities = 1
        if has_two_cities:
            cities = 2
        self.city_income = cities - self.cities.value
        self.cities.value = cities


    fun has_income_phase() -> Bool:
        # player can decide to advance a science_step or gain a book
        return (self.science_step_income + self.book_income) > 0

    fun has_end_round_phase() -> Bool:
        # player can decide to gain a book
        return (self.book_income) > 0

    fun has_build_phase() -> Bool:
        # player can decide to get a competency tile, get a city tile, or palace tile
        return (self.city_income + self.competency_tile_income + self.palace_income) > 0

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

    fun pay_scholar( Int num_scholars): 
        self.scholars_on_hand = self.scholars_on_hand - num_scholars
        self.scholars = self.scholars + num_scholars

    fun return_scholar( Int num_scholars):
        self.pay_scholar(num_scholars)
        self.gain_vp(self.send_scholar_vp)

    fun send_scholar( Int num_scholars):
        self.scholars_on_hand = self.scholars_on_hand - num_scholars
        self.gain_vp(self.send_scholar_vp)

    fun gain_book( Discipline discipline, Int num_books):
        self.books[discipline.value] = self.books[discipline.value] + num_books

    fun gain_power(Int power):
        let to_bowl2 = min( power, self.powers[0].value )
        self.powers[0] = self.powers[0] - to_bowl2
        self.powers[1] = self.powers[1] + to_bowl2
        let power3 = power - to_bowl2
        let to_bowl3 = min( power3, self.powers[1].value )
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

    fun gain_science_step(Int num_steps):
        # no need for this, science steps are fully implemented self.URP = self.URP + float(num_steps)*URP_SCIENCE_STEP
        return

    fun gain_spade( Int num_spades):
        self.spades = self.spades + num_spades

    fun gain_vp( Int VP ):
        #converts VPs into equivalent URPs
        self.VP = self.VP + VP
        self.URP = self.URP + self.urp_for_vp*float(VP)

    fun can_pay_building(BuildingType building_type) -> Bool :
        return self.coins >= building_type.coin_cost() and self.tools >= building_type.tool_cost()

    fun pay_building(BuildingType building_type) -> Void :
        self.pay_coin( building_type.coin_cost() )
        self.pay_tool( building_type.tool_cost() )
        
    fun spades_needed() -> Int:
        let cluster_spades = [0,1,2,1,2,1,2]
        return cluster_spades[self.num_buildings()]      

    fun can_build_workshop() -> Bool :
        return self.workshops < NUM_WORKSHOPS and self.can_pay_building( BuildingType::workshop) and self.spades >= self.spades_needed()
    
    fun can_build_guild() -> Bool :
        return self.guilds < NUM_GUILDS and self.workshops > 0 and self.can_pay_building( BuildingType::guild)

    fun can_build_school() -> Bool :
        return self.schools < NUM_SCHOOLS and self.guilds > 0 and self.can_pay_building( BuildingType::school)

    fun can_build_palace() -> Bool :
        return self.palaces < NUM_PALACES and self.guilds > 0 and self.can_pay_building( BuildingType::palace)

    fun can_build_university() -> Bool :
        return self.universities< NUM_UNIVERSITIES and self.schools > 0 and self.can_pay_building( BuildingType::university)
    
    fun build_workshop() -> Void :
        #considering spade costs
        self.spades = self.spades - self.spades_needed()
        self.workshops = self.workshops + 1
        self.pay_building(BuildingType::workshop)
        self.update_cities()

    fun build_free_workshop() -> Void :
        self.workshops = self.workshops + 1

    fun build_guild() -> Void :
        self.guilds = self.guilds + 1
        self.workshops = self.workshops - 1
        self.pay_building(BuildingType::guild)
        self.update_cities()

    fun build_free_guild() -> Void :
        self.guilds = self.guilds + 1
        self.workshops = self.workshops - 1
        self.update_cities()

    fun build_school() -> Void :
        self.schools = self.schools + 1
        self.guilds = self.guilds - 1
        self.pay_building(BuildingType::school)
        self.competency_tile_income = self.competency_tile_income + 1
        self.update_cities()
    
    fun build_palace() -> Void :
        self.palaces = self.palaces + 1
        self.guilds = self.guilds - 1
        self.pay_building(BuildingType::palace)
        self.palace_income = 1
        self.update_cities()

    fun build_university() -> Void :
        self.universities = self.universities + 1
        self.schools = self.schools - 1
        self.pay_building(BuildingType::university)
        self.competency_tile_income = self.competency_tile_income + 1
        self.update_cities()

    fun convert_scholars_to_tools( Int num_scholars) -> Void :
        self.gain_scholar( -1*num_scholars)
        self.gain_tool( num_scholars )
        
    fun convert_tools_to_coins( Int num_tools) -> Void :
        self.pay_tool( num_tools )
        self.gain_coin( num_tools )

    fun convert_tools_to_spades( Int num_spades) -> Void :
        self.pay_tool( num_spades * self.terraforming_cost() )
        self.gain_spade( num_spades )

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
        self.gain_spade( num_spades )

    fun terraforming_cost() -> Int:
        # track level 1 -> 3 tools
        return 4 - self.terraforming_track_level.value

    fun can_get_competency_tile(CompetencyTileKind kind) -> Bool:
        # check if the player has already the tile
        for comp_tile_kind in self.competency_tiles:
            if comp_tile_kind == kind:
                return false
        return true

    fun get_competency_tile( CompetencyTileKind kind ) -> Void:
        self.competency_tiles.append(kind)
        if kind == CompetencyTileKind::spades2:
            self.gain_spade(2)
        else if kind == CompetencyTileKind::tool_coins2_vp5:
            self.gain_coin(2)
            self.gain_tool(1)
            self.gain_vp(5)
        else if kind == CompetencyTileKind::send_scholar_vp:
            self.send_scholar_vp = 2

    fun get_competency_tile_round_bonus() -> Void:
        for tile in self.competency_tiles:
            if tile == CompetencyTileKind::tool_science_adv:
                self.tool_income = self.tool_income + 1
                self.science_step_income = self.science_step_income + 1
                continue
            if tile == CompetencyTileKind::book_power:
                self.book_income = self.book_income + 1
                self.power_income = self.power_income + 1
                continue
            if tile == CompetencyTileKind::coins2_vp3:
                self.coin_income = self.coin_income + 2
                self.vp_income = self.vp_income + 3
                continue

    fun get_competency_tile_pass_bonus() -> Void:
        for tile in self.competency_tiles:
            if tile == CompetencyTileKind::lowest_science_vp:
                let min_level = min(min(min(self.discipline_level[0],self.discipline_level[1]), self.discipline_level[2]),self.discipline_level[3])
                self.gain_vp( min_level.value )
                continue
            if tile == CompetencyTileKind::city_vp:
                self.gain_vp( self.cities.value * 2 )
                continue


    fun get_city_tile(CityTiles city_tiles, CityTileKind kind):
        # TODO get discipline
        city_tiles.draw_city_tile(kind)
        self.city_tiles.append(kind)

        self.gain_vp(kind.bonus()[0])
        self.gain_tool(kind.bonus()[1])
        self.gain_coin(kind.bonus()[2])
        self.gain_power(kind.bonus()[3])
        self.gain_scholar(kind.bonus()[4])
        self.book_income = self.book_income + kind.bonus()[5]
        self.gain_spade(kind.bonus()[6])

    fun get_palace_tile(PalaceTiles palace_tiles, PalaceTileKind kind):
        palace_tiles.draw_palace_tile(kind)
        self.palace = kind
        if kind == PalaceTileKind::power2_vp10:
            self.gain_vp(10)
        else if kind == PalaceTileKind::power2_upgrade_to_guild:
            self.palace_upgrade_to_guild = true

    fun get_palace_tile_round_bonus():
        if  self.palace== PalaceTileKind::power2_upgrade_to_guild:
            self.power_income = self.power_income + 2
            self.palace_upgrade_to_guild = true

    fun get_palace_tile_pass_bonus():
        return

    fun can_upgrade_terraforming() -> Bool:
        return self.scholars_on_hand>0 and self.coins>=5 and self.tools>=1 and self.terraforming_track_level <= 2

    fun upgrade_terraforming() -> Void:
        self.pay_scholar( 1 )
        self.pay_tool( 1 )
        self.pay_coin( 5 )
        self.terraforming_track_level = self.terraforming_track_level + 1
        if self.terraforming_track_level == 1:
            self.book_income = self.book_income + 2
        if self.terraforming_track_level == 2:
            self.gain_vp(6)

    fun update_income() -> Void:
        # beginning of a new phase. get new production from building, competency tile,
        let tool_income_by_workshops = [1,2,3,4,5,5,6,7,8,9]
        let coin_income_by_guilds = [0,2,4,6,8]
        let power_income_by_guilds = [0,1,2,4,6]

        self.tool_income = tool_income_by_workshops[ self.workshops.value ]
        self.coin_income = coin_income_by_guilds[ self.guilds.value ]
        self.power_income = power_income_by_guilds[ self.guilds.value ]
        self.scholar_income = min( self.schools.value + self.universities.value , self.scholars.value)
        self.vp_income = 0
        self.science_step_income = 0
        self.book_income = 0

        self.get_competency_tile_round_bonus()
        self.get_palace_tile_round_bonus()

        #scenario 11 power bonus on every phase
        self.power_income = self.power_income + 6
        self.vp_income = self.vp_income - 3

        self.gain_coin(self.coin_income)
        self.gain_tool(self.tool_income)
        self.gain_power(self.power_income)
        self.gain_scholar(self.scholar_income)
        self.gain_vp(self.vp_income)

        self.phase_production_URP = float(self.power_income) * URP_POWER + float(self.coin_income) * URP_COIN + float(self.tool_income) * URP_TOOL + float(self.scholar_income) * URP_SCHOLAR


fun make_player() -> Player:
    let player : Player
    player.coins = 15
    player.tools = 5
    player.powers[0] = 5
    player.powers[1] = 7
    player.powers[2] = 0
    
    player.scholars = 7
    player.scholars_on_hand = 0
    player.workshops = 0
    player.guilds = 0
    player.schools = 0
    player.universities = 0
    player.palaces = 0
    player.VP = 0
    player.URP = 0.0
    player.phase_production_URP = 0.0
    player.cities = 0
    player.spades = 0
    player.science_step_income = 0
    player.city_income = 0
    player.competency_tile_income = 0
    player.palace_income = 0
    player.palace_upgrade_to_guild = false

    player.terraforming_track_level = 1
    for i in range(4):
        player.discipline_level[i] = 0
        player.books[i] = 0
    return player

fun pretty_print(Player player):
    print_indented(player)

fun test_player_coin_income() -> Bool:
    let player = make_player()
    player.build_free_workshop()
    player.build_guild()
    player.update_income()
    return player.coins == 14

fun test_player_tool_income() -> Bool:
    let player = make_player()
    let tools = player.tools
    player.build_free_workshop()
    player.update_income()
    return player.tools == tools + 2

fun test_player_gain_power() -> Bool:
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

fun test_player_scholar_income() -> Bool:
    let player = make_player()
    let scholars = player.scholars
    player.build_free_workshop()
    player.build_guild()
    player.build_school()
    player.update_income()
    assert( player.scholars == scholars - 1 and player.scholars_on_hand == 1, "new scholar")
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

fun test_urp_for_production() -> Bool:
    # 1 workshop, 1 guild, 1 school -> 2 tool, 2 coins, 1 power, 1 scholar
    # + 6power from standard gain
    let player = make_player()
    player.build_free_workshop()
    player.build_free_workshop()
    player.build_workshop()
    player.build_guild()
    player.build_guild()
    player.build_school()
    player.update_income()
    return int( (player.score(1) - player.URP) * 100.0) == int(47.7 * 100.0)