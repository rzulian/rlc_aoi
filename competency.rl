import bounded_arg
import collections.vector
import range
import player
import discipline
import enum_range

const NUM_COMPETENCY_TILES_KIND = 12

enum CompetencyTileKind:
    neutral_tower
    neutral_annexes
    4power
    lowest_science_vp
    city_tile_vp
    2spades
    1book_1power
    send_scholar_vp
    2coins_3vp
    build_workshop_border
    1tool_2coins_5vp
    1tool_1science_adv

    fun get(Int id) -> CompetencyTileKind:
        let to_return :  CompetencyTileKind
        to_return.value = id
        return to_return

    fun equal(CityTileKind other) -> Bool:
        return self.value == other.value

cls InnovationDisplay:
    CompetencyTileKind competency_tile
    Int num_tiles
    DisciplineName discipline_name
    Int level

cls CompetencyTiles:
    InnovationDisplay[NUM_COMPETENCY_TILES_KIND] display

    fun init():
        let k: CompetencyTileKind
        for kind in range(CompetencyTileKind::neutral_tower):
            self.num_tiles[kind.value] = 3

    fun get( CompetencyTileKind kind) -> InnovationDisplay:
        return self.num_tiles[kind.value].value

    fun draw_city_tile( CompetencyTileKind kind) :
        self.num_tiles[kind.value] = self.num_tiles[kind.value] - 1

    fun has_competency_tile( CompetencyTileKind kind ) -> Bool:
        return self.num_tiles[kind.value] > 0

fun make_competency_tiles() -> CompetencyTiles:
    let tiles : CompetencyTiles
    return tiles
