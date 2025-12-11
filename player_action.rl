import bounded_arg
import collections.vector
import range
import discipline

enum Action:
    workshop
    guild
    school
    big
    send_scholar
    spade
    science_step
    city
    sailing_terraforming
    innovation_tile
    workshop_on_border


    fun equal(Action other) -> Bool:
        return self.value == other.value
