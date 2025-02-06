import collections.vector
import serialization.to_byte_vector
import serialization.print
import math.numeric
import player
import state
import none
import machine_learning

act action_phase(ctx State state) -> ActionPhase:
    while true:
        actions:
            act build_workshop() {state.players[state.current_player.value].can_build_workshop() }
                state.players[state.current_player.value].build_workshop()
            act build_guild() {state.players[state.current_player.value].can_build_guild() }
                state.players[state.current_player.value].build_guild()
            act build_school() {state.players[state.current_player.value].can_build_school() }
                state.players[state.current_player.value].build_school()
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
            subaction*(state) player_frame = action_phase(state)

            state.current_player = state.current_player + 1
        state.new_phase()

    

fun get_current_player(Game g) -> Int:
    return g.state.current_player.value

fun score(Game g, Int player_id) -> Float:
    return g.state.players[player_id].score()
    
fun get_num_players() -> Int:
    return 4

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

        print(executable.get(num_action % executable.size()))
        apply(executable.get(num_action % executable.size()), state)

fun test_game_setup()-> Bool:
    let game = play()
    game.build_workshop()
    return game.state.players[0].workshops == 6


fun test_game_setup2()-> Bool:
    let game = play()
    game.build_guild()
    return game.state.players[0].guilds == 3
 
fun test_game_build_school()-> Bool:
    let game = play()
    game.build_guild()
    game.build_school()
    return game.state.players[0].schools == 2 and game.state.players[0].guilds == 4

fun test_game_schoolar_income()-> Bool:
    let game = play()
    game.build_guild()
    game.build_school()
    game.pass_turn()
    return game.state.players[0].scholars_on_hand == 1 and game.state.players[0].scholars == 6

fun test_game_schoolar_income_no_scholar()-> Bool:
    let game = play()
    game.state.players[0].scholars=0
    game.build_guild()
    game.build_school()
    game.pass_turn()
    return game.state.players[0].scholars_on_hand == 0 and game.state.players[0].scholars == 0