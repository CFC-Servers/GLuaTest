AddCSLuaFile()

GLuaTest = {
    loader = include( "gluatest/loader.lua" ),
    runner = include( "gluatest/runner.lua" )
}

local testFiles = GLuaTest.loader( "tests" )

hook.Add( "Tick", "GLuaTest_Runner", function()
    hook.Remove( "Tick", "GLuaTest_Runner" )
    GLuaTest.runner( testFiles )
end )

if SERVER then AddCSLuaFile( "gluatest/expectations.lua" ) end
