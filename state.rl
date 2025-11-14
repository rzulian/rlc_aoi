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
import scenario
import round_score_tile

const FINAL_ROUND = 5

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
    Bool book_action_3spades
    DisciplineTracks discipline_tracks
    CompetencyTiles competency_tiles
    CityTiles city_tiles
    PalaceTiles palace_tiles
    RoundScoreDisplay round_score_display

    fun setup_game(Int num_players):
        self.board = make_board()
        self.round = 0
        self.is_done = false

        self.discipline_tracks = make_discipline_tracks()
        self.city_tiles = make_city_tiles()
        self.competency_tiles = make_competency_tiles(Scenario::sc1)
        self.palace_tiles = make_palace_tiles()
        self.round_score_display = make_round_score_display()

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
        # book actions return available
        self.book_action_3spades= true

        #assign urp_for_vp
        for player in self.players:
            player.urp_for_vp = urp_for_vp[self.round.value]

        return

    fun get_round_score_bonus(ActionBonus action) -> Int:
        let frs_bonus = 0
        if self.round.value == FINAL_ROUND:
            frs_bonus = self.round_score_display.final_round_score_tile.action_bonus()[action.value]

        return frs_bonus + self.round_score_display[self.round.value].action_bonus()[action.value]

    fun get_round_score_tile_end_round_bonus():
        #no round bonus in final round
        if self.round.value == FINAL_ROUND:
            return
        let round_score_tile = self.round_score_display[self.round.value]
        for player in self.players:
            let level = player.discipline_level[round_score_tile.discipline().value]
            let multiplier = level.value / round_score_tile.steps()
            player.gain_tool(multiplier*round_score_tile.end_round_bonus()[0])
            player.gain_coin(multiplier*round_score_tile.end_round_bonus()[1])
            player.gain_power(multiplier*round_score_tile.end_round_bonus()[2])
            player.gain_scholar(multiplier*round_score_tile.end_round_bonus()[3])
            player.book_income = player.book_income + multiplier*round_score_tile.end_round_bonus()[4]
            player.gain_spade(multiplier*round_score_tile.end_round_bonus()[5])


    fun pretty_print_state():
        let to_print : String
        let player_id = 0 
        print(self)
        print(self.players)
        print('\n')