import bounded_arg
import collections.vector
import range
import discipline
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

    fun init():
        for i in range(NUM_COMPETENCY_TILES_KIND):
            self.space[i].num_tiles = 4

    fun get(CompetencyTileKind kind) -> ref CompetencySpace:
        return self.space[kind.value]

    fun has_competency_tile(CompetencyTileKind kind) -> Bool:
        return self.space[kind.value].num_tiles > 0

    fun distribute_competency_tiles():
        # this is the standard distribution of competencies
        let discipline : Discipline

        for tile_idx in range(NUM_COMPETENCY_TILES_KIND):
            let discipline_id = tile_idx / 3
            let level = tile_idx % 3
            self.space[tile_idx].level = level
            self.space[tile_idx].discipline = discipline[discipline_id]

    fun distribute_scenario_std():
        # equally distribute on level 1
        #TODO some tiles are not assigned to a discipline, but they should
        for tile_idx in range(NUM_COMPETENCY_TILES_KIND):
            self.space[tile_idx].level = 1
        self[CompetencyTileKind::book_power].discipline = Discipline::banking
        self[CompetencyTileKind::lowest_science_vp].discipline = Discipline::banking
        self[CompetencyTileKind::coins2_vp3].discipline = Discipline::law
        self[CompetencyTileKind::send_scholar_vp].discipline = Discipline::law
        self[CompetencyTileKind::spades2].discipline = Discipline::engineering
        self[CompetencyTileKind::city_vp].discipline = Discipline::engineering
        self[CompetencyTileKind::tool_science_adv].discipline = Discipline::medicine
        self[CompetencyTileKind::tool_coins2_vp5].discipline = Discipline::medicine




fun test_standard_distribution()->Bool:
    let tiles : CompetencyTiles
    tiles.distribute_competency_tiles()
    print(tiles)
    return true
