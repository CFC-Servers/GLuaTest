local isfunction = isfunction

--- @type GLuaTest_RunnerHelpers
local Helpers = include( "gluatest/runner/helpers.lua" )

--- case.when should evaluate to `true` if the test should run
--- case.skip should evaluate to `true` if the test should be skipped
--- (case.skip takes precedence over case.when)
--- @param case GLuaTest_RunnableTestCase
local function checkShouldSkip( case )
    -- skip
    local skip = case.skip
    if skip == true then return true end
    if skip and isfunction( skip ) then
        return skip() == true
    end

    -- when
    local condition = case.when
    if condition == nil then return false end
    if condition == false then return true end

    if isfunction( condition ) then
        return condition() ~= true
    end

    return condition ~= true
end

--- @param TestGroupRunner GLuaTest_TestGroupRunner
--- @param case GLuaTest_RunnableTestCase
--- @return GLuaTest_TestCaseRunner
function GLuaTest.TestCaseRunner( TestGroupRunner, case )
    local group = assert( TestGroupRunner.group ) --[[@as GLuaTest_TestGroup]]

    local defaultEnv = getfenv( 1 )

    --- @class GLuaTest_TestCaseRunner
    local TCR = {}

    --- Checks if the given test case can/should be run
    function TCR:CanRun()
        local shouldSkip = checkShouldSkip( case )
        if shouldSkip then
            TestGroupRunner:SetSkipped( case )
            return false
        end

        local canRun = hook.Run( "GLuaTest_CanRunTestCase", TestGroupRunner.group, case )
        if canRun == nil then canRun = true end
        if not canRun then return false end

        -- Tests in the wrong realm will be hidden from output
        local shared = case.shared
        local clientside = case.clientside
        local serverside = not case.clientside
        local correctRealm = shared or ( clientside and CLIENT ) or ( serverside and SERVER )
        if not correctRealm then return false end

        return true
    end

    --- Run the case synchronously
    --- @param cb fun(): nil The function to run once the test is complete
    function TCR:RunSync( cb )
        local beforeFunc = group.beforeEach
        local caseResult = Helpers.SafeRunWithEnv( defaultEnv, beforeFunc, case.func, case.state )

        case.cleanup( case.state )

        local afterEach = group.afterEach
        if afterEach then afterEach( case.state ) end

        if caseResult.result == "empty" then
            TestGroupRunner:SetEmpty( case )
        elseif caseResult.result == "success" then
            TestGroupRunner:SetSucceeded( case )
        elseif caseResult.result == "failure" then
            local errInfo = caseResult.errInfo
            TestGroupRunner:SetFailed( case, errInfo )
        end

        cb()
    end

    --- Run the case asynchronously
    --- @param cb fun(): nil The function to run once the test is complete
    function TCR:RunAsync( cb )
        local isDone = false
        local expectationFailure = false

        local asyncCleanup = function()
            ErrorNoHaltWithStack( "Running an empty Async Cleanup func" )
        end

        local function testComplete()
            isDone = true

            timer.Remove( "GLuaTest_AsyncTimeout_" .. case.id )
            setfenv( case.func, defaultEnv )

            local cleanup = case.cleanup
            if cleanup then case.cleanup( case.state ) end

            local afterEach = group.afterEach
            if afterEach then group.afterEach( case.state ) end

            asyncCleanup()
            cb()
        end

        --- Call to manually mark the test as done
        --- (injected into the test's environment)
        local function done()
            if isDone then return end

            if not expectationFailure then
                TestGroupRunner:SetSucceeded( case )
            end

            testComplete()
        end

        --- Call to manually fail the test
        --- (injected into the test's environment)
        --- @param reason? string
        local function fail( reason )
            if isDone then return end

            TestGroupRunner:SetFailed( case, { reason = reason or "fail() called" } )
            testComplete()
        end

        --- Received an expectation failure
        --- We will record it here, but still expect them
        --- to call done().
        ---
        --- This will only be called once, even though many
        --- expectations may fail.
        --- @param errInfo GLuaTest_FailCallbackInfo
        local function onFailedExpectation( errInfo )
            if isDone then return end
            if expectationFailure then return end

            TestGroupRunner:SetFailed( case, errInfo )
            expectationFailure = true
        end

        local asyncEnv, asyncCleanupFunc = Helpers.MakeAsyncEnv( done, fail, onFailedExpectation )
        asyncCleanup = asyncCleanupFunc

        local beforeEach = group.beforeEach
        if beforeEach then
            setfenv( beforeEach, asyncEnv )
            beforeEach( case.state )
            setfenv( beforeEach, defaultEnv )
        end

        setfenv( case.func, asyncEnv )
        local success, errInfo = xpcall( case.func, Helpers.FailCallback, case.state )

        -- If the test failed while calling it
        -- (Async expectation failures handled in asyncEnv.expect)
        -- (Async unhandled failures handled with timeouts)
        if not success then
            TestGroupRunner:SetFailed( case, errInfo )
            testComplete()

            return
        end

        -- If the async case actually operated synchronously
        -- (i.e. called done() or fail() before we got here)
        -- then we don't need to set a timeout
        if isDone then return end

        -- If the test ran successfully, start the case-specific timeout timer
        local timeout = case.timeout or 5

        timer.Create( "GLuaTest_AsyncTimeout_" .. case.id, timeout, 1, function()
            TestGroupRunner:SetTimedOut( case )
            testComplete()
        end )
    end

    --- Run the test case
    --- @param cb fun(): nil The function to run once the test is complete
    function TCR:Run( cb )
        if not self:CanRun() then
            return cb()
        end

        local func = case.async and self.RunAsync or self.RunSync

        if case.coroutine then
            func = coroutine.wrap( func )
        end

        func( self, cb )
    end

    return TCR
end
