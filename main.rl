import collections.vector
import serialization.to_byte_vector
import serialization.print
import math.numeric
import player
import state
import none
import machine_learning

fun do_move_steps_action(  State state,  Player player,  Int discipline_id,  Int num_steps) -> Void:
    let starting_level =  player.discipline_level[discipline_id].value
    let power = state.disciplines[discipline_id].power_from_track( starting_level, num_steps)
    let new_level = state.disciplines[discipline_id].next_level( starting_level, num_steps)
    player.gain_power( power )
    player.discipline_level[discipline_id] = new_level
    player.URP = player.URP + float(new_level-starting_level)*URP_SCIENCE_STEP

act action_phase(ctx State state, ctx Player player) -> ActionPhase:
    while true:
        actions:
            act build_workshop() {player.can_build_workshop() }
                player.build_workshop()
            act build_guild() {player.can_build_guild() }
                player.build_guild()
            act build_school() {player.can_build_school() }
                player.build_school()
                act get_competency_tile(BInt<0,4> discipline_id , BInt<0,3> level){player.can_get_competency_tile( discipline_id.value, level.value) }
                    do_move_steps_action(state, player, discipline_id.value, level.value + 1)
                    player.get_competency_tile( discipline_id.value, level.value)
                    player.URP = player.URP + URP_COMPETENCY_TILE * float(6-state.phase.value)/5.0

            act build_palace() {player.can_build_palace() }
                player.build_palace()
                player.URP = player.URP + URP_PALACE * float(6-state.phase.value)/5.0
            act build_university() {player.can_build_university() }
                player.build_university()
                act get_competency_tile(BInt<0,4> discipline_id , BInt<0,3> level){player.can_get_competency_tile( discipline_id.value, level.value) }
                    do_move_steps_action(state, player, discipline_id.value, level.value + 1)
                    player.get_competency_tile( discipline_id.value, level.value)
                    player.URP = player.URP +  URP_COMPETENCY_TILE * float(6-state.phase.value)/5.0

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
            act power_action_2tools(){ state.power_action_2tools, player.has_power(4)  }
                state.power_action_2tools = false
                player.convert_power_to_tools( 4, 2 )
            act power_action_scholar(){ state.power_action_scholar, player.scholars.value > 0,  player.has_power(3)  }
                state.power_action_scholar = false
                player.convert_power_to_scholars( 3, 1 )
            act power_action_1spade(){ player.has_power(4)  }
                state.power_action_1spade = false                
                player.convert_power_to_spades( 4, 1 )
            act power_action_2spades(){ player.has_power(6)  }
                state.power_action_2spades = false                
                player.convert_power_to_spades( 6, 2 )

            act send_scholar(BInt<0,4> discipline_id ){player.scholars_on_hand.value > 0 and state.disciplines[discipline_id.value].can_send_scholar() }
                let num_steps = state.disciplines[discipline_id.value].steps_for_send_scholar()
                do_move_steps_action(state, player, discipline_id.value, num_steps)
                player.send_scholar(1)
                state.disciplines[discipline_id.value].send_scholar()

            act return_scholar(BInt<0,4> discipline_id ){player.scholars_on_hand.value > 0 }
                do_move_steps_action(state, player, discipline_id.value, 1)
                player.pay_scholar(1)

            act upgrade_terraforming(){player.can_upgrade_terraforming()}
                player.upgrade_terraforming()

            act pass_turn()
                return

@classes
act play() -> Game:

    frm state : State
    state.setup_game()
    state.new_phase()

    while !state.is_done:
        
        state.current_player = 0
        while state.current_player < state.players.size():
            subaction*(state, state.get_current_player() ) player_frame = action_phase(state , state.get_current_player())
            state.current_player = state.current_player + 1
        state.new_phase()

fun get_current_player(Game g) -> Int:
    return g.state.current_player.value

fun score(Game g, Int player_id) -> Float:
    return g.state.players[player_id].score(g.state.phase.value)
    
fun get_num_players() -> Int:
    return 1

fun pretty_print(Game g):
    g.state.pretty_print_state()

fun main() -> Int:
    let game = play()
    print(game.state)
    ref player = game.state.players[0]
    game.pass_turn()
    return 0

fun fuzz(Vector<Byte> input):
    let state = play()
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
    let game = play()
    ref player = game.state.players[0]
    return player.workshops == 2

fun test_game_build_workshop()-> Bool:
    let game = play()
    ref player = game.state.players[0]
    player.powers[2]=12
    game.power_action_1spade()
    game.build_workshop()
    return player.workshops == 3 and player.spades==0

fun test_game_build_guild()-> Bool:
    # check also power income
    let game = play()
    ref player = game.state.players[0]
    player.powers[0] = 1
    game.build_guild()
    game.pass_turn()
    return player.guilds == 1 and player.powers[0] == 0
 
fun test_game_build_school()-> Bool:
    let game = play()
    ref player = game.state.players[0]
    game.build_guild()
    game.build_school()
    return player.schools == 1 and player.guilds == 0

fun test_game_schoolar_income()-> Bool:
    let game = play()
    ref player = game.state.players[0]
    game.build_guild()
    game.build_school()
    let discipline_id : BInt<0,4>
    let level : BInt<0,3>
    discipline_id=1
    level=2
    game.get_competency_tile(discipline_id, level)
    game.pass_turn()
    return player.scholars_on_hand == 1 and player.scholars == 6

fun test_game_schoolar_income_no_scholar()-> Bool:
    let game = play()
    ref player = game.state.players[0]
    game.state.players[0].scholars=0
    game.build_guild()
    game.build_school()
    let discipline_id : BInt<0,4>
    let level : BInt<0,3>
    discipline_id=1
    level=2
    game.get_competency_tile(discipline_id, level)
    game.pass_turn()
    return player.scholars_on_hand == 0 and player.scholars == 0

fun test_game_build_palace()-> Bool:
    let game = play()
    ref player = game.state.players[0]
    game.build_guild()
    game.build_palace()
    return player.palaces == 1 and player.guilds == 0


fun test_game_build_university()-> Bool:
    let game = play()
    ref player = game.state.players[0]
    player.powers[0]=5
    player.powers[1]=7
    player.powers[2]=0
    player.tools=10
    player.coins=16
    let discipline_id : BInt<0,4>
    let level : BInt<0,3>
    discipline_id=1
    level=2
    game.build_guild()
    game.build_school()
    game.get_competency_tile(discipline_id, level)
    assert( player.competency_tiles.value == 1 and player.powers[0].value == 4 and player.discipline_level[discipline_id.value].value == 3, "first competency tile")
    game.build_university()
    game.get_competency_tile(discipline_id, level)
    assert(player.universities == 1 and player.guilds == 0 and player.schools == 0 and player.competency_tiles.value == 2 and player.powers[0].value == 2 and player.powers[1].value == 10, "second competency tile")
    return  true


fun test_game_power_actions()-> Bool:
    let game = play()
    ref player = game.state.players[0]

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
    let game = play()
    ref player = game.state.players[0]

    player.tools=0
    player.coins=0
    player.scholars_on_hand=0
    player.powers[0]=0
    player.powers[1]=0
    player.powers[2]=12
    game.power_action_2spades()
    assert (player.spades == 2 and player.powers[2]==6 and player.powers[0]==6, "power action 2spades")
    game.power_action_1spade()
    assert (player.spades == 3 and player.powers[2]==2 and player.powers[0]==10, "power action 1spade")
    return true


fun test_URP()-> Bool:
    let game = play()
    ref player = game.state.players[0]
    game.pass_turn()
    game.pass_turn()
    
    #TODO return player.score(2) == 63.0
    return true

fun test_game_send_scholar()-> Bool:
    let game = play()
    ref player = game.state.players[0]
    player.powers[0]=4
    player.powers[1]=8
    player.powers[2]=0
    player.gain_scholar(2)
    let discipline_id : BInt<0,4>
    discipline_id = 1 
    game.send_scholar( discipline_id)
    assert ( game.state.disciplines[discipline_id.value].first_space == 1 and player.discipline_level[discipline_id.value] == 3 and player.powers[0] == 3 and player.scholars_on_hand == 1 , "send 1 scholar")
    game.send_scholar( discipline_id)
    assert ( game.state.disciplines[discipline_id.value].first_space == 2 and player.discipline_level[discipline_id.value] == 5 and player.powers[0] == 1 and player.scholars_on_hand == 0 , "send 2 scholar")
    return true

fun test_game_return_scholar()-> Bool:
    let game = play()
    ref player = game.state.players[0]
    player.powers[0]=4
    player.powers[1]=8
    player.powers[2]=0
    player.gain_scholar(2)
    let discipline_id : BInt<0,4>
    discipline_id = 1 
    game.return_scholar( discipline_id)
    assert ( game.state.disciplines[discipline_id.value].first_space == 0 and player.discipline_level[discipline_id.value] == 1 and player.powers[0] == 4 and player.scholars_on_hand == 1  and player.scholars == 6, "return 1 scholar")
    return true