include( "gluatest/runner/test_case_runner.lua" )

--- @type GLuaTest_RunnerHelpers
local Helpers = include( "gluatest/runner/helpers.lua" )
local noop = function() end

local DEFAULT_HOOK_TIMEOUT = 5

--- Create a new TestGroupRunner
--- @param TestRunner GLuaTest_TestRunner
--- @param group GLuaTest_RunnableTestGroup
function GLuaTest.TestGroupRunner( TestRunner, group )
    --- @class GLuaTest_TestGroupRunner
    local TGR = {}

    --- The test group that this runner is Running
    --- @type GLuaTest_RunnableTestGroup
    TGR.group = group

    --- Shared group-level state
    TGR.groupState = {}

    --- Cases that we will run from this group
    --- @type GLuaTest_TestCaseRunner[]
    TGR.caseRunners = {}

    --- Add a result to the test run
    --- @param result GLuaTest_UngroupedTestResult
    function TGR:AddResult( result )
        --- @type GLuaTest_TestResult
        local groupedResult = {
            case = result.case,
            empty = result.empty,
            success = result.success,
            skipped = result.skipped,
            errInfo = result.errInfo,

            testGroup = group
        }

        TestRunner:AddResult( groupedResult )
    end

    --- Add a success result for the given case
    --- @param case GLuaTest_RunnableTestCase
    function TGR:SetSucceeded( case )
        self:AddResult( { case = case, success = true } )
    end

    --- Add a failed result for the given case
    --- @param case GLuaTest_RunnableTestCase
    --- @param errInfo? GLuaTest_FailCallbackInfo
    function TGR:SetFailed( case, errInfo )
        self:AddResult( { case = case, success = false, errInfo = errInfo } )
    end

    --- Add a timeout result for the given case
    --- @param case GLuaTest_RunnableTestCase
    function TGR:SetTimedOut( case )
        self:SetFailed( case, { reason = "Timeout" } )
    end

    --- Add a skipped result for the given case
    --- @param case GLuaTest_RunnableTestCase
    function TGR:SetSkipped( case )
        self:AddResult( { case = case, skipped = true, } )
    end

    --- Add an empty result for the given case
    --- @param case GLuaTest_RunnableTestCase
    function TGR:SetEmpty( case )
        self:AddResult( { case = case, empty = true, } )
    end

    --- Run an individual test case
    --- @param case GLuaTest_TestCase
    --- @return GLuaTest_TestCaseRunner
    function TGR:MakeCaseRunner( case )
        --- @type GLuaTest_RunnableTestCase
        local runnableCase = {
            name = case.name,
            func = case.func,
            async = case.async,
            coroutine = case.coroutine,
            timeout = case.timeout,
            when = case.when,
            skip = case.skip,
            clientside = case.clientside,
            shared = case.shared,

            cleanup = case.cleanup or noop,
            id = Helpers.GetCaseID(),
            state = Helpers.CreateCaseState( self.groupState )
        }

        local caseRunner = GLuaTest.TestCaseRunner( self, runnableCase )

        return caseRunner
    end

    --- Run all cases in the test group
    --- @param cb fun(): nil The function to run once the group is complete
    function TGR:Run( cb )
        if group.includeError ~= nil then
            --- @type GLuaTest_RunnableTestCase
            local mockTestCase = {
                name = "Failed to include file",
                func = function() end,
            }

            self:SetFailed( mockTestCase, group.includeError )
            return cb()
        end

        local hookTimeout = group.hookTimeout or DEFAULT_HOOK_TIMEOUT

        local function onAfterAllFinished( afterAllFailure )
            if afterAllFailure then
                self:SetFailed( { name = "afterAll", func = noop }, afterAllFailure )
            end

            cb()
        end

        local function finish()
            Helpers.RunWaitingHook( group.afterAll, self.groupState, hookTimeout, onAfterAllFinished )
        end

        local function runCases()
            local runners = self.caseRunners

            local cases = group.cases
            local caseCount = #cases
            for i = caseCount, 1, -1 do
                local case = cases[i]
                local runner = self:MakeCaseRunner( case )
                table.insert( runners, runner )
            end

            local function runNext()
                local nextRunner = table.remove( runners )
                if not nextRunner then return finish() end

                local continued = false
                local function runNextOnce()
                    if continued then return end
                    continued = true

                    runNext()
                end

                local success, errInfo = xpcall( nextRunner.Run, Helpers.FailCallback, nextRunner, runNextOnce )
                if success then return end
                if continued then return ErrorNoHalt( errInfo.reason .. "\n" ) end

                self:SetFailed( nextRunner.case, errInfo )
                runNextOnce()
            end

            runNext()
        end

        local function onBeforeAllFinished( beforeAllFailure )
            if beforeAllFailure then
                self:SetFailed( { name = "beforeAll", func = noop }, beforeAllFailure )
                return finish()
            end

            runCases()
        end

        Helpers.RunWaitingHook( group.beforeAll, self.groupState, hookTimeout, onBeforeAllFinished )
    end

    return TGR
end
