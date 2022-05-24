local Helpers = include( "gluatest/runner/helpers.lua" )
local FailCallback = Helpers.FailCallback
local MakeAsyncEnv = Helpers.MakeAsyncEnv
local SafeRunWithEnv = Helpers.SafeRunWithEnv
local CleanupPostTest = Helpers.CleanupPostTest

local ResultLogger = include( "gluatest/runner/logger.lua" )
local LogTestFailureDetails = ResultLogger.LogTestFailureDetails
local LogTestResult = ResultLogger.LogTestResult
local LogFileStart = ResultLogger.LogFileStart

local noop = function() end

local caseID = 0
local function getCaseID()
    caseID = caseID + 1
    return "case" .. caseID
end

return function( allTestGroups )
    if CLIENT and not GLuaTest.RUN_CLIENTSIDE then return end

    -- Sequential table of Result structures
    local allResults = {}

    -- { caseID = { result, result }, caseID = { result } }
    local failures = {}

    local function _addResult( testGroup, success, case, errInfo )
        local result = {
            success = success,
            testGroup = testGroup,
            case = case,
            errInfo = errInfo
        }

        table.insert( allResults, result )

        if not success then
            local id = case.id
            failures[id] = failures[id] or {}
            table.insert( failures[id], result )
        end

        LogTestResult( result )
    end

    hook.Run( "GLuaTest_StartedTestRun", allTestGroups )
    local defaultEnv = getfenv( 1 )

    local testGroup
    local function runNextTestGroup( testGroups )
        if testGroup then testGroup.afterAll() end

        testGroup = table.remove( testGroups )

        if not testGroup then
            LogTestFailureDetails( failures )
            hook.Run( "GLuaTest_Finished", testGroups, allResults )
            return
        end

        local function addResult( ... )
            return _addResult( testGroup, ... )
        end

        local cases = testGroup.cases
        local caseCount = #cases

        LogFileStart( testGroup )
        testGroup.beforeAll()

        local asyncCases = {}

        for c = 1, caseCount do
            local case = cases[c]
            case.id = getCaseID()
            case.state = case.state or {}
            case.setup = case.setup or noop
            case.cleanup = case.cleanup or noop

            local shared = case.shared
            local clientside = case.clientside
            local serverside = not case.clientside
            local shouldRun = shared or ( clientside and CLIENT ) or ( serverside and SERVER )

            if shouldRun then
                if case.async then
                    asyncCases[case.id] = case
                else
                    testGroup.beforeEach( case.state )
                    case.setup( case.state )

                    local success, errInfo = SafeRunWithEnv( defaultEnv, case.func, case.state )

                    case.cleanup( case.state )
                    testGroup.afterEach( case.state )
                    CleanupPostTest()

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

        for id, case in pairs( asyncCases ) do
            local caseFunc = case.func
            local caseTimeout = case.timeout
            local setup = case.setup or noop

            testGroup.beforeEach( case.state )
            setup( case.state )

            local expectationFailure = false

            -- TODO: Find a better way to handle this function
            -- It shouldn't take a param like this to modify its behavior
            case.testComplete = function( shouldCheckComplete )
                timer.Remove( "GLuaTest_AsyncTimeout_" .. id )
                setfenv( caseFunc, defaultEnv )

                case.cleanup( case.state )
                testGroup.afterEach( case.state )

                if shouldCheckComplete == false then return end

                checkComplete()
            end

            local onDone = function()
                if callbacks[id] ~= nil then
                    ErrorNoHaltWithStack( "Tried to call done() after we already recorded a result?" )
                    print( case.name )
                    return
                end

                if not expectationFailure then
                    addResult( true, case )
                end

                callbacks[id] = not expectationFailure
                case.testComplete()
            end

            -- Received an expectation failure
            -- We will record it here, but still expect them to
            -- call done()
            --
            -- This will only be called once, even though many
            -- expectations may fail.
            local onFailedExpectation = function( errInfo )
                addResult( false, case, errInfo )
                expectationFailure = true
            end

            local asyncEnv = MakeAsyncEnv( onDone, onFailedExpectation )

            setfenv( caseFunc, asyncEnv )
            local success, errInfo = xpcall( caseFunc, FailCallback, case.state )

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
                if caseTimeout then
                    timer.Create( "GluaTest_AsyncTimeout_" .. case.id, caseTimeout, 1, function()
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
