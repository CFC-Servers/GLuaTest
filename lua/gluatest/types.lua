--- @class GLuaTest_TestState
--- @field [any] any The state of the test

--- @class GLuaTest_TestCase
--- @field name string The human-readable name of the test
--- @field func fun(state: GLuaTest_TestState): nil The test function
--- @field async? boolean Whether the test requires asynchronous handling
--- @field timeout? number The maximum time (in seconds) the test can run before being considered failed
--- @field cleanup? fun(state: GLuaTest_TestState): nil A function to run after the test, regardless of the test outcome
--- @field when? boolean|fun(): boolean Only run this test case when this condition is met
--- @field skip? boolean|fun(): boolean Skip this test case when this condition is met
--- @field clientside? boolean (Not fully supported) Whether the test is clientside

--- @class GLuaTest_TestGroup
--- @field private fileName string The name of the file the test is in
--- @field cases GLuaTest_TestCase[] The test cases in the group
--- @field groupName? string The human-readable name of the test group (Defaults to the path of the test)
--- @field beforeAll? fun(): nil A function to run before all tests in the group
--- @field beforeEach? fun(state: GLuaTest_TestState): nil A function to run before each test in the group
--- @field afterAll? fun(): nil A function to run after all tests in the group
--- @field afterEach? fun(state: GLuaTest_TestState): nil A function to run after each test in the group


