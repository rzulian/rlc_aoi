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
    for i in range(new_level-starting_level):
        apply_action_bonus(state, player, Action::science_step)

fun do_move_get_competency_tile(State state, Player player, CompetencyTileKind kind) -> Void:
    state.competency_tiles[kind].draw_competency_tile()
    player.competency_tiles.append(kind)
    apply_competency_tile_immediate_bonus(player, kind)

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

fun do_move_get_round_bonus_tile(State state, Player player, RoundBonusTileKind kind) -> Void:
    state.round_bonus_tiles.return_round_bonus_tile(player.round_bonus_tile)
    state.round_bonus_tiles.draw_round_bonus_tile(kind)
    player.round_bonus_tile = kind

    # Collect coin bonus if any
    let coin_bonus = state.round_bonus_tiles.get_coin_bonus(kind)
    player.gain_coin(coin_bonus)

fun apply_action_bonus(State state, Player player, Action action) -> Void:
    # apply bonus for that action from round bonus tile,round score tile, final round score tile and competency tiles

    let bonus = player.round_bonus_tile.action_bonus(action)
    bonus = bonus +  state.round_score_display[state.round.value].action_bonus(action)
    if state.round.value == FINAL_ROUND:
        bonus = bonus + state.round_score_display.final_round_score_tile.action_bonus(action)
    for tile in player.competency_tiles:
        bonus = bonus + tile.action_bonus(action)
    player.gain_vp(bonus)

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
                state.city_tiles.draw_city_tile(city_tile_kind)
                player.city_tiles.append(city_tile_kind)
                apply_city_tile_immediate_bonus(player, city_tile_kind)
                apply_action_bonus(state, player, Action::city)
                player.city_income = player.city_income - 1
            act get_palace_tile(PalaceTileKind palace_tile_kind){player.palace_income > 0 and state.palace_tiles.has_palace_tile(palace_tile_kind)}
                state.palace_tiles.draw_palace_tile(palace_tile_kind)
                player.palace = palace_tile_kind
                apply_palace_tile_immediate_bonus(player, palace_tile_kind)
                player.palace_income = player.palace_income - 1
            act pass_build_phase()
                return

act conversion_phase(ctx State state, ctx Player player) -> ConversionPhase:
    while true:
        actions:
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
            act pass_conversion()
                return

act book_pay_phase(ctx State state, ctx Player player) -> BookPayPhase:
    while player.has_book_pay_phase():
            act pay_book( Discipline discipline, BInt<0,7> num_books) {
                player.books[discipline.value] >= num_books.value,
                num_books.value  <= player.books_to_pay }
                player.pay_book(discipline, num_books.value )
                player.books_to_pay = player.books_to_pay - num_books.value


act action_phase(ctx State state, ctx Player player) -> ActionPhase:
    while true:
        actions:
            act build_workshop() {player.can_build_workshop() }
                player.build_workshop()
                apply_action_bonus(state, player, Action::workshop)
                #TODO workshop on border
                subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
                return
            act build_guild() {player.can_build_guild()}
                player.build_guild()
                apply_action_bonus(state, player, Action::guild)
                subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
                return
            act palace_free_upgrade_to_guild() {player.can_build_free_guild() and player.palace_upgrade_to_guild}
                player.build_free_guild()
                player.palace_upgrade_to_guild = false
                apply_action_bonus(state, player, Action::guild)
                subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
                return
            act build_school() {player.can_build_school() }
                player.build_school()
                apply_action_bonus(state, player, Action::school)
                subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
                return
            act build_palace() {player.can_build_palace() }
                player.build_palace()
                apply_action_bonus(state, player, Action::big)
                subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
                return
            act build_university() {player.can_build_university() }
                player.build_university()
                apply_action_bonus(state, player, Action::big)
                subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
                return

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
                apply_action_bonus(state, player, Action::spade)
                return
            act power_action_2spades(){ player.has_power(6)  }
                state.power_action_2spades = false
                player.convert_power_to_spades( 6, 2 )
                apply_action_bonus(state, player, Action::spade)
                apply_action_bonus(state, player, Action::spade)
                return

            act book_action(frm BookActionTileKind kind){
                state.book_action_tiles[kind].available,
                player.has_books(kind.books())
                }
                player.books_to_pay = kind.books()
                subaction*(state, state.get_current_player() ) book_pay_phase_frame = book_pay_phase(state , state.get_current_player())
                state.book_action_tiles.use(kind)
                if kind == BookActionTileKind::science_steps:
                    act advance_two_science_steps(Discipline discipline)
                        do_move_advance_discipline( state, player, discipline, 2)
                else if kind == BookActionTileKind::power:
                    player.gain_power(5)
                else if kind == BookActionTileKind::points_guild:
                    player.gain_vp(2*player.guilds.value)
                else if kind == BookActionTileKind::free_guild:
                    player.build_free_guild()
                    apply_action_bonus(state, player, Action::guild)
                    subaction*(state, state.get_current_player() ) build_phase = build_phase(state , state.get_current_player())
                else if kind == BookActionTileKind::coins:
                    player.gain_coin(6)
                else if kind == BookActionTileKind::spades:
                    player.gain_spade(3)
                    for i in range(3):
                        apply_action_bonus(state, player, Action::spade)
                return


            act send_scholar(Discipline discipline){player.scholars_on_hand.value > 0 and state.discipline_tracks[discipline].can_send_scholar() }
                let num_levels = state.discipline_tracks[discipline].steps_for_send_scholar()
                do_move_advance_discipline(state, player, discipline, num_levels)
                player.send_scholar(1)
                apply_action_bonus(state, player, Action::send_scholar)
                state.discipline_tracks[discipline].send_scholar()
                return

            act return_scholar(Discipline discipline){player.scholars_on_hand.value > 0 }
                do_move_advance_discipline(state, player, discipline, 1)
                player.return_scholar(1)
                apply_action_bonus(state, player, Action::send_scholar)
                return

            act upgrade_terraforming(){player.can_upgrade_terraforming()}
                player.upgrade_terraforming(true)
                apply_action_bonus(state, player, Action::sailing_terraforming)
                player.terraforming_sailing_income = 0
                # if books income
                subaction*(state, state.get_current_player() ) player_frame = income_phase(state , state.get_current_player())
                return

            act upgrade_sailing(){player.can_upgrade_sailing()}
                player.upgrade_sailing(true)
                apply_action_bonus(state, player, Action::sailing_terraforming)
                player.terraforming_sailing_income = 0
                # if books income
                subaction*(state, state.get_current_player() ) player_frame = income_phase(state , state.get_current_player())
                return

            act develop_innovation(frm InnovationTileKind kind){
                state.innovation_tiles[kind].in_play,
                state.innovation_tiles[kind].available,
                player.can_get_innovation_tile( state.innovation_tiles[kind] )
                }
                player.pay_requirements_innovation_tile(state.innovation_tiles[kind])
                subaction*(state, state.get_current_player() ) book_pay_phase_frame = book_pay_phase(state , state.get_current_player())
                player.get_innovation_tile( kind )
                state.innovation_tiles.draw_innovation_tile(kind)
                apply_innovation_tile_immediate_bonus(player, kind)
                for i in range(player.terraforming_sailing_income):
                    apply_action_bonus(state, player, Action::sailing_terraforming)
                player.terraforming_sailing_income = 0
                # if books income
                subaction*(state, state.get_current_player() ) player_frame = income_phase(state , state.get_current_player())
                return
            act special_action_professors() {player.special_action_professors}
                player.gain_scholar(1)
                player.gain_vp(3)
                player.special_action_professors = false
                return
            act special_action_one_spade() {player.special_action_one_spade}
                player.gain_spade(1)
                player.special_action_one_spade = false
                apply_action_bonus(state, player, Action::spade)
                return
            act pass_round()
                player.has_passed = true
                return

@classes
act play() -> Game:
    subaction* game = base_play( 1, Scenario::sc1)

@classes
act base_play(Int num_players, Scenario scenario) -> Base:

    frm state : State
    state.setup_game(num_players, scenario)

    #player get initial round bonus tile

    state.reset_turn_order()
    while state.has_players_in_turn_order():
        act get_round_bonus_tile(RoundBonusTileKind kind){state.round_bonus_tiles[kind].available and state.round_bonus_tiles[kind].in_play}
            do_move_get_round_bonus_tile( state, state.get_current_player(), kind)
        state.mark_current_player_passed()

    while state.round<=FINAL_ROUND:
        state.new_round()

        for player in state.players:
            player.has_passed = false
            player.update_income()

        state.reset_turn_order()
        while state.has_players_in_turn_order():
            subaction*(state, state.get_current_player() ) player_income = income_phase(state , state.get_current_player())
            state.mark_current_player_passed()

        #TODO update income after level update
        state.reset_turn_order()
        while state.has_players_in_turn_order():
            if !(state.scenario == Scenario::test): #exclude conversion before main action
                subaction*(state, state.get_current_player() ) player_conversion = conversion_phase(state , state.get_current_player())

            subaction*(state, state.get_current_player() ) player_action = action_phase(state , state.get_current_player())

            if !(state.scenario == Scenario::test): #exclude conversion after main action
                subaction*(state, state.get_current_player() ) player_conversion = conversion_phase(state , state.get_current_player())

            if state.get_current_player().has_passed:
                #pass and get a new round bonus tile
                apply_competency_tile_pass_bonus(state.get_current_player())
                apply_palace_tile_pass_bonus(state.get_current_player())
                apply_round_bonus_tile_pass_bonus(state.get_current_player())

                act get_round_bonus_tile(RoundBonusTileKind kind){state.round_bonus_tiles[kind].available and state.round_bonus_tiles[kind].in_play}
                    do_move_get_round_bonus_tile( state, state.get_current_player(), kind)
                state.mark_current_player_passed()
            else:
                state.move_to_next_player()

        #get round score tile bonus in pass order
        state.original_turn_order = state.passed_turn_order
        state.reset_turn_order()

        while state.has_players_in_turn_order() and state.round<FINAL_ROUND: #not in the final round
            do_move_get_round_score_tile_bonus(state, state.get_current_player(), state.round_score_display[state.round.value])
            subaction*(state, state.get_current_player() ) player_end_round = end_round_phase(state , state.get_current_player())
            #scenario 11 power bonus on every phase
            if (state.scenario == Scenario::sc1):
                state.get_current_player().power_income = state.get_current_player().power_income + 6
                state.get_current_player().vp_income = state.get_current_player().vp_income - 3
            state.mark_current_player_passed()

        state.round = state.round + 1

fun get_current_player(Game g) -> Int:
    return g.game.state.current_player.value

fun score(Game g, Int player_id) -> Float:
    return g.game.state.players[player_id].score(g.game.state.round.value) / 100.0
    
fun get_num_players() -> Int:
    return NUM_PLAYERS

fun pretty_print(Game g):
    g.game.state.pretty_print_state()

fun main() -> Int:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.pass_round()
    return 0



fun test_game_setup()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    return player.workshops == 2

fun test_game_build_workshop()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    player.powers[2]=12
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    assert( can game.power_action_1spade(), "can spade")
    game.power_action_1spade()
    #new turn
    game.build_workshop()
    return player.workshops == 3 and player.spades==0

fun test_game_can_pass_round_with_action()-> Bool:
    let game = base_play(1, Scenario::default)
    ref player = game.state.players[0]
    player.powers[2]=12
    game.state.round_bonus_tiles.make_available(RoundBonusTileKind::dummy1)
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.convert_3power_to_tool()
    assert( can game.pass_conversion(), "can pass conversion after conversion")
    return true

fun test_game_can_convert_after_action()-> Bool:
    let game = base_play(1, Scenario::default)
    ref player = game.state.players[0]
    player.powers[2]=12
    game.state.round_bonus_tiles.make_available(RoundBonusTileKind::dummy1)
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.pass_conversion()
    game.power_action_1spade()
    assert( can game.pass_conversion(), "can end turn without convertion")
    assert( !can game.build_workshop(), "cannot do another main action")
    game.convert_3power_to_tool()
    assert( can game.pass_conversion(), "can end turn after conversion")
    assert( !can game.pass_round(), "cannot do main action after conversion")
    return true

fun test_game_build_guild()-> Bool:
    # check also power income from guild
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    player.powers[0] = 1
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.build_guild()
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    return player.guilds == 1 and player.powers[0] == 0
 
fun test_game_build_school()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.build_guild()
    game.build_school()
    return player.schools == 1 and player.guilds == 0

fun test_game_scholar_income()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::neutral_tower)
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    return player.scholars_on_hand == 1 and player.scholars == 6

fun test_game_scholar_income_no_scholar()-> Bool:
    # has no scholars available, gets nothing
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.state.players[0].scholars=0
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::neutral_tower)
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    return player.scholars_on_hand == 0 and player.scholars == 0


fun test_build_palace_tile_17_10vp()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    let kind = PalaceTileKind::power2_vp10
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.build_guild()
    game.build_palace()
    assert( player.palaces == 1 and player.guilds == 0, "has palace")
    let VP = player.VP
    game.get_palace_tile(kind)
    assert( player.palace == kind and player.VP == VP+10 and game.state.palace_tiles[kind] == 0, "tile has been draw")
    let power = player.powers[0]
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    assert( player.powers[0] == power -2 , "got 2 power round bonus")
    return true

fun test_palace_tile_4_free_upgrade_to_guild()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    let kind = PalaceTileKind::power2_upgrade_to_guild
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    player.build_free_workshop()
    game.build_guild()
    game.build_palace()
    game.get_palace_tile(kind)
    assert( player.palace == kind and player.palace_upgrade_to_guild and game.state.palace_tiles[kind] == 0, "tile has been draw")
    let coins = player.coins
    let tools = player.tools
    let guilds = player.guilds
    game.palace_free_upgrade_to_guild()
    assert( player.coins == coins and player.tools == tools and player.guilds == guilds + 1, "didnt pay for the guild")
    assert (!player.palace_upgrade_to_guild, "cannot use it again during round")
    game.pass_round()

    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    assert (player.palace_upgrade_to_guild and can game.palace_free_upgrade_to_guild(), "is available in new round")
    return true

fun test_game_build_university()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    player.powers[0]=5
    player.powers[1]=7
    player.powers[2]=0
    player.tools=10
    player.coins=16
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::neutral_annexes)
    return true


fun test_game_power_actions()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)

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
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
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
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.pass_round()

    
    #TODO return player.score(2) == 63.0
    return true

fun test_get_round_bonus_tile()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.pass_round()
    assert( !can game.get_round_bonus_tile(RoundBonusTileKind::dummy1), "cannot get same tile")
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    game.pass_round()
    return true

fun test_get_round_bonus_tile_spade_book()-> Bool:
    let game = base_play(1, Scenario::sc1)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::spade_book)
    game.gain_book(Discipline::law)
    game.pass_conversion()

    game.special_action_one_spade()
    assert( player.spades == 1, "has one spade")
    assert( !player.special_action_one_spade  , "used special action one spade")
    return true

fun test_game_send_scholar()-> Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
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
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    player.powers[0]=4
    player.powers[1]=8
    player.powers[2]=0
    player.gain_scholar(2)
    game.return_scholar(Discipline::law)
    assert ( game.state.discipline_tracks[Discipline::law].first_space == 0 and player.discipline_level[Discipline::law.value] == 1 and player.powers[0] == 4 and player.scholars_on_hand == 1  and player.scholars == 6, "return 1 scholar")
    return true

fun test_game_city()-> Bool:
    # test game_tile and round bonus for tile 4
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
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
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    assert(player.VP == VP + 1*2 ,"got city round bonus vps")
    assert(player.universities == 1 and player.guilds == 0 and player.schools == 2 and player.cities == 1, "first city after turn ")
    return  true

fun test_game_income_phase_science_step()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::tool_science_adv)
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    assert(player.science_step_income==1,"has to advance one science step")
    game.advance_science_step(Discipline::banking)
    assert(player.discipline_level[0]==1,"advanced one science step")

    return true

fun test_game_income_phase_gain_book()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.state.competency_tiles = make_competency_tiles(Scenario::default)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::book_power)
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    assert(player.book_income==1,"has to get a book")
    game.gain_book(Discipline::banking)
    assert(player.books[0]==1,"got a book")
    return true

fun test_game_send_scholar_vp()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::send_scholar_vp)
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    let VP = player.VP
    game.send_scholar(Discipline::banking)
    assert(player.VP==VP + 2,"has get scholar vps")
    return true

fun test_game_discipline_level_round_pass_vp()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)

    game.state.competency_tiles = make_competency_tiles(Scenario::default)
    for i in range(4):
        player.discipline_level[i] = i+2

    game.build_guild()
    game.build_school()
    game.get_competency_tile(CompetencyTileKind::lowest_science_vp)
    let VP = player.VP
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    # -3 is for power getting
    assert(player.VP == VP + 2 ,"got discipline level vps")
    return true


fun test_game_round_score_action_bonus_vp()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)

    game.state.round_score_display[0] = RoundScoreTileKind::rs_tile2 #vp for guild
    game.state.competency_tiles = make_competency_tiles(Scenario::default)
    let VP = player.VP
    game.build_guild()
    assert(player.VP == VP + 3 ,"got guild  vps")
    return true

fun test_game_round_score_end_round_bonus()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)

    game.state.round_score_display[0] = RoundScoreTileKind::rs_tile1 #3powers for 2steps law
    player.discipline_level[Discipline::law.value] = 3
    let power0 = player.powers[0]
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    assert(player.powers[0] == power0 - 3 ,"got power bonus")
    return true

fun test_game_final_round_score_bonus()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    game.state.round = 5 #move to last round
    game.state.round_score_display.assign_final_round_score_tile( FinalRoundScoreTileKind::frs_guild) #3vp for guild
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    let VP = player.VP
    game.build_guild()
    assert(player.VP == VP + 3 ,"got guild bonus")
    return true

fun test_get_innovation_tile()->Bool:
    # books and additional cost
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]

    player.books[Discipline::banking.value] = 2
    player.books[Discipline::law.value] = 2
    player.books[Discipline::engineering.value] = 2
    player.books[Discipline::medicine.value] = 2
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    let coins = player.coins
    game.develop_innovation(InnovationTileKind::dummy1)

    let num_books : BInt<0,7>

    assert(player.books[Discipline::banking.value] == 0 ,"payed discipline required books")
    num_books = 3
    assert( !can game.pay_book(Discipline::law, num_books), "cannot pay more books than available")
    num_books = 2
    game.pay_book(Discipline::law, num_books)
    assert(player.books[Discipline::law.value] == 0 ,"payed discipline law books")
    num_books = 1
    game.pay_book(Discipline::engineering, num_books)
    assert(player.books[Discipline::engineering.value] == 1 ,"payed discipline engineering books")
    assert(player.innovation_tiles.get(0) == InnovationTileKind::dummy1, "got the innovation tile")
    assert(player.coins == coins-5, "payed additional cost")
    assert(!game.state.innovation_tiles[InnovationTileKind::dummy1].available, "innovation tile is not available")

    return true


fun test_get_additional_innovation_tile()->Bool:
    # books and additional cost (books 5 standard + 1 )
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]

    player.books[Discipline::banking.value] = 3
    player.books[Discipline::law.value] = 3
    player.books[Discipline::engineering.value] = 3
    player.books[Discipline::medicine.value] = 3
    player.palaces = 1
    player.innovation_tiles.append(InnovationTileKind::none)
    let coins = player.coins
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    game.develop_innovation(InnovationTileKind::dummy1)

    let num_books : BInt<0,7>

    assert(player.books[Discipline::banking.value] == 1 ,"payed 2 banking required books")
    assert(player.coins == coins, "didn't pay additional cost")
    num_books = 3
    game.pay_book(Discipline::law, num_books)
    assert(player.books[Discipline::law.value] == 0 ,"payed discipline law books")
    num_books = 1
    game.pay_book(Discipline::engineering, num_books)
    assert(player.books[Discipline::engineering.value] == 2 ,"payed discipline engineering books")
    assert(player.innovation_tiles.get(1) == InnovationTileKind::dummy1, "got the innovation tile")
    assert(!game.state.innovation_tiles[InnovationTileKind::dummy1].available, "innovation tile is not available")

    return true


fun test_innovation_tile_libraries()->Bool:
    let game = base_play(1, Scenario::sc1)
    ref player = game.state.players[0]

    player.books[Discipline::banking.value] = 5
    player.books[Discipline::law.value] = 5
    player.books[Discipline::engineering.value] = 5
    player.books[Discipline::medicine.value] = 5

    player.discipline_level[Discipline::banking.value] = 7
    player.discipline_level[Discipline::law.value] = 5
    player.discipline_level[Discipline::engineering.value] = 6
    player.discipline_level[Discipline::medicine.value] = 1


    game.get_round_bonus_tile(RoundBonusTileKind::coins)
    #print_available_actions(game)
    game.pass_conversion()
    game.develop_innovation(InnovationTileKind::libraries)

    let num_books : BInt<0,7>
    num_books = 5
    let VP = player.VP
    game.pay_book(Discipline::law, num_books)
    assert( player.VP == VP + 7 + 6, "got VP for 2 top disciplines")

    return true


fun test_innovation_tile_colleges()->Bool:
    let game = base_play(1, Scenario::sc1)
    ref player = game.state.players[0]

    player.books[Discipline::banking.value] = 5
    player.books[Discipline::law.value] = 5
    player.books[Discipline::engineering.value] = 5
    player.books[Discipline::medicine.value] = 5
    game.state.round_score_display[0] = RoundScoreTileKind::rs_tile1 #5vp innovation tile
    player.schools = 2
    game.get_round_bonus_tile(RoundBonusTileKind::coins)
    #print_available_actions(game)
    game.pass_conversion()
    game.develop_innovation(InnovationTileKind::colleges)

    let num_books : BInt<0,7>
    num_books = 5
    let VP = player.VP
    game.pay_book(Discipline::law, num_books)
    assert( player.VP == VP + 10, "got VP for 2 schools")

    return true


fun test_innovation_tile_steam_power()->Bool:
    let game = base_play(1, Scenario::sc1)
    ref player = game.state.players[0]
    game.state.round_score_display[0] = RoundScoreTileKind::rs_tile8 #3vp for terraforming/sailing
    player.books[Discipline::banking.value] = 5
    player.books[Discipline::law.value] = 5
    player.books[Discipline::engineering.value] = 5
    player.books[Discipline::medicine.value] = 5
    game.get_round_bonus_tile(RoundBonusTileKind::coins)
    #print_available_actions(game)
    game.pass_conversion()
    game.develop_innovation(InnovationTileKind::steam_power)

    let num_books : BInt<0,7>
    num_books = 5
    let VP = player.VP
    game.pay_book(Discipline::law, num_books)
    assert( player.VP == VP + 2 + 3 + 3, "got 2VP for sailing + 3 +3 for round score")
    assert( player.sailing_track_level == 1, "sailing")
    assert( player.terraforming_track_level == 1, "terraforming")
    assert( player.scholars_on_hand == 1, "got scholar")
    assert( player.book_income == 2, "has to get books")
    assert( can game.gain_book(Discipline::law), "can get book")
    return true

fun test_innovation_tile_professors()->Bool:
    let game = base_play(1, Scenario::sc1)
    ref player = game.state.players[0]
    game.state.round_score_display[0] = RoundScoreTileKind::rs_tile1
    player.books[Discipline::banking.value] = 5
    player.books[Discipline::law.value] = 5
    player.books[Discipline::engineering.value] = 5
    player.books[Discipline::medicine.value] = 5
    game.get_round_bonus_tile(RoundBonusTileKind::coins)

    game.pass_conversion()
    game.develop_innovation(InnovationTileKind::professors)
    let num_books : BInt<0,7>
    num_books = 5
    game.pay_book(Discipline::law, num_books)
    game.pass_conversion()

    game.pass_conversion()
    game.special_action_professors()
    game.pass_conversion()

    game.pass_conversion()
    assert( !can game.special_action_professors(), "cannot redo professors")
    game.pass_round()
    game.pass_conversion()

    game.get_round_bonus_tile(RoundBonusTileKind::big)
    game.pass_conversion()
    let VP = player.VP
    let scholars = player.scholars_on_hand
    game.special_action_professors()
    assert( player.VP == VP + 3 , "professors VP")
    assert( player.scholars_on_hand == scholars + 1, "new scholar")
    return true


fun test_book_actions()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    player.books[Discipline::banking.value] = 5
    player.books[Discipline::law.value] = 5
    player.books[Discipline::engineering.value] = 5
    player.books[Discipline::medicine.value] = 5
    let num_books : BInt<0,7>
    num_books = 1
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    let coins = player.coins
    game.book_action(BookActionTileKind::coins)
    game.pay_book(Discipline::banking,num_books)
    game.pay_book(Discipline::law,num_books)
    assert(player.coins == coins + 6, "got 6 coins")
    assert(!game.state.book_action_tiles[BookActionTileKind::coins].available, "book action is not more available")
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    assert(game.state.book_action_tiles[BookActionTileKind::coins].available, "book action is available")
    let level = player.discipline_level[Discipline::law.value]
    game.book_action(BookActionTileKind::science_steps)
    game.pay_book(Discipline::banking, num_books)
    game.advance_two_science_steps(Discipline::law)
    assert(player.discipline_level[Discipline::law.value] == level + 2, "got 2 science steps")

    return true


fun test_min_book_book_actions()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    player.books[Discipline::banking.value] = 1
    player.books[Discipline::law.value] = 1
    player.books[Discipline::engineering.value] =0
    player.books[Discipline::medicine.value] = 0
    let num_books : BInt<0,7>
    num_books = 1
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    let coins = player.coins
    game.book_action(BookActionTileKind::coins)
    game.pay_book(Discipline::banking,num_books)
    game.pay_book(Discipline::law,num_books)
    assert(player.coins == coins + 6, "got 6 coins")
    assert(!game.state.book_action_tiles[BookActionTileKind::coins].available, "book action is not more available")
    game.pass_round()
    return true

fun test_upgrade_terraforming()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    player.gain_scholar(3)

    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    let coins = player.coins
    let tools = player.tools
    let scholars = player.scholars_on_hand
    # first level terraforming : 2 books
    game.upgrade_terraforming()
    assert(player.coins == coins - 5,"payed coins")
    assert(player.tools == tools - 1,"payed tool")
    assert(player.scholars_on_hand == scholars - 1,"payed scholars")
    game.gain_book(Discipline::banking)
    game.gain_book(Discipline::law)
    game.pass_round()
    game.get_round_bonus_tile(RoundBonusTileKind::dummy2)
    let vp = player.VP
    # second level terraforming : 6VP
    game.upgrade_terraforming()
    assert(player.VP == vp + 6,"got terraforming vps")
    assert( !can game.upgrade_terraforming(), "max terraformig level reached")
    return true

fun test_upgrade_sailing()->Bool:
    let game = base_play(1, Scenario::test)
    ref player = game.state.players[0]
    player.gain_scholar(3)
    # first level sailing : 2 vp
    game.get_round_bonus_tile(RoundBonusTileKind::dummy1)
    let coins = player.coins
    let scholars = player.scholars_on_hand
    let vp = player.VP
    game.upgrade_sailing()
    assert(player.coins == coins - 4,"payed coins")
    assert(player.scholars_on_hand == scholars - 1,"payed scholars")
    assert(player.VP == vp + 2,"got sailing vps")
    # second level sailing : 2 books
    game.upgrade_sailing()
    game.gain_book(Discipline::banking)
    game.gain_book(Discipline::law)
    let vp = player.VP
    # third level sailing : 4VP
    game.upgrade_sailing()
    assert(player.VP == vp + 4,"got terraforming vps")
    assert( !can game.upgrade_sailing(), "max sailing level reached")
    return true