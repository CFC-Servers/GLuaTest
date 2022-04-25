AddCSLuaFile()

GLuaTest = {
    loader = include( "gluatest/loader.lua" ),
    runner = include( "gluatest/runner.lua" )
}

local _, projects = file.Find( "tests/*", "LUA" )
local testFiles = {}

for i = 1, #projects do
    local project = projects[i]
    table.Add( testFiles, GLuaTest.loader( "tests/" .. project ) )
end

GLuaTest.testFiles = testFiles

hook.Add( "Tick", "GLuaTest_Runner", function()
    hook.Remove( "Tick", "GLuaTest_Runner" )
    GLuaTest.runner( GLuaTest.testFiles )
end )

if SERVER then AddCSLuaFile( "gluatest/expectations.lua" ) end
