GLuaTest = {
    -- If, for some reason, you need to run GLuaTest clientside, set this to true
    RUN_CLIENTSIDE = false
}

if GLuaTest.RUN_CLIENTSIDE then
    AddCSLuaFile()
    AddCSLuaFile( "gluatest/loader.lua" )
    AddCSLuaFile( "gluatest/expectations.lua" )

    AddCSLuaFile( "gluatest/runner/runner.lua" )
    AddCSLuaFile( "gluatest/runner/helpers.lua" )
    AddCSLuaFile( "gluatest/runner/log_helpers.lua" )
    AddCSLuaFile( "gluatest/runner/msgc_wrapper.lua" )
    AddCSLuaFile( "gluatest/runner/result_logger.lua" )
end

GLuaTest.loader = include( "gluatest/loader.lua" )
GLuaTest.runner = include( "gluatest/runner/runner.lua" )

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
