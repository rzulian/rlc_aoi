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

    fun can_send_scholar()->Bool:
        return self.first_space<4

    fun send_scholar( Int starting_level ) -> Int[2]:
        let space_value = [3,2,2,2,1]
        let space_power = [0,0,0,1,0,2,0,2,0,0,0,0,3,0,0,0]
        let steps = space_value[ self.first_space ]
 
        let power = 0
        for i in range( steps ) :
            power = power + space_power[ starting_level + 1 + i]
        self.first_space = min( self.first_space + 1, 4)
        return [ min(starting_level + steps, 12), power]

    fun return_scholar( Int starting_level ) -> Int[2]:
        let space_power = [0,0,0,1,0,2,0,2,0,0,0,0,3,0,0,0]
        let power = space_power[ starting_level + 1 ]
        return [ min(starting_level + 1, 12) , power]



fun make_discipline_track(DisciplineName discipline_name) -> DisciplineTrack:
    let discipline_track : DisciplineTrack
    discipline_track.discipline_name = discipline_name
    discipline_track.first_space = 0
    for i in range(5):
        discipline_track.spaces[i] = false

    return discipline_track
    

fun test_send_scholar() -> Bool:
    let d = make_discipline_track(DisciplineName::banking)
    let result : Int[2]
    result = d.send_scholar(0)
    assert ( result[0] == 3 and result[1] == 1 , "first scholar")

    result = d.send_scholar(3)
    assert ( result[0] == 5 and result[1] == 2 , "second scholar")

    result = d.send_scholar(5)
    assert ( result[0] == 7 and result[1] == 2 , "third scholar")
    assert (  d.can_send_scholar() == true, "only three scholars can send another one")

    result = d.send_scholar(0)
    assert ( result[0] == 2 and result[1] == 0 and d.first_space == 4, "another scholar" )
    assert (  d.can_send_scholar() == false, "fourth scholar no spaces")

    return true

fun test_return_scholar() -> Bool:
    let d = make_discipline_track(DisciplineName::banking)
    let result : Int[2]

    result = d.return_scholar(7)
    assert ( result[0] == 8 and d.first_space == 0, "send scholar")

    result = d.return_scholar(11)
    assert ( result[0] == 12 and result[1] == 3 and d.first_space == 0, "send scholar from 11")

    result = d.return_scholar(12)
    assert ( result[0] == 12 and result[1] == 0 and d.first_space == 0, "send scholar from 12")

    return true
