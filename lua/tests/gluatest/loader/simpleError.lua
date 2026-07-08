return {
    groupName = "simpleError",

    beforeEach = function( state )
        state.Loader = include( "gluatest/loader.lua" )
    end,

    cases = {
        {
            name = "Handles errors without a file prefix",
            func = function( state )
                local errInfo = state.Loader.simpleError( "plain failure", "tests/project/file.lua" )

                expect( errInfo.reason ).to.equal( "plain failure" )
                expect( errInfo.sourceFile ).to.equal( "tests/project/file.lua" )
                expect( errInfo.lineNumber ).to.equal( -1 )
            end
        },
        {
            name = "Trims prefixed file errors",
            func = function( state )
                local errInfo = state.Loader.simpleError( "tests/project/file.lua:12: prefixed failure", "tests/project/file.lua" )

                expect( errInfo.reason ).to.equal( "12: prefixed failure" )
            end
        }
    }
}
