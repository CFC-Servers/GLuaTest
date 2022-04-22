GLuaTest = {
    loader = include( "loader.lua" ),
    runner = include( "runner.lua" )
}

local testFiles = loader( "lua/tests/" )

hook.Add( "Tick", "GLuaTest_Runner", function()
    GLuaTest.runner( testFiles )
end )
