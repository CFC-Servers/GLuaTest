--- @meta GLuaTest_Types

--- @class GLuaTest_TestState
--- @field [any] any The state of the test

--- @class GLuaTest_TestCase
--- @field name string The human-readable name of the test
--- @field func fun(state: GLuaTest_TestState): nil The test function
--- @field async? boolean Whether the test requires asynchronous handling
--- @field coroutine? boolean Whether the test requires coroutine handling
--- @field timeout? number The maximum time (in seconds) the test can run before being considered failed
--- @field cleanup? fun(state: GLuaTest_TestState): nil A function to run after the test, regardless of the test outcome
--- @field when? boolean|fun(): boolean Only run this test case when this condition is met
--- @field skip? boolean|fun(): boolean Skip this test case when this condition is met
--- @field clientside? boolean (Not fully supported) Whether the test is clientside
--- @field shared? boolean (Not fully supported) Whether the test is shared

--- @class GLuaTest_RunnableTestCase : GLuaTest_TestCase
--- The test case with additional information that the Runner needs
--- @field id? string The unique identifier of the test case
--- @field state? GLuaTest_TestState The state of the test case

--- @class GLuaTest_TestGroup
--- @field cases GLuaTest_TestCase[] The test cases in the group
--- @field groupName? string The human-readable name of the test group (Defaults to the path of the test)
--- @field beforeAll? fun(state: GLuaTest_TestState): nil A function to run before all tests in the group
--- @field beforeEach? fun(state: GLuaTest_TestState): nil A function to run before each test in the group
--- @field afterAll? fun(state: GLuaTest_TestState): nil A function to run after all tests in the group
--- @field afterEach? fun(state: GLuaTest_TestState): nil A function to run after each test in the group

--- @class GLuaTest_RunnableTestGroup : GLuaTest_TestGroup
--- @field fileName string The name of the file the test is in
--- @field project string The name of the project the test is in

--- @class GLuaTest_UngroupedTestResult
--- @field case GLuaTest_TestCase The test case
--- @field empty? boolean Whether the test case was empty
--- @field success? boolean Whether the test succeeded
--- @field skipped? boolean Whether the test was skipped
--- @field errInfo? GLuaTest_FailCallbackInfo The error information if the test failed

--- @class GLuaTest_TestResult : GLuaTest_UngroupedTestResult
--- @field testGroup GLuaTest_RunnableTestGroup The test group


--- @class GLuaTest_CaseSuccess
--- @field result '"success"'

--- @class GLuaTest_CaseFailure
--- @field result '"failure"'
--- @field errInfo GLuaTest_FailCallbackInfo

--- @class GLuaTest_CaseEmpty
--- @field result '"empty"'

--- @alias GLuaTest_CaseRunResult GLuaTest_CaseSuccess | GLuaTest_CaseFailure | GLuaTest_CaseEmpty


--- Begin an expectation chain
--- @param subject any The subject of the expectation
--- @return GLuaTest_Expect
function expect( subject, ... )
    _ = subject
end

--- Create a stub function
--- @param tbl table The table to stub
--- @param key any The key to stub
--- @return GLuaTest_Stub
function stub( tbl, key )
    _ = tbl
    _ = key
end
