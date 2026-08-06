local fileHandle = file.Open( "garrysmod_branch.txt", "rb", "MOD" ) --[[@as File]]
if fileHandle then -- NOTE: This file is created in our docker file / BRANCH will only be accurate inside of the Docker images
    BRANCH = fileHandle:ReadLine() -- prerelease shows unknown instead of prerelease as BRANCH. Not useful for tests.
    BRANCH = string.Trim( BRANCH )
    fileHandle:Close()
end

local RED = Color( 255, 0, 0 )

--- @type VersionTools
local VersionTools = include( "utils/version.lua" )

local conVarFlags = bit.bor( FCVAR_ARCHIVE, FCVAR_PROTECTED )

local isHotload = GLuaTest ~= nil
--- @class GLuaTest
GLuaTest = {
    --- @diagnostic disable-next-line: param-type-mismatch
    RunServersideConVar = CreateConVar( "gluatest_server_enable",   "1", conVarFlags, "Should GLuaTest run automatically on the server side?" ),
    --- @diagnostic disable-next-line: param-type-mismatch
    RunClientsideConVar = CreateConVar( "gluatest_client_enable",   "0", conVarFlags, "Should GLuaTest run automatically on the client side?" ),
    --- @diagnostic disable-next-line: param-type-mismatch
    SelfTestConVar      = CreateConVar( "gluatest_selftest_enable", "0", conVarFlags, "Should GLuaTest run its own tests?" ),
    --- @diagnostic disable-next-line: param-type-mismatch
    HttpHelloConVar     = CreateConVar( "gluatest_http_hello", "1", conVarFlags, "Should GLuaTest ping the GLuaTest hello endpoint?" ),

    DeprecatedNotice = function( old, new )
        local msg = [[GLuaTest: (DEPRECATION NOTICE) "]] .. old .. [[" is deprecated, use "]] .. new .. [[" instead.]]
        if SERVER then MsgC( RED, msg .. "\n" ) end
    end
}

--[[ Set Up Client Testing ]] do
    if SERVER then
        util.AddNetworkString( "GLuaTest_RunClientTests" )

        -- /*
        AddCSLuaFile( "gluatest/init.lua" )
        AddCSLuaFile( "gluatest/loader.lua" )
        AddCSLuaFile( "gluatest/types.lua" )

        -- /util/*
        AddCSLuaFile( "gluatest/utils/git_tools.lua" )
        AddCSLuaFile( "gluatest/utils/version.lua" )

        -- /stubs/*
        AddCSLuaFile( "gluatest/stubs/stub_maker.lua" )

        -- /runner/*
        AddCSLuaFile( "gluatest/runner/colors.lua" )
        AddCSLuaFile( "gluatest/runner/helpers.lua" )
        AddCSLuaFile( "gluatest/runner/log_helpers.lua" )
        AddCSLuaFile( "gluatest/runner/logger.lua" )
        AddCSLuaFile( "gluatest/runner/runner.lua" )
        AddCSLuaFile( "gluatest/runner/test_case_runner.lua" )
        AddCSLuaFile( "gluatest/runner/test_group_runner.lua" )

        -- /expectations/*
        AddCSLuaFile( "gluatest/expectations/expect.lua" )
        AddCSLuaFile( "gluatest/expectations/negative.lua" )
        AddCSLuaFile( "gluatest/expectations/positive.lua" )

        -- /expectations/utils/*
        AddCSLuaFile( "gluatest/expectations/utils/table_diff.lua" )

        -- When the server finishes its tests, notify clients to start theirs
        -- While it is possible to run client and server tests in parallel, that may lead to
        -- undesirable side-effects or conflicts.
        hook.Add( "GLuaTest_Finished", "GLuaTest_RunClientTests", function()
            -- Give the server tests a moment to finish so the console messages on local servers don't get mixed together
            timer.Simple( 0.1, function()
                if GLuaTest.RunClientsideConVar:GetBool() then
                    net.Start( "GLuaTest_RunClientTests" )
                    net.Broadcast()
                end
            end )
        end )
    end

    if CLIENT then
        -- Run clientside tests when the server asks 
        net.Receive( "GLuaTest_RunClientTests", function( _, _ )
            if not GLuaTest then
                error( "[GLuaTest] Client tests are attempting to run before GLuaTest has initialized" )
            end

            GLuaTest.runAllTests()
        end )
    end
end

--- Encodes a string for use in a URL param
--- @param str string
local function urlEncode( str )
    if not str then return "" end

    str = string.gsub( str, "([^%w%-%._~])", function( c )
        return string.format( "%%%02X", string.byte( c ) )
    end )

    return str
end

--- Runs a simple ping against the GLuatest Hello endpoint
--- (Helps us get a rough idea of how many people use GLuaTest, as well as preserving HTTP during container minification)
--- @param version string
local function httpHello( version )
    local shouldRun = GLuaTest.HttpHello:GetBool()
    if not shouldRun then return end

    HTTP( {
        method = "GET",
        url = "https://hello.gluatest.com?version=" .. urlEncode( version ),
        success = function() end,
        failed = function() end,
    } )
end

--- @param loader GLuaTest_Loader
--- @param projectName string
--- @param path string
--- @param testFiles GLuaTest_TestGroup[]
local function addTestFiles( loader, projectName, path, testFiles )
    if projectName == "gluatest" and not GLuaTest.SelfTestConVar:GetBool() then
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

--- Loads and runs all tests in the tests/ directory
GLuaTest.runAllTests = function()
    local shouldRunServerside = GLuaTest.RunServersideConVar:GetBool()
    local shouldRunClientside = GLuaTest.RunClientsideConVar:GetBool()

    if SERVER and not shouldRunServerside then
        -- Alert the client immediately if we are skipping server tests and are still running client tests
        if shouldRunClientside then
            net.Start( "GLuaTest_RunClientTests" )
            net.Broadcast()
        end

        if not shouldRunClientside then
            print( "[GLuaTest] Test runs are disabled clientside and serverside. Enable them with gluatest_server_enable 1 and/or gluatest_client_enable 1" )
        end

        return
    end

    GLuaTest.VERSION = VersionTools.getVersion()

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

    httpHello( GLuaTest.VERSION )

    --- @type GLuaTest_TestRunner
    local runner = include( "gluatest/runner/runner.lua" )
    runner:Run( testFiles )
end

-- Automatically run tests when loading into a map
if not isHotload then
    hook.Add( "Tick", "GLuaTest_Runner", function()
        hook.Remove( "Tick", "GLuaTest_Runner" )
        GLuaTest.runAllTests()
    end )
end

--- @diagnostic disable-next-line: param-type-mismatch
concommand.Add( "gluatest_run_tests", GLuaTest.runAllTests, nil, "Run all tests in the tests/ directory", FCVAR_PROTECTED )
