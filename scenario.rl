enum Scenario:
    default
    sc1

    fun equal(Scenario other) -> Bool:
        return self.value == other.value
