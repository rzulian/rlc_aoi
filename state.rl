import collections.vector
import serialization.to_byte_vector
import serialization.print
import math.numeric
import board
import player
import range

using PlayerID = BInt<0, 5>



cls State:
    Board board
    BoundedVector<Player, 4> players
    PlayerID current_player
    BInt<0, 8> phase
    Bool is_done
    Bool power_action_scholar
    Bool power_action_2tools
    Bool power_action_7coins
    Bool power_action_1spade
    Bool power_action_2spades

    fun setup_game():
        self.board = make_board()
        self.phase = 0
        self.is_done = false


        # setup players
        for i in range(1):
            let player = make_player()
            player.build_free_workshop()
            player.build_free_workshop() 
            self.players.append(player)

        self.current_player = 0
    
    fun get_current_player() -> ref Player:
        return self.players[self.current_player.value]
    
    fun new_phase():  
        for player in self.players:
            player.update_income()

        self.power_action_2tools = true
        self.power_action_7coins = true
        self.power_action_scholar= true
        self.power_action_1spade = true
        self.power_action_2spades= true

        if self.phase == 3:
            self.is_done = true
        else:
            self.phase = self.phase + 1
        return


    fun pretty_print_state():
        let to_print : String
        let player_id = 0 
        print(self.players)
        print('\n')