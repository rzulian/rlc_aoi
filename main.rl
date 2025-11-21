import collections.vector
import serialization.to_byte_vector
import serialization.print
import math.numeric
import player
import state
import none
import machine_learning

const NUM_PLAYERS = 1

fun do_move_advance_discipline(State state, Player player, Discipline discipline, Int num_levels) -> Void:
    let starting_level =  player.discipline_level[discipline.value].value
    let power = state.discipline_tracks[discipline].power_from_track( starting_level, num_levels)
    let new_level = state.discipline_tracks[discipline].next_level( starting_level, num_levels)
    player.gain_power( power )
    player.discipline_level[discipline.value] = new_level
    player.gain_vp((new_level-starting_level) * state.get_round_score_bonus(Action::science_step))

fun do_move_get_competency_tile(State state, Player player, CompetencyTileKind kind) -> Void:
    player.get_competency_tile( kind )
    state.competency_tiles[kind].draw_competency_tile()
    let num_levels =  state.competency_tiles[kind].num_levels()
    let num_books =  state.competency_tiles[kind].num_books()
    do_move_advance_discipline( state, player, state.competency_tiles[kind].discipline, num_levels)
    player.gain_book(state.competency_tiles[kind].discipline, num_books)

fun do_move_get_round_score_tile_bonus(State state, Player player, RoundScoreTileKind round_score_tile ) -> Void:
    let level = player.discipline_level[round_score_tile.discipline().value]
    let multiplier = level.value / round_score_tile.steps()
    player.gain_tool(multiplier*round_score_tile.end_round_bonus(Resource::tool))
    player.gain_coin(multiplier*round_score_tile.end_round_bonus(Resource::coin))
    player.gain_power(multiplier*round_score_tile.end_round_bonus(Resource::power))
    player.gain_scholar(multiplier*round_score_tile.end_round_bonus(Resource::scholar))
    player.book_income = player.book_income + multiplier*round_score_tile.end_round_bonus(Resource::book)
    player.gain_spade(multiplier*round_score_tile.end_round_bonus(Resource::spade))

act income_phase(ctx State state, ctx Player player) -> IncomePhase:
    while player.has_income_phase():
        actions:
            act advance_science_step(Discipline discipline){player.science_step_income > 0 }
                do_move_advance_discipline( state, player, discipline, 1)
                player.science_step_income = player.science_step_income - 1
            act gain_book(Discipline discipline){player.book_income > 0 }
                player.gain_book(discipline, 1)
                player.book_income = player.book_income - 1

act end_round_phase(ctx State state, ctx Player player) -> EndRoundPhase:
    while player.has_end_round_phase():
        actions:
           act gain_book(Discipline discipline){player.book_income > 0 }
                player.gain_book(discipline, 1)
                player.book_income = player.book_income - 1

act build_phase(ctx State state, ctx Player player) -> BuildPhase:
    # during build phase you can found a city and/or get competency tiles and/or get a palace tile, player decide the order of actions
    while player.has_build_phase():
        actions:
            act get_competency_tile(CompetencyTileKind kind){player.competency_tile_income > 0 and player.can_get_competency_tile(kind)}
                do_move_get_competency_tile(state, player, kind)
                player.competency_tile_income = player.competency_tile_income - 1
            act get_city_tile(CityTileKind city_tile_kind){player.city_income > 0 and state.city_tiles.has_city_tile(city_tile_kind)}
                player.get_city_tile(state.city_tiles, city_tile_kind)
                player.gain_vp(state.get_round_score_bonus(Action::city))
                player.city_income = player.city_income - 1
            act get_palace_tile(PalaceTileKind palace_tile_kind){player.palace_income > 0 and state.palace_tiles.has_palace_tile(palace_tile_kind)}
                player.get_palace_tile(state.palace_tiles, palace_tile_kind)
                player.palace_income = player.palace_income - 1
            act pass_build_phase()
                return


act action_phase(ctx State state, ctx Player player) -> ActionPhase:
    actions:
        act build_workshop() {player.can_build_workshop() }
            player.build_workshop()
            player.gain_vp(state.get_round_score_bonus(Action::workshop))
            #TODO workshop on border
            subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
            return
        act build_guild() {player.can_build_guild()}
            player.build_guild()
            player.gain_vp(state.get_round_score_bonus(Action::guild))
            subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
            return
        act free_upgrade_to_guild() {player.palace_upgrade_to_guild}
            player.build_free_guild()
            player.palace_upgrade_to_guild = false
            player.gain_vp(state.get_round_score_bonus(Action::guild))
            subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
            return
        act build_school() {player.can_build_school() }
            player.build_school()
            player.gain_vp(state.get_round_score_bonus(Action::school))
            subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
            return
        act build_palace() {player.can_build_palace() }
            player.build_palace()
            player.gain_vp(state.get_round_score_bonus(Action::big))
            subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
            return
        act build_university() {player.can_build_university() }
            player.build_university()
            player.gain_vp(state.get_round_score_bonus(Action::big))
            subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
            return

        act convert_scholars_to_tools(BInt<1, 20> num_scholars) {player.scholars_on_hand.value >= num_scholars.value }
            player.convert_scholars_to_tools( num_scholars.value )
        act convert_tools_to_coins(BInt<1, 20> num_tools) {player.tools.value >= num_tools.value}
            player.convert_tools_to_coins( num_tools.value )

        act convert_tools_to_spades(BInt<1, 4> num_spades) {player.tools.value >= num_spades.value * player.terraforming_cost() }
            player.convert_tools_to_spades( num_spades.value )

        act convert_power_to_coins(BInt<1, 20> num_power) {player.has_power(num_power.value) }
            player.convert_power_to_coins( num_power.value , num_power.value )
        act convert_3power_to_tool() {player.has_power(3) }
            player.convert_power_to_tools( 3 , 1)
        act convert_5power_to_scholar() {player.scholars.value > 0, player.has_power(5) }
            player.convert_power_to_scholars( 5 , 1)

        act sacrifice_power(BInt<1, 20> num_power) {player.powers[1].value >= num_power.value*2}
            player.sacrifice_power( num_power.value )

        act power_action_7coins(){state.power_action_7coins, player.has_power(4)  }
            state.power_action_7coins = false
            player.convert_power_to_coins( 4, 7 )
            return
        act power_action_2tools(){ state.power_action_2tools, player.has_power(4)  }
            state.power_action_2tools = false
            player.convert_power_to_tools( 4, 2 )
            return
        act power_action_scholar(){ state.power_action_scholar, player.scholars.value > 0,  player.has_power(3)  }
            state.power_action_scholar = false
            player.convert_power_to_scholars( 3, 1 )
            return
        act power_action_1spade(){ player.has_power(4)  }
            state.power_action_1spade = false
            player.convert_power_to_spades( 4, 1 )
            return
        act power_action_2spades(){ player.has_power(6)  }
            state.power_action_2spades = false
            player.convert_power_to_spades( 6, 2 )
            return

        act send_scholar(Discipline discipline){player.scholars_on_hand.value > 0 and state.discipline_tracks[discipline].can_send_scholar() }
            let num_levels = state.discipline_tracks[discipline].steps_for_send_scholar()
            do_move_advance_discipline(state, player, discipline, num_levels)
            player.send_scholar(1)
            state.discipline_tracks[discipline].send_scholar()
            return

        act return_scholar(Discipline discipline){player.scholars_on_hand.value > 0 }
            do_move_advance_discipline(state, player, discipline, 1)
            player.return_scholar(1)
            return

        act upgrade_terraforming(){player.can_upgrade_terraforming()}
            player.upgrade_terraforming()
            player.gain_vp(state.get_round_score_bonus(Action::sailing_terraforming))
            # if books income
            subaction*(state, state.get_current_player() ) player_frame = income_phase(state , state.get_current_player())
            return

        act pass_turn()
            player.has_passed = true
            return





@classes
act play(Int num_players, Scenario scenario) -> Game:

    frm state : State
    state.setup_game(num_players, scenario)

    #player get initial round bonus tile

    state.reset_turn_order()
    while state.turn_has_players():
        act get_round_bonus_tile(RoundBonusTileKind kind){state.round_bonus_tiles[kind].available and state.round_bonus_tiles[kind].in_play}
            state.get_current_player().get_round_bonus_tile(state.round_bonus_tiles, kind)
        state.player_passed_turn()

    while state.round<=FINAL_ROUND:
        state.new_round()

        for player in state.players:
            player.update_income()

        state.reset_turn_order()
        while state.turn_has_players():
            subaction*(state, state.get_current_player() ) player_income = income_phase(state , state.get_current_player())
            state.player_passed_turn()

        #TODO update income after level update
        state.reset_turn_order()
        while state.turn_has_players():
            subaction*(state, state.get_current_player() ) player_action = action_phase(state , state.get_current_player())
            if state.get_current_player().has_passed:
                #pass and get a new round bonus tile
                state.get_current_player().get_competency_tile_pass_bonus()
                state.get_current_player().get_palace_tile_pass_bonus()
                state.get_current_player().get_round_bonus_tile_pass_bonus()
                act get_round_bonus_tile(RoundBonusTileKind kind){state.round_bonus_tiles[kind].available and state.round_bonus_tiles[kind].in_play}
                    state.get_current_player().get_round_bonus_tile(state.round_bonus_tiles, kind)
                state.player_passed_turn()
            else:
                state.next_player_turn()

        #get round score tile bonus in pass order
        state.initial_turn_order = state.pass_turn_order
        state.reset_turn_order()

        while state.turn_has_players() and state.round<FINAL_ROUND: #not in the final round
            do_move_get_round_score_tile_bonus(state, state.get_current_player(), state.round_score_display[state.round.value])
            subaction*(state, state.get_current_player() ) player_end_round = end_round_phase(state , state.get_current_player())
            state.player_passed_turn()

        state.round = state.round + 1


fun get_current_player(Game g) -> Int:
    return g.state.current_player.value

fun score(Game g, Int player_id) -> Float:
    return g.state.players[player_id].score(g.state.round.value) / 100.0
    
fun get_num_players() -> Int:
    return NUM_PLAYERS

fun pretty_print(Game g):
    g.state.pretty_print_state()

fun main() -> Int:
    let game = play(1, Scenario::default)
    print(game.state)
    ref player = game.state.players[0]
    game.pass_turn()
    return 0

fun fuzz(Vector<Byte> input):
    let state = play(1, Scenario::default)
    let x : AnyGameAction
    let enumeration = enumerate(x)
    let index = 0
    while index + 8 < input.size() and !state.is_done():
        let num_action : Int
        from_byte_vector(num_action, input, index)
        if num_action < 0:
          num_action = num_action * -1 
        if num_action < 0:
          num_action = 0 

        let executable : Vector<AnyGameAction>
        let i = 0
        #print("VALIDS")
        while i < enumeration.size():
          if can apply(enumeration.get(i), state):
            #print(enumeration.get(i))
            executable.append(enumeration.get(i))
          i = i + 1
        #print("ENDVALIDS")
        #if executable.size() == 0:
        #print("zero valid actions")
        #print(state)
        #return

        #print(executable.get(num_action % executable.size()))
        apply(executable.get(num_action % executable.size()), state)

fun test_game_setup()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    #print(game.state)
    return player.workshops == 2

fun test_game_build_workshop()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    player.powers[2]=12
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.power_action_1spade()
    game.build_workshop()
    return player.workshops == 3 and player.spades==0

fun test_game_build_guild()-> Bool:
    # check also power income
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    player.powers[0] = 1
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.build_guild()
    game.pass_turn()
    return player.guilds == 1 and player.powers[0] == 0
 
fun test_game_build_school()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.build_guild()
    game.build_school()
    return player.schools == 1 and player.guilds == 0

fun test_game_scholar_income()-> Bool:
    let game = play(1, Scenario::sc1)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::neutral_tower)
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::coins)
    return player.scholars_on_hand == 1 and player.scholars == 6

fun test_game_scholar_income_no_scholar()-> Bool:
    let game = play(1, Scenario::sc1)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.state.players[0].scholars=0
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::neutral_tower)
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::coins)
    return player.scholars_on_hand == 0 and player.scholars == 0


fun test_game_build_palace()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    let kind = PalaceTileKind::power2_vp10
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.build_guild()
    game.build_palace()
    assert( player.palaces == 1 and player.guilds == 0, "has palace")
    let VP = player.VP
    game.get_palace_tile(kind)
    assert( player.palace == kind and player.VP == VP+10 and game.state.palace_tiles[kind] == 0, "tile has been draw")
    let power = player.powers[0]
    game.pass_turn()
    assert( player.powers[0] == power -2 , "got 2 power round bonus")
    return true

fun test_game_free_upgrade_to_guild()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    let kind = PalaceTileKind::power2_upgrade_to_guild
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    player.build_free_workshop()
    game.build_guild()
    game.build_palace()
    game.get_palace_tile(kind)
    assert( player.palace == kind and player.palace_upgrade_to_guild and game.state.palace_tiles[kind] == 0, "tile has been draw")
    let coins = player.coins
    let tools = player.tools
    let guilds = player.guilds
    game.free_upgrade_to_guild()
    assert( player.coins == coins and player.tools == tools and player.guilds == guilds + 1, "didnt pay for the guild")
    assert (!player.palace_upgrade_to_guild, "cannot use it again during round")
    game.pass_turn()

    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    assert (player.palace_upgrade_to_guild, "is available in new round")
    return true

fun test_game_build_university()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    player.powers[0]=5
    player.powers[1]=7
    player.powers[2]=0
    player.tools=10
    player.coins=16
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::neutral_annexes)
    return true


fun test_game_power_actions()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)

    player.tools=0
    player.coins=0
    player.scholars_on_hand=0
    player.powers[0]=0
    player.powers[1]=0
    player.powers[2]=12

    game.power_action_7coins()
    assert (player.coins == 7 and player.powers[2]==8 and player.powers[0]==4, "power action 7 coins")
    game.power_action_2tools()
    assert (player.tools == 2 and player.powers[2]==4 and player.powers[0]==8, "power action 2 tools")
    game.power_action_scholar()
    assert (player.scholars_on_hand == 1 and  player.scholars == 6 and player.powers[2]==1 and player.powers[0]==11, "power action 1 scholar")
    return true

fun test_game_power_action_spade()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    player.tools=0
    player.coins=0
    player.scholars_on_hand=0
    player.powers[0]=0
    player.powers[1]=0
    player.powers[2]=12
    let spades = player.spades
    game.power_action_2spades()
    assert (player.spades == spades + 2 and player.powers[2]==6 and player.powers[0]==6, "power action 2spades")
    game.power_action_1spade()
    assert (player.spades == spades + 2 + 1 and player.powers[2]==2 and player.powers[0]==10, "power action 1spade")
    return true


fun test_URP()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.pass_turn()

    
    #TODO return player.score(2) == 63.0
    return true

fun test_get_round_bonus_tile()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.pass_turn()
    assert( !can game.get_round_bonus_tile(RoundBonusTileKind::big), "cannot get same tile")
    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    game.pass_turn()
    return true

fun test_game_send_scholar()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    player.powers[0]=4
    player.powers[1]=8
    player.powers[2]=0
    player.gain_scholar(2)
    game.send_scholar(Discipline::law)
    assert ( game.state.discipline_tracks[Discipline::law].first_space == 1 and player.discipline_level[Discipline::law.value] == 3 and player.powers[0] == 3 and player.scholars_on_hand == 1 , "send 1 scholar")
    game.send_scholar(Discipline::law)
    assert ( game.state.discipline_tracks[Discipline::law].first_space == 2 and player.discipline_level[Discipline::law.value] == 5 and player.powers[0] == 1 and player.scholars_on_hand == 0 , "send 2 scholar")
    return true

fun test_game_return_scholar()-> Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    player.powers[0]=4
    player.powers[1]=8
    player.powers[2]=0
    player.gain_scholar(2)
    game.return_scholar(Discipline::law)
    assert ( game.state.discipline_tracks[Discipline::law].first_space == 0 and player.discipline_level[Discipline::law.value] == 1 and player.powers[0] == 4 and player.scholars_on_hand == 1  and player.scholars == 6, "return 1 scholar")
    return true

fun test_game_city()-> Bool:
    # test game_tile and round bonus for tile 4
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    player.powers[0]=5
    player.powers[1]=7
    player.powers[2]=0
    player.tools=100
    player.coins=160
    player.spades=10
    game.state.competency_tiles = make_scenario_1_competency_tiles()
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::neutral_tower)

    game.build_workshop()
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::neutral_annexes)

    game.build_workshop()
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::power4)

    game.build_university()
    assert(player.cities == 1, "first city")
    let tile_kind = CityTileKind::VP6_6COINS
    let VP = player.VP
    let coins = player.coins
    game.get_city_tile(tile_kind)
    assert( player.coins - coins == 6, "got city tile income" )
    assert( player.VP - VP == 6, "got VP tile income" )
    game.get_competency_tile(CompetencyTileKind::city_vp) # 2VP per city

    let VP = player.VP
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    assert(player.VP == VP + 1*2 - 3,"got city round bonus vps")
    assert(player.universities == 1 and player.guilds == 0 and player.schools == 2 and player.cities == 1, "first city after turn ")
    return  true

fun test_game_income_phase_science_step()->Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::tool_science_adv)
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    assert(player.science_step_income==1,"has to advance one science step")
    game.advance_science_step(Discipline::banking)
    assert(player.discipline_level[0]==1,"advanced one science step")

    return true

fun test_game_income_phase_gain_book()->Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.state.competency_tiles = make_competency_tiles(Scenario::default)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::book_power)
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    assert(player.book_income==1,"has to get a book")
    game.gain_book(Discipline::banking)
    assert(player.books[0]==1,"got a book")
    return true

fun test_game_send_scholar_vp()->Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::send_scholar_vp)
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    let VP = player.VP
    game.send_scholar(Discipline::banking)
    assert(player.VP==VP + 2,"has get scholar vps")
    return true

fun test_game_discipline_level_round_pass_vp()->Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)

    game.state.competency_tiles = make_competency_tiles(Scenario::default)
    for i in range(4):
        player.discipline_level[i] = i+2

    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::lowest_science_vp)
    let VP = player.VP
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    # -3 is for power getting
    assert(player.VP == VP + 2 - 3,"got discipline level vps")
    return true


fun test_game_round_score_action_bonus_vp()->Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)

    game.state.round_score_display[0] = RoundScoreTileKind::rs_tile2 #vp for guild
    game.state.competency_tiles = make_competency_tiles(Scenario::default)
    let VP = player.VP
    game.build_guild()
    assert(player.VP == VP + 3 ,"got guild  vps")
    return true

fun test_game_round_score_end_round_bonus()->Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)

    game.state.round_score_display[0] = RoundScoreTileKind::rs_tile1 #3powers for 2steps low
    player.discipline_level[Discipline::law.value] = 3
    let power0 = player.powers[0]
    game.pass_turn()
    assert(player.powers[0] == power0 - 3 ,"got power bonus")
    return true

fun test_game_final_round_score_bonus()->Bool:
    let game = play(1, Scenario::default)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::big)

    game.state.round_score_display.assign_final_round_score_tile( FinalRoundScoreTileKind::frs_guild) #3vp for guild
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.pass_turn()
    game.get_round_bonus_tile(RoundBonusTileKind::guild)
    let VP = player.VP
    game.build_guild()
    assert(player.VP == VP + 3 ,"got guild bonus")
    return true