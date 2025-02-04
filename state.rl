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
    BInt<1, 8> phase
    Bool is_done

    fun setup_game():
        self.board = make_board()
        self.phase = 1
        self.is_done = false

        # setup players
        for i in range(4):
            let player = make_player()
            self.players.append(player)

        self.current_player = 0

    
    fun new_phase():  
        if self.phase == 2:
            self.is_done = true
        else:
            self.phase = self.phase + 1
            print("PHASE=>"s + to_string(self.phase))
        return


    fun pretty_print_state():
        let to_print : String
        let player_id = 0 
        print(self.players)
        print('\n')