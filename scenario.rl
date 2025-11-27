enum Scenario:
    default
    sc1
    test

    fun equal(Scenario other) -> Bool:
        return self.value == other.value
