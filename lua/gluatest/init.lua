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

--- filters a list of test groups based on targets
--- @param allTestGroups GLuaTest_RunnableTestGroup[] The list of all loaded test groups
--- @param targets string[] The list of targets to filter by
--- @return GLuaTest_RunnableTestGroup[] groupsToRun The filtered list of groups that match the targets
--- @return string[] unmatchedTargets The list of targets that did not match any group
local function filterTestGroupsByTargets( allTestGroups, targets )
    print( "[GLuaTest] Filtering loaded tests based on targets..." )

    --- @type table<string, GLuaTest_RunnableTestGroup>
    local groupLookupByIdentifier = {}
    for _, group in ipairs( allTestGroups ) do
        local identifiers = { group.project .. "/" .. group.fileName }

        if group.groupName then
            table.insert( identifiers, group.groupName )
            table.insert( identifiers, group.project .. "/" .. group.groupName )
        end

        for _, id in ipairs( identifiers ) do
            groupLookupByIdentifier[id] = group
        end
    end

    --- @type GLuaTest_RunnableTestGroup[]
    local groupsToRun = {}
    local groupsAddedLookup = {}
    local foundTargetsLookup = {}
    local unmatchedTargets = {}

    for _, target in ipairs( targets ) do
        local matchedGroup = groupLookupByIdentifier[target]
        if matchedGroup then
            if not groupsAddedLookup[matchedGroup] then
                table.insert( groupsToRun, matchedGroup )
                groupsAddedLookup[matchedGroup] = true
            end
            foundTargetsLookup[target] = true
        end
    end

    for _, originalTarget in ipairs( targets ) do
        if not foundTargetsLookup[originalTarget] then
            table.insert( unmatchedTargets, originalTarget )
        end
    end

    return groupsToRun, unmatchedTargets
end



--- Loads and runs tests, optionally filtering by targets
--- @param targets? string[] Optional list of targets (group names or project/file paths)
GLuaTest.runAllTests = function( targets )
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
    local allTestGroups = {}
    for _, path in ipairs( testPaths ) do
        loadAllProjectsFrom( Loader, path, allTestGroups )
    end

    hook.Run( "GLuaTest_RunTestFiles", allTestGroups )

    --- @type GLuaTest_RunnableTestGroup[]
    local groupsToRun
    --- @type string[]
    local unmatchedTargets = {}

    if targets and #targets > 0 then
        groupsToRun, unmatchedTargets = filterTestGroupsByTargets( allTestGroups, targets )
    else
        groupsToRun = allTestGroups
    end

    if #unmatchedTargets > 0 then
        local missed = ( #unmatchedTargets == #targets )
        local messagePrefix = missed and
            "No test groups matched the specified target( s ): '" or
            "The following specified target( s ) did not match any test groups: '"
        MsgC(
            RED,
            messagePrefix,
            table.concat( unmatchedTargets, "', '" ),
            "'\n"
         )
    end

    if #groupsToRun > 0 then
        --- @type GLuaTest_TestRunner
        local runner = include( "gluatest/runner/runner.lua" )
        runner:Run( groupsToRun )
    elseif targets and #targets > 0 then
        print( "[GLuaTest] No tests selected to run after filtering." )
    else
        print( "[GLuaTest] No tests found to run." )
    end
end

-- Automatically run tests when loading into a map
if not isHotload then
    hook.Add( "Tick", "GLuaTest_Runner", function()
        hook.Remove( "Tick", "GLuaTest_Runner" )
        GLuaTest.runAllTests()
    end )
end


--- Parses the argument string into a list of targets
--- @param args string? The raw argument string (  e.g., "group1, project2/file.lua , group3"  )
--- @return string[]? A list of trimmed target identifiers, or nil if args is empty
local function parseTargets( args )
    if not args or args == "" then return nil end

    local rawTargets = string.Split( args, "," )
    local targets = {}
    for _, target in ipairs( rawTargets ) do
        local trimmed = string.Trim( target )
        if trimmed ~= "" then
            table.insert( targets, trimmed )
        end
    end

    return #targets > 0 and targets or nil
end

--- @param _ Player?
--- @param __ string
--- @param ___ string[]
--- @param argsStr string The full argument string
local function runTestsCommand( _, __, ___, argsStr ) -- Luals doesn't like duplicate parameters (  e.g _  )
    local targets = parseTargets( argsStr )
    if targets then
        local targetList = table.concat( targets, "', '" )
        print( "[GLuaTest] Running specific targets: '" .. targetList .. "'" )
    else
        print( "[GLuaTest] Running all tests." )
    end
    GLuaTest.runAllTests( targets )
end

--- @diagnostic disable-next-line: param-type-mismatch
concommand.Add(
    "gluatest_run_tests",
    runTestsCommand,
    nil,
    "Run tests. Optionally specify comma separated group names or project/file paths (e.g., 'group1, myproject/mytest.lua')",
    FCVAR_PROTECTED
)
