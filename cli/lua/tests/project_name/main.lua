return {
    groupName = "MyProject",
    cases = {
        {
            name = "Should create project tables",
            func = function()
                expect(MyProject).to.exist()
            end
        },
    }
}
