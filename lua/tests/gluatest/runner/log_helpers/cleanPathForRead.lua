local LogHelpers = include( "gluatest/runner/log_helpers.lua" )
local cleanPathForRead = LogHelpers.cleanPathForRead

return {
    groupName = "cleanPathForRead",

    cases = {
        {
            name = "Exists on the LogHelpers table",
            func = function()
                expect( LogHelpers.cleanPathForRead ).to.beA( "function" )
            end
        },

        {
            name = "Converts path from addons directory",
            func = function()
                local path = "addons/addon_name/lua/tests/addon_name/test.lua"
                local result = cleanPathForRead( path )
                expect( result ).to.equal( "tests/addon_name/test.lua" )
            end
        },

        {
            name = "Converts path from gamemodes directory",
            func = function()
                local path = "gamemodes/darkrp/gamemode/tests/darkrp/main.lua"
                local result = cleanPathForRead( path )
                expect( result ).to.equal( "darkrp/gamemode/tests/darkrp/main.lua" )
            end
        },

        {
            name = "Handles path with subdirectories after lua",
            func = function()
                local path = "lua/project/module/tests/test_file.lua"
                local result = cleanPathForRead( path )
                expect( result ).to.equal( "project/module/tests/test_file.lua" )
            end
        },

        {
            name = "Returns path when 'lua' is root directory",
            func = function()
                local path = "lua/test.lua"
                local result = cleanPathForRead( path )
                expect( result ).to.equal( "test.lua" )
            end
        },
        {
            name = "Returns path when 'gamemodes' is root directory",
            func = function()
                local path = "gamemodes/othergamemode/file.lua"
                local result = cleanPathForRead( path )
                expect( result ).to.equal( "othergamemode/file.lua" )
            end
        },
        {
            name = "Errors on incomplete path following lua",
            func = function()
                local path = "addons/lua"
                expect( cleanPathForRead, path ).to.err()
            end
        }
    }
}
