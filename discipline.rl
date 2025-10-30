import bounded_arg
import collections.vector
import range
import math.numeric

enum DisciplineName:
    banking
    law
    engineering
    medicine

    fun equal(DisciplineName other) -> Bool:
        return self.value == other.value

const NUM_SPACES_PER_DISCIPLINE = 4

cls DisciplineTrack:
    DisciplineName discipline_name
    Bool[5] spaces
    Int first_space 

    fun power_from_track( Int starting_level, Int steps) -> Int:
        let level_power = [0,0,0,1,0,2,0,2,0,0,0,0,3,0,0,0]
        let power = 0
        for i in range( steps ) :
            power = power + level_power[ starting_level + 1 + i]
        return power

    fun next_level( Int starting_level, Int steps)-> Int:
        return min(starting_level + steps, 12)

    fun steps_for_send_scholar() -> Int:
        let space_value = [3,2,2,2,0]
        return space_value[ self.first_space ]

    fun can_send_scholar()->Bool:
        return self.first_space < NUM_SPACES_PER_DISCIPLINE

    fun send_scholar() -> Void:
        self.first_space = min(self.first_space + 1, NUM_SPACES_PER_DISCIPLINE)
        



fun make_discipline_track(DisciplineName discipline_name) -> DisciplineTrack:
    let discipline_track : DisciplineTrack
    discipline_track.discipline_name = discipline_name
    discipline_track.first_space = 0
    for i in range(5):
        discipline_track.spaces[i] = false

    return discipline_track
    

fun test_send_scholar() -> Bool:
    let d = make_discipline_track(DisciplineName::banking)
    
    assert ( d.first_space == 0 , "first space is empty")
    let steps = d.steps_for_send_scholar()
    assert ( steps == 3 and d.power_from_track(0, steps) == 1 , "first scholar")
    d.send_scholar()

    assert ( d.first_space == 1 , "second space is empty")
    let steps2 = d.steps_for_send_scholar()
    assert ( steps2 == 2 and d.power_from_track(3, steps2) == 2, "second scholar")
    d.send_scholar()

    assert ( d.first_space == 2 , "third space is empty")
    let steps3 = d.steps_for_send_scholar()
    assert ( steps3 == 2 and d.power_from_track(5, steps3) == 2, "third scholar")
    d.send_scholar()

    assert ( d.first_space == 3 , "fourth space is empty")
    let steps4 = d.steps_for_send_scholar()
    assert ( steps4 == 2 and d.power_from_track(7, steps4) == 0, "fourth scholar")
    d.send_scholar()

    assert (d.can_send_scholar() == false, "cannot send another scholar")


    return true
