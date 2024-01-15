local RED = Color( 255, 0, 0 )

GLuaTest = {
    -- If, for some reason, you need to run GLuaTest clientside, set this to true
    RUN_CLIENTSIDE = false,

    DeprecatedNotice = function( old, new )
        local msg = [[GLuaTest: (DEPRECATION NOTICE) "]] .. old .. [[" is deprecated, use "]] .. new .. [[" instead.]]
        if SERVER then MsgC( RED, msg .. "\n" ) end
    end
}

if GLuaTest.RUN_CLIENTSIDE then
    AddCSLuaFile()
    AddCSLuaFile( "gluatest/loader.lua" )

    AddCSLuaFile( "gluatest/expectations/expect.lua" )
    AddCSLuaFile( "gluatest/expectations/positive.lua" )
    AddCSLuaFile( "gluatest/expectations/negative.lua" )

    AddCSLuaFile( "gluatest/stubs/stubMaker.lua" )

    AddCSLuaFile( "gluatest/runner/runner.lua" )
    AddCSLuaFile( "gluatest/runner/colors.lua" )
    AddCSLuaFile( "gluatest/runner/logger.lua" )
    AddCSLuaFile( "gluatest/runner/helpers.lua" )
    AddCSLuaFile( "gluatest/runner/log_helpers.lua" )
    AddCSLuaFile( "gluatest/runner/msgc_wrapper.lua" )
end

CreateConVar( "gluatest_use_ansi", 1, FCVAR_ARCHIVE, "Should GLuaTest use ANSI coloring in its output", 0, 1 )

GLuaTest.loader = include( "gluatest/loader.lua" )
GLuaTest.runner = include( "gluatest/runner/runner.lua" )

local shouldRun = CreateConVar( "gluatest_enable", 0, FCVAR_ARCHIVE + FCVAR_PROTECTED )

local function loadAllProjectsFrom( path, testFiles )
    local _, projects = file.Find( path .. "/*", "LUA" )

    for i = 1, #projects do
        local project = projects[i]
        table.Add( testFiles, GLuaTest.loader( path .. "/" .. project ) )
    end
end

GLuaTest.runAllTests = function()
    if not shouldRun:GetBool() then return end

    local testPaths = {
        "tests",
        GAMEMODE.FolderName .. "/gamemode/tests"
    }
    hook.Run( "GLuaTest_AddTestPaths", testPaths )

    local testFiles = {}
    for i = 1, #testPaths do
        local path = testPaths[i]
        loadAllProjectsFrom( path, testFiles )
    end

    hook.Run( "GLuaTest_RunTestFiles", testFiles )

    GLuaTest.runner( testFiles )
end

hook.Add( "Tick", "GLuaTest_Runner", function()
    hook.Remove( "Tick", "GLuaTest_Runner" )
    GLuaTest.runAllTests()
end )

concommand.Add( "gluatest_run_tests", function( ply )
    if ply and IsValid( ply ) then return end
    GLuaTest.runAllTests()
end, nil, "Run all tests in the tests/ directory", FCVAR_PROTECTED )
