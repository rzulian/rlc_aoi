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
    BInt<0, 8> phase
    Bool is_done
    Bool power_action_scholar
    Bool power_action_2tools
    Bool power_action_7coins
    Bool power_action_1spade
    Bool power_action_2spades
    BoundedVector<DisciplineTrack, 4> disciplines
    CompetencyTiles competency_tiles
    CityTiles city_tiles
    BInt<0,NUM_COMPETENCY_TILES>[NUM_COMPETENCY_TILES] innovation_display  


    fun setup_game(Int num_players):
        self.board = make_board()
        self.phase = 0
        self.is_done = false

        for dn in enumerate(DisciplineName::banking):
            let discipline = make_discipline_track(dn)
            self.disciplines.append(discipline)

        self.competency_tiles = make_competency_tiles()
        self.city_tiles = make_city_tiles()
        # innovation_display contains the position of the corresponding competency_tiles
        # position is discipline_id*3 + level
        # TODO shuffle innovation display tiles
        for i in range(NUM_COMPETENCY_TILES):
            self.innovation_display[i] = i


        # setup players
        for i in range(num_players):
            let player = make_player()
            player.build_free_workshop()
            player.build_free_workshop() 
            self.players.append(player)

        self.current_player = 0
    
    fun get_current_player() -> ref Player:
        return self.players[self.current_player.value]
    
    fun new_phase():
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
            player.urp_for_vp = urp_for_vp[self.phase.value]

        return


    fun pretty_print_state():
        let to_print : String
        let player_id = 0 
        print(self)
        print(self.players)
        print('\n')