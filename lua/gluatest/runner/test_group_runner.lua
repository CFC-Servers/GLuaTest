include( "gluatest/runner/test_case_runner.lua" )

--- @type GLuaTest_RunnerHelpers
local Helpers = include( "gluatest/runner/helpers.lua" )
local noop = function() end

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
        result.testGroup = group

        local groupedResult = result --[[@as GLuaTest_TestResult]]
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
        case.id = Helpers.GetCaseID()
        case.state = case.state or Helpers.CreateCaseState( self.groupState )
        case.cleanup = case.cleanup or noop

        local runnableCase = case --[[@as GLuaTest_RunnableTestCase]]
        local caseRunner = GLuaTest.TestCaseRunner( self, runnableCase )

        return caseRunner
    end

    --- Run all cases in the test group
    --- @param cb fun(): nil The function to run once the group is complete
    function TGR:Run( cb )
        local beforeAll = group.beforeAll
        if beforeAll then beforeAll( self.groupState ) end

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

            if not nextRunner then
                local afterAll = group.afterAll
                if afterAll then afterAll( self.groupState ) end

                return cb()
            end

            nextRunner:Run( runNext )
        end

        runNext()
    end

    return TGR
end
