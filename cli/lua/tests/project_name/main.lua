return {
    groupName = "MyProject",
    cases = {
        {
            name = "Should create project tables",
            func = function()
                expect(engine.ActiveGamemode()).to.equal("terrortown")
                expect(util).to.exist()
            end
        },
    }
}
