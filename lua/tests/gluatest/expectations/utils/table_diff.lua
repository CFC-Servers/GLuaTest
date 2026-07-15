local GetDiff = include( "gluatest/expectations/utils/table_diff.lua" )

return {
    groupName = "Table Diff",

    cases = {
        {
            name = "Formats boolean keys in diff paths",
            func = function()
                local isDifferent, path = GetDiff( { [true] = 1 }, { [true] = 2 } )

                expect( isDifferent ).to.beTrue()
                expect( path ).to.equal( "tableA[true]" )
            end
        }
    }
}
