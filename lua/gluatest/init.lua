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

local shouldRun = CreateConVar( "gluatest_enable", 0, FCVAR_ARCHIVE + FCVAR_PROTECTED )

hook.Add( "Tick", "GLuaTest_Runner", function()
    hook.Remove( "Tick", "GLuaTest_Runner" )
    if not shouldRun:GetBool() then return end

    GLuaTest.runner( GLuaTest.testFiles )
end )
