return {
    groupName = "filterTestGroups",

    beforeEach = function( state )
        state.Loader = include( "gluatest/loader.lua" )

        state.rankFile = { project = "myaddon/ranks", fileName = "getRank.lua", groupName = "Rank lookup", cases = {} }
        state.shopFile = { project = "myaddon/shop", fileName = "buy.lua", groupName = "Purchasing", cases = {} }
        state.unnamedFile = { project = "other", fileName = "misc.lua", cases = {} }
        state.groups = { state.rankFile, state.shopFile, state.unnamedFile }
    end,

    cases = {
        {
            name = "Keeps every group when the filter is empty or only whitespace",
            func = function( state )
                local filterTestGroups = state.Loader.filterTestGroups

                expect( filterTestGroups( state.groups, "" ) ).to.equal( state.groups )
                expect( filterTestGroups( state.groups, "   " ) ).to.equal( state.groups )
            end
        },

        {
            name = "Matches a term against the project path and file name",
            func = function( state )
                local filterTestGroups = state.Loader.filterTestGroups

                expect( filterTestGroups( state.groups, "myaddon" ) ).to.deepEqual( { state.rankFile, state.shopFile } )
                expect( filterTestGroups( state.groups, "ranks/getRank.lua" ) ).to.deepEqual( { state.rankFile } )
                expect( filterTestGroups( state.groups, "misc" ) ).to.deepEqual( { state.unnamedFile } )
            end
        },

        {
            name = "Matches a term against the group name",
            func = function( state )
                local matching = state.Loader.filterTestGroups( state.groups, "Purchasing" )

                expect( matching ).to.deepEqual( { state.shopFile } )
            end
        },

        {
            name = "Ignores case and surrounding quotes",
            func = function( state )
                local matching = state.Loader.filterTestGroups( state.groups, "\"GETRANK\"" )

                expect( matching ).to.deepEqual( { state.rankFile } )
            end
        },

        {
            name = "Keeps a group that matches any one of several terms",
            func = function( state )
                local matching = state.Loader.filterTestGroups( state.groups, "buy  misc nothing" )

                expect( matching ).to.deepEqual( { state.shopFile, state.unnamedFile } )
            end
        },

        {
            name = "Treats pattern characters as plain text",
            func = function( state )
                local filterTestGroups = state.Loader.filterTestGroups

                expect( filterTestGroups( state.groups, "." ) ).to.deepEqual( state.groups )
                expect( filterTestGroups( state.groups, "%a+" ) ).to.deepEqual( {} )
            end
        },

        {
            name = "Returns no groups when nothing matches",
            func = function( state )
                local matching = state.Loader.filterTestGroups( state.groups, "doesnotexist" )

                expect( matching ).to.deepEqual( {} )
            end
        },
    }
}
