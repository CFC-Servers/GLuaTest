return {
    groupName = "getProjectName",
    beforeEach = function( state )
        state.Loader = include( "gluatest/loader.lua" )
    end,

    cases = {
        {
            name = "Exists on the Loader table",
            func = function( state )
                local Loader = state.Loader

                expect( Loader.getProjectName ).to.beA( "function" )
            end
        },

        {
            name = "Returns the project name",
            func = function( state )
                local Loader = state.Loader
                local getProjectName = Loader.getProjectName

                expect( getProjectName( "addons/testAddon/lua/tests/project1/file1.lua" ) ).to.equal( "project1" )
                expect( getProjectName( "tests/project1/file1.lua" ) ).to.equal( "project1" )
                expect( getProjectName( "tests/project2/module/file2.lua" ) ).to.equal( "project2/module" )
                expect( getProjectName( "adskfjadslfjdaslfadskj" ) ).to.equal( nil )
            end
        }

    }
}
