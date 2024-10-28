include( "gluatest/runner/test_group_runner.lua" )

--- @type GLuaTest_ResultLogger
local ResultLogger = include( "gluatest/runner/logger.lua" )
local LogFileStart = ResultLogger.LogFileStart
local LogTestResult = ResultLogger.LogTestResult
local LogTestsComplete = ResultLogger.LogTestsComplete
local LogTestFailureDetails = ResultLogger.LogTestFailureDetails
local PlainLogStart = ResultLogger.PlainLogStart

--- @class GLuaTest_TestRunner
local TestRunner = {}

--- @type GLuaTest_TestResult[]
TestRunner.results = {}

--- Adds and logs a result to the test run
--- @param result GLuaTest_TestResult
function TestRunner:AddResult( result )
    hook.Run( "GLuaTest_LogTestResult", result )
    table.insert( self.results, result )

    LogTestResult( result )
    if result.success == false then LogTestFailureDetails( result ) end
end

--- Completes the test run
--- @param testGroups GLuaTest_TestGroup[]
function TestRunner:Complete( testGroups )
    local duration = SysTime() - self.startTime

    hook.Run( "GLuaTest_Finished", testGroups, self.results, duration )
    LogTestsComplete( testGroups, self.results, duration )
end

--- Runs all given test groups
--- @param testGroups GLuaTest_RunnableTestGroup[]
function TestRunner:Run( testGroups )
    if CLIENT and not GLuaTest.RUN_CLIENTSIDE then return end

    PlainLogStart()

    hook.Run( "GLuaTest_StartedTestRun", testGroups )
    self.startTime = SysTime()

    --- @type GLuaTest_TestGroupRunner[]
    local runners = {}

    for _, group in ipairs( testGroups ) do
        local runner = GLuaTest.TestGroupRunner( self, group )
        table.insert( runners, runner )
    end

    local function runNext()
        --- @type GLuaTest_TestGroupRunner
        local nextRunner = table.remove( runners )

        if not nextRunner then
            return self:Complete( testGroups )
        end

        LogFileStart( nextRunner.group )

        nextRunner:Run( runNext )
    end

    runNext()
end

return TestRunner
