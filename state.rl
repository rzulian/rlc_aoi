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
import round_bonus_tile

const FINAL_ROUND = 5

using PlayerID = BInt<0, 5>

cls State:
    Board board
    BInt<1,5> num_players
    BoundedVector<Player, 4> players
    PlayerID current_player
    BoundedVector<PlayerID, 4> original_turn_order
    BoundedVector<PlayerID, 4> turn_order
    BoundedVector<PlayerID, 4> passed_turn_order
    Int turn_order_pos
    BInt<0, 8> round
    Bool is_done
    Bool power_action_scholar
    Bool power_action_2tools
    Bool power_action_7coins
    Bool power_action_1spade
    Bool power_action_2spades
    DisciplineTracks discipline_tracks
    CompetencyTiles competency_tiles
    CityTiles city_tiles
    PalaceTiles palace_tiles
    RoundScoreDisplay round_score_display
    RoundBonusTiles round_bonus_tiles
    Scenario scenario


    fun setup_game(Int num_players, Scenario scenario):
        self.scenario = scenario
        self.board = make_board()
        self.round = 0
        self.is_done = false
        self.num_players = num_players

        self.discipline_tracks = make_discipline_tracks()
        self.city_tiles = make_city_tiles()
        self.competency_tiles = make_competency_tiles(Scenario::sc1)
        self.palace_tiles = make_palace_tiles()
        self.round_score_display = make_round_score_display()
        self.round_bonus_tiles = make_round_bonus_tiles(scenario)


        # setup players
        for i in range(self.num_players.value):
            let player = make_player()
            player.build_free_workshop()
            player.build_free_workshop()
            self.players.append(player)
            let index : PlayerID
            index = i
            self.original_turn_order.append(index) #TODO shuffle


    fun reset_turn_order():
        self.turn_order = self.original_turn_order
        self.passed_turn_order.clear()
        self.turn_order_pos = 0

    fun move_to_first_player():
        self.turn_order_pos = 0

    fun has_players_in_turn_order()->Bool:
        return self.turn_order.size()>0

    fun mark_current_player_passed():
        #current player has played, we remove it from the list
        #move it to the pass_order_turn
        #keep the pos to the current position
        self.passed_turn_order.append(self.turn_order.get(self.turn_order_pos))
        self.turn_order.erase(self.turn_order_pos)
        if self.turn_order_pos==self.turn_order.size(): #if last player passed
            self.move_to_first_player()

    fun move_to_next_player():
        self.turn_order_pos = (self.turn_order_pos + 1) % self.turn_order.size()

    fun get_current_player() -> ref Player:
        return self.players[self.turn_order[self.turn_order_pos].value]
    
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
            player.has_passed = false
        return

    fun get_round_score_bonus(Action action) -> Int:
        let frs_bonus = 0
        if self.round.value == FINAL_ROUND:
            frs_bonus = self.round_score_display.final_round_score_tile.action_bonus(action)

        return frs_bonus + self.round_score_display[self.round.value].action_bonus(action)

    fun get_round_score_tile_end_round_bonus():
        #no round bonus in final round
        if self.round.value == FINAL_ROUND:
            return
        let round_score_tile = self.round_score_display[self.round.value]
        for player in self.players:
            let level = player.discipline_level[round_score_tile.discipline().value]
            let multiplier = level.value / round_score_tile.steps()
            player.gain_tool(multiplier*round_score_tile.end_round_bonus(Resource::tool))
            player.gain_coin(multiplier*round_score_tile.end_round_bonus(Resource::coin))
            player.gain_power(multiplier*round_score_tile.end_round_bonus(Resource::power))
            player.gain_scholar(multiplier*round_score_tile.end_round_bonus(Resource::scholar))
            player.book_income = player.book_income + multiplier*round_score_tile.end_round_bonus(Resource::book)
            player.gain_spade(multiplier*round_score_tile.end_round_bonus(Resource::spade))


    fun pretty_print_state():
        let to_print : String
        let player_id = 0 
        print(self)
        print(self.players)
        print('\n')


fun test_turn_order()->Bool:
    let state : State
    state.setup_game(4, Scenario::sc1)

    state.reset_turn_order()
    state.move_to_next_player() #to player 1
    state.mark_current_player_passed()
    assert( state.passed_turn_order.get(0) == 1, "player 1 passed")
    state.move_to_next_player() #to player 3
    state.mark_current_player_passed()
    assert( state.passed_turn_order.get(1) == 3, "player 3 passed")
    state.mark_current_player_passed() # player 0
    state.mark_current_player_passed() # player 2
    assert( state.passed_turn_order.get(2) == 0, "player 0 passed")
    assert( state.passed_turn_order.get(3) == 2, "player 2 passed")

    state.original_turn_order = state.passed_turn_order
    state.reset_turn_order()
    state.mark_current_player_passed()
    assert( state.passed_turn_order.get(0) == 1, "player 1 pos 0 passed")
    assert( state.original_turn_order.get(0) == 1, "stil player 1")
    assert( state.turn_order.get(0) == 3, "new player is 3")
    return true

