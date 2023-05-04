return {
    groupName = "MyProject",
    cases = {
        {
            name = "Should create project tables",
            func = function()
                expect( util ).to.exist()
            end
        },
        {
            name = "Should not load modules automatically",
            func = function()
                expect( MyProject ).to.beNil()
            end
        }
    }
}
