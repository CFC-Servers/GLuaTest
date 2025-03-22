local RED = Color( 255, 0, 0 )

--- @class GLuaTest
GLuaTest = {
    -- If, for some reason, you need to run GLuaTest clientside, set this to true (not very well supported)
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

-- TOOD: Unnecessary with the new colored output changes?
CreateConVar( "gluatest_use_ansi", "1", FCVAR_ARCHIVE, "Should GLuaTest use ANSI coloring in its output", 0, 1 )

local shouldRun = CreateConVar( "gluatest_enable", "0", FCVAR_ARCHIVE + FCVAR_PROTECTED )
local shouldSelfTest = CreateConVar( "gluatest_selftest_enable", "0", FCVAR_ARCHIVE + FCVAR_PROTECTED )

--- @param loader GLuaTest_Loader
--- @param projectName string
--- @param path string
--- @param testFiles GLuaTest_TestGroup[]
local function addTestFiles( loader, projectName, path, testFiles )
    if projectName == "gluatest" and not shouldSelfTest:GetBool() then
        return
    end

    local tests = loader.getTestsInDir( path .. "/" .. projectName )
    table.Add( testFiles, tests )
end

--- Loads all GLuaTest-compatible projects from a given path
--- @param loader GLuaTest_Loader
--- @param path string The path to load projects from (in the LUA mount point)
--- @param testFiles GLuaTest_TestGroup[] The table to add the loaded test files to
local function loadAllProjectsFrom( loader, path, testFiles )
    local _, projects = file.Find( path .. "/*", "LUA" )

    for i = 1, #projects do
        local projectName = projects[i]
        addTestFiles( loader, projectName, path, testFiles )
    end
end

--- Attempts the read the version of GLuaTest
--- First checks data_static/gluatest_version.txt (when running in docker)
--- Then, attempts to read the git commit of the cloned GLuaTest repository
--- Then, gives up
--- local function getGLuaTestVersion()
--- end

--- Loads and runs all tests in the tests/ directory
GLuaTest.runAllTests = function()
    if not shouldRun:GetBool() then
        print( "[GLuaTest] Test runs are disabled. Enable them with: gluatest_enable 1" )
        return
    end

    --- @type GLuaTest_Loader
    local Loader = include( "gluatest/loader.lua" )
    Loader.loadExtensions( "gluatest/extensions" )

    local testPaths = {
        "tests",
        GAMEMODE.FolderName .. "/gamemode/tests"
    }
    hook.Run( "GLuaTest_AddTestPaths", testPaths )

    --- @type GLuaTest_TestGroup[]
    local testFiles = {}

    for i = 1, #testPaths do
        local path = testPaths[i]
        loadAllProjectsFrom( Loader, path, testFiles )
    end

    hook.Run( "GLuaTest_RunTestFiles", testFiles )

    --- @type GLuaTest_TestRunner
    local runner = include( "gluatest/runner/runner.lua" )
    runner:Run( testFiles )
end

hook.Add( "Tick", "GLuaTest_Runner", function()
    hook.Remove( "Tick", "GLuaTest_Runner" )
    GLuaTest.runAllTests()
end )

concommand.Add( "gluatest_run_tests", function()
    GLuaTest.runAllTests()
end, nil, "Run all tests in the tests/ directory", { FCVAR_PROTECTED } )
