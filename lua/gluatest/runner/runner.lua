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

--- Global var to track the current case ID, even across lua refreshes
GLuaTest_CaseID = GLuaTest_CaseID or 0
local function getCaseID()
    GLuaTest_CaseID = GLuaTest_CaseID + 1
    return "case" .. GLuaTest_CaseID
end

TestRunner.results = {}
TestRunner.testGroups = {}

function TestRunner:AddResult( result )
    result.testGroup = self.testGroup

    hook.Run( "GLuaTest_LogTestResult", result )
    table.insert( self.results, result )

    LogTestResult( result )
    if result.success == false then LogTestFailureDetails( result ) end
end

function TestRunner:SetSucceeded( case )
    return self:AddResult( {
        case = case,
        success = true,
    } )
end

function TestRunner:SetFailed( case, errInfo )
    return self:AddResult( {
        case = case,
        success = false,
        errInfo = errInfo
    } )
end

function TestRunner:SetTimedOut( case )
    return self:SetFailed( case, { reason = "Timeout" } )
end

function TestRunner:SetSkipped( case )
    return self:AddResult( {
        case = case,
        skipped = true,
    } )
end

function TestRunner:SetEmpty( case )
    return self:AddResult( {
        case = case,
        empty = true,
    } )
end

function TestRunner:RunGroup( testGroup )
end

function TestRunner:RunGroups( testGroups )
    if CLIENT and not GLuaTest.RUN_CLIENTSIDE then return end

    self.testGroups = testGroups

    PlainLogStart()

    hook.Run( "GLuaTest_StartedTestRun", allTestGroups )
    self.startTime = SysTime()
    self.defaultEnv = getfenv( 1 )
end

return function( allTestGroups )

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


        local cases = testGroup.cases
        local caseCount = #cases

        LogFileStart( testGroup )
        testGroup.beforeAll( testGroupState )

        local asyncCases = {}

        local function processCase( case )
            local shouldSkip = checkShouldSkip( case )
            if shouldSkip then
                setSkipped( case )
                return
            end

            -- Returning false from this hook will hide it from the output
            local canRun = hook.Run( "GLuaTest_CanRunTestCase", testGroup, case )
            if canRun == nil then canRun = true end
            if not canRun then return end

            -- Tests in the wrong realm will be hidden from output
            local shared = case.shared
            local clientside = case.clientside
            local serverside = not case.clientside
            local correctRealm = shared or ( clientside and CLIENT ) or ( serverside and SERVER )
            if not correctRealm then return end

            if case.async then
                asyncCases[case.id] = case
            else
                local beforeFunc = testGroup.beforeEach
                local success, errInfo = SafeRunWithEnv( defaultEnv, beforeFunc, case.func, case.state )

                case.cleanup( case.state )
                testGroup.afterEach( case.state )

                if success then
                    setSucceeded( case )
                elseif success == nil then
                    setEmpty( case )
                else
                    setFailed( case, errInfo )
                end
            end
        end

        for c = 1, caseCount do
            local case = cases[c]
            case.id = getCaseID()
            case.state = case.state or CreateCaseState( testGroupState )
            case.cleanup = case.cleanup or noop

            processCase( case )
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

            runNextTestGroup( testGroups )
        end

        for _, case in pairs( asyncCases ) do
            local expectationFailure = false
            local asyncCleanup = function()
                ErrorNoHaltWithStack( "Running an empty Async Cleanup func" )
            end

            case.testComplete = function()
                timer.Remove( "GLuaTest_AsyncTimeout_" .. case.id )
                setfenv( case.func, defaultEnv )

                case.cleanup( case.state )
                testGroup.afterEach( case.state )

                asyncCleanup()
                checkComplete()
            end

            local done = function()
                if callbacks[case.id] ~= nil then return end

                if not expectationFailure then
                    setSucceeded( case )
                end

                callbacks[case.id] = not expectationFailure
                case.testComplete()
            end

            local fail = function( reason )
                if callbacks[case.id] ~= nil then return end

                setFailed( case, { reason = reason or "fail() called" } )
                callbacks[case.id] = false
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

                setFailed( case, errInfo )
                expectationFailure = true
            end

            local asyncEnv, asyncCleanupFunc = MakeAsyncEnv( done, fail, onFailedExpectation )
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
                setFailed( case, errInfo )
                callbacks[case.id] = false
                case.testComplete()
            else
                -- If the test ran successfully, start the case-specific timeout timer

                if callbacks[case.id] == nil then
                    -- If the async case actually operated synchronously (i.e. called done() or fail() before we got here) then we don't need to set a timeout
                    local timeout = case.timeout or 60

                    timer.Create( "GLuaTest_AsyncTimeout_" .. case.id, timeout, 1, function()
                        setTimedOut( case )
                        callbacks[case.id] = false

                        case.testComplete()
                    end )
                end
            end
        end
    end

    runNextTestGroup( allTestGroups )
end
