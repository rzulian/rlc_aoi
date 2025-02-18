import bounded_arg
import collections.vector
import range

enum DisciplineName:
    banking
    law
    engineering
    medicine

    fun equal(DisciplineName other) -> Bool:
        return self.value == other.value


cls DisciplineTrack:
    DisciplineName discipline_name
    Bool[5] spaces
    Int first_space 

    fun power_from_track( Int starting_level, Int steps) -> Int:
        let space_power = [0,0,0,1,0,2,0,2,0,0,0,0,3,0,0,0]
        let power = 0
        for i in range( steps ) :
            power = power + space_power[ starting_level + 1 + i]
        return power

    fun next_level( Int starting_level, Int steps)-> Int:
        return min(starting_level + steps, 12)

    fun steps_for_send_scholar() -> Int:
        let space_value = [3,2,2,2,1]
        return space_value[ self.first_space ]

    fun can_send_scholar()->Bool:
        return self.first_space<4

    fun send_scholar() -> Void:
        self.first_space = min(self.first_space + 1, 4)



fun make_discipline_track(DisciplineName discipline_name) -> DisciplineTrack:
    let discipline_track : DisciplineTrack
    discipline_track.discipline_name = discipline_name
    discipline_track.first_space = 0
    for i in range(5):
        discipline_track.spaces[i] = false

    return discipline_track
    

fun test_send_scholar() -> Bool:
    let d = make_discipline_track(DisciplineName::banking)
    
    let steps = d.steps_for_send_scholar()
    assert ( steps == 3 and d.power_from_track(0, steps) == 1 , "first scholar")
    d.send_scholar()
    return true
