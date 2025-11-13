import bounded_arg
import collections.vector
import range
import discipline
import scenario
import enum_range


const NUM_COMPETENCY_TILES_KIND = 12

enum CompetencyTileKind:
    neutral_tower
    neutral_annexes
    power4
    lowest_science_vp
    city_vp
    spades2
    book_power
    send_scholar_vp
    coins2_vp3
    build_workshop_border
    tool_coins2_vp5
    tool_science_adv

    fun get(Int id) -> CompetencyTileKind:
        let to_return :  CompetencyTileKind
        to_return.value = id
        return to_return

    fun equal(CompetencyTileKind other) -> Bool:
        return self.value == other.value

cls CompetencySpace:
    Int num_tiles
    Discipline discipline
    Int level

    fun num_books() -> Int:
        return 2 - self.level

    fun num_levels() -> Int:
        return 1 + self.level

    fun draw_competency_tile():
        self.num_tiles = self.num_tiles  - 1

cls CompetencyTiles:
    CompetencySpace[NUM_COMPETENCY_TILES_KIND] space

    fun get(CompetencyTileKind kind) -> ref CompetencySpace:
        return self.space[kind.value]

    fun has_competency_tile(CompetencyTileKind kind) -> Bool:
        return self.space[kind.value].num_tiles > 0


fun make_competency_tiles(Scenario scenario)->CompetencyTiles:
    if scenario == Scenario::sc1:
        return make_scenario_1_competency_tiles()
    return make_standard_competency_tiles()

fun make_standard_competency_tiles()->CompetencyTiles:
        # this is the standard distribution of competencies
        let tiles : CompetencyTiles
        let discipline : Discipline
        for tile_idx in range(NUM_COMPETENCY_TILES_KIND):
            let discipline_id = tile_idx / 3
            let level = tile_idx % 3
            tiles.space[tile_idx].num_tiles = 4
            tiles.space[tile_idx].level = level
            tiles.space[tile_idx].discipline = discipline[discipline_id]
        return tiles

fun make_scenario_1_competency_tiles()->CompetencyTiles:
        # this is the scenario 1
        let tiles : CompetencyTiles
        let discipline : Discipline

        # equally distribute on level 1
        # some tiles are not assigned to a discipline -> assigned by default to the first discipline aka banking
        for tile_idx in range(NUM_COMPETENCY_TILES_KIND):
            tiles.space[tile_idx].level = 1
            tiles.space[tile_idx].num_tiles = 4

        tiles[CompetencyTileKind::book_power].discipline = Discipline::banking
        tiles[CompetencyTileKind::lowest_science_vp].discipline = Discipline::banking
        tiles[CompetencyTileKind::coins2_vp3].discipline = Discipline::law
        tiles[CompetencyTileKind::send_scholar_vp].discipline = Discipline::law
        tiles[CompetencyTileKind::spades2].discipline = Discipline::engineering
        tiles[CompetencyTileKind::city_vp].discipline = Discipline::engineering
        tiles[CompetencyTileKind::tool_science_adv].discipline = Discipline::medicine
        tiles[CompetencyTileKind::tool_coins2_vp5].discipline = Discipline::medicine
        return tiles


fun test_standard_distribution()->Bool:
    let tiles = make_competency_tiles(Scenario::default)
    return true
