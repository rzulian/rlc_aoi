import collections.vector
import serialization.to_byte_vector
import serialization.print
import math.numeric
import range
import action

import board
import player
import discipline
import competency
import city_tile

using PlayerID = BInt<0, 5>

cls State:
    Board board
    BoundedVector<Player, 4> players
    PlayerID current_player
    BInt<0, 8> round
    Bool is_done
    Bool power_action_scholar
    Bool power_action_2tools
    Bool power_action_7coins
    Bool power_action_1spade
    Bool power_action_2spades
    DisciplineDisplay discipline_display
    CompetencyTiles competency_tiles
    CityTiles city_tiles
    PalaceTiles palace_tiles

    fun setup_game(Int num_players):
        self.board = make_board()
        self.round = 0
        self.is_done = false

        self.competency_tiles.distribute_scenario_std()
        self.palace_tiles.setup_scenario_std()

        # setup players
        for i in range(num_players):
            let player = make_player()
            player.build_free_workshop()
            player.build_free_workshop() 
            self.players.append(player)

        self.current_player = 0
    
    fun get_current_player() -> ref Player:
        return self.players[self.current_player.value]
    
    fun new_round():
        let urp_for_vp = [0.0, 0.58, 0.69, 0.83, 1.0, 1.2, 1.44]
        # reset board
        # power actions return available
        self.power_action_2tools = true
        self.power_action_7coins = true
        self.power_action_scholar= true
        self.power_action_1spade = true
        self.power_action_2spades= true

        #assign urp_for_vp
        for player in self.players:
            player.urp_for_vp = urp_for_vp[self.round.value]

        return


    fun pretty_print_state():
        let to_print : String
        let player_id = 0 
        print(self)
        print(self.players)
        print('\n')