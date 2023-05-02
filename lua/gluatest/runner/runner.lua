local Helpers = include( "gluatest/runner/helpers.lua" )
local FailCallback = Helpers.FailCallback
local MakeAsyncEnv = Helpers.MakeAsyncEnv
local SafeRunWithEnv = Helpers.SafeRunWithEnv
local CreateCaseState = Helpers.CreateCaseState

local ResultLogger = include( "gluatest/runner/logger.lua" )
local LogFileStart = ResultLogger.LogFileStart
local LogTestResult = ResultLogger.LogTestResult
local LogTestsComplete = ResultLogger.LogTestsComplete
local LogTestFailureDetails = ResultLogger.LogTestFailureDetails
local PlainLogStart = ResultLogger.PlainLogStart
local noop = function() end

local caseID = 0
local function getCaseID()
    caseID = caseID + 1
    return "case" .. caseID
end

return function( allTestGroups )
    if CLIENT and not GLuaTest.RUN_CLIENTSIDE then return end

    -- A copy of the original test groups for later reference
    local originalTestGroups = table.Copy( allTestGroups )

    -- Sequential table of Result structures
    local allResults = {}

    -- success and errInfo can be nil if the test case
    -- didn't error or call an expectation
    local function _addResult( testGroup, success, case, errInfo )
        local result = {
            success = success,
            testGroup = testGroup,
            case = case,
            errInfo = errInfo
        }

        hook.Run( "GLuaTest_LogTestResult", result )

        table.insert( allResults, result )

        LogTestResult( result )
        if success == false then LogTestFailureDetails( result ) end
    end

    PlainLogStart()
    hook.Run( "GLuaTest_StartedTestRun", allTestGroups )
    local startTime = SysTime()
    local defaultEnv = getfenv( 1 )

    local testGroup
    local testGroupState = {}
    local function runNextTestGroup( testGroups )
        if testGroup then testGroup.afterAll( testGroupState ) end

        testGroup = table.remove( testGroups )
        testGroupState = {}

        if not testGroup then
            local duration = SysTime() - startTime

            hook.Run( "GLuaTest_Finished", originalTestGroups, allResults, duration )
            LogTestsComplete( originalTestGroups, allResults, duration )

            return
        end

        local function addResult( ... )
            return _addResult( testGroup, ... )
        end

        local cases = testGroup.cases
        local caseCount = #cases

        LogFileStart( testGroup )
        testGroup.beforeAll( testGroupState )

        local asyncCases = {}

        for c = 1, caseCount do
            local case = cases[c]
            case.id = getCaseID()
            case.state = case.state or CreateCaseState( testGroupState )
            case.cleanup = case.cleanup or noop

            local shared = case.shared
            local clientside = case.clientside
            local serverside = not case.clientside
            local shouldRun = shared or ( clientside and CLIENT ) or ( serverside and SERVER )

            local canRun = hook.Run( "GLuaTest_CanRunTestCase", testGroup, case )
            if canRun == nil then canRun = true end

            if canRun and shouldRun then
                if case.async then
                    asyncCases[case.id] = case
                else
                    local beforeFunc = testGroup.beforeEach
                    local success, errInfo = SafeRunWithEnv( defaultEnv, beforeFunc, case.func, case.state )

                    case.cleanup( case.state )
                    testGroup.afterEach( case.state )

                    addResult( success, case, errInfo )
                end
            end
        end

        local asyncCount = table.Count( asyncCases )
        if asyncCount == 0 then
            runNextTestGroup( testGroups )
            return
        end

        local callbacks = {}
        local checkComplete = function()
            local cbCount = table.Count( callbacks )
            if cbCount ~= asyncCount then return end

            timer.Remove( "GLuaTest_AsyncWaiter" )
            runNextTestGroup( testGroups )
        end

        for _, case in pairs( asyncCases ) do
            local expectationFailure = false
            local asyncCleanup = function()
                ErrorNoHaltWithStack( "Running an empty Async Cleanup func" )
            end

            -- TODO: Find a better way to handle this function
            -- It shouldn't take a param like this to modify its behavior
            case.testComplete = function( shouldCheckComplete )
                timer.Remove( "GLuaTest_AsyncTimeout_" .. case.id )
                setfenv( case.func, defaultEnv )

                case.cleanup( case.state )
                testGroup.afterEach( case.state )

                asyncCleanup()

                if shouldCheckComplete == false then return end

                checkComplete()
            end

            local onDone = function()
                if callbacks[case.id] ~= nil then return end

                if not expectationFailure then
                    addResult( true, case )
                end

                callbacks[case.id] = not expectationFailure
                case.testComplete()
            end

            -- Received an expectation failure
            -- We will record it here, but still expect them
            -- to call done().
            --
            -- This will only be called once, even though many
            -- expectations may fail.
            local onFailedExpectation = function( errInfo )
                if callbacks[case.id] ~= nil then return end

                addResult( false, case, errInfo )
                expectationFailure = true
            end

            local asyncEnv, asyncCleanupFunc = MakeAsyncEnv( onDone, onFailedExpectation )
            asyncCleanup = asyncCleanupFunc

            setfenv( testGroup.beforeEach, asyncEnv )
            testGroup.beforeEach( case.state )
            setfenv( testGroup.beforeEach, defaultEnv )

            setfenv( case.func, asyncEnv )
            local success, errInfo = xpcall( case.func, FailCallback, case.state )

            -- If the test failed while calling it
            -- (Async expectation failures handled in asyncEnv.expect)
            -- (Async unhandled failures handled with timeouts)
            if not success then
                addResult( success, case, errInfo )
                callbacks[case.id] = false
                case.testComplete()
            else
                -- If the test ran successfully, start the case-specific timeout timer
                -- (If it's configured)
                if case.timeout then
                    timer.Create( "GLuaTest_AsyncTimeout_" .. case.id, case.timeout, 1, function()
                        local timeoutInfo = { reason = "Timeout" }

                        addResult( false, case, timeoutInfo )
                        callbacks[case.id] = false

                        case.testComplete()
                    end )
                end
            end

        end

        timer.Create( "GLuaTest_AsyncWaiter", 60, 1, function()
            for id, case in pairs( asyncCases ) do
                if callbacks[id] == nil then
                    addResult( false, case, { reason = "Timeout" } )

                    local shouldCheckComplete = false
                    case.testComplete( shouldCheckComplete )
                end
            end

            -- Should always run the next testGroup
            checkComplete()
        end )
    end

    runNextTestGroup( allTestGroups )
end
