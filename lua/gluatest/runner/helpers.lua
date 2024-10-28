--- @class GLuaTest_RunnerHelpers
local Helpers = {}

--- @type GLuaTest_Expect
local expect = include( "gluatest/expectations/expect.lua" )
local stubMaker = include( "gluatest/stubs/stubMaker.lua" )

--- Global var to track the current case ID, even across lua refreshes
GLuaTest_CaseID = GLuaTest_CaseID or 0

--- Gets a unique case ID
--- @return string
function Helpers.GetCaseID()
    GLuaTest_CaseID = GLuaTest_CaseID + 1
    return "case" .. GLuaTest_CaseID
end

------------------
-- Cleanup stuff--
------------------

--- Makes a mocked hook library that will clean itself up after the test completes
local makeHookTable = function()
    local trackedHooks = {}

    --- Wrapper over hook.Add that tracks the hooks added
    local hook_Add = function( event, name, func, ... )
        if not trackedHooks[event] then trackedHooks[event] = {} end
        table.insert( trackedHooks[event], name )

        if not isfunction( func ) and func.IsStub then
            local givenStub = func
            func = function( ... )
                givenStub( ... )
            end
        end

        return _G.hook.Add( event, name, func, ... )
    end

    --- Cleans up all the hooks that were added
    local function cleanup()
        for event, names in pairs( trackedHooks ) do
            for _, name in ipairs( names ) do
                _G.hook.Remove( event, name )
            end
        end
    end

    local newHookTable = setmetatable( {}, {
        __index = function( _, key )
            if key == "Add" then
                return hook_Add
            end

            return rawget( _G.hook, key )
        end,

        __newindex = function( _, key, value )
            rawset( _G.hook, key, value )
        end
    } )

    return newHookTable, cleanup
end

local timerCount = 0
local function makeTimerTable()
    local timerNames = {}

    local timer_Create = function( identifier, delay, reps, func, ... )
        table.insert( timerNames, identifier )

        return timer.Create( identifier, delay, reps, func, ... )
    end

    local timer_Simple = function( delay, func )
        local name = "simple_timer_" .. timerCount
        timerCount = timerCount + 1

        timer_Create( name, delay, 1, func )
    end

    local function cleanup()
        for _, name in ipairs( timerNames ) do
            timer.Remove( name )
        end
    end

    return table.Inherit( { Create = timer_Create, Simple = timer_Simple }, timer ), cleanup
end

local function makeTestLibStubs()
    local testHook, hookCleanup = makeHookTable()
    local testTimer, timerCleanup = makeTimerTable()

    local testEnv = {
        hook = testHook,
        timer = testTimer
    }

    local function cleanup()
        hookCleanup()
        timerCleanup()
    end

    return testEnv, cleanup
end

local function makeTestTools()
    local stub, stubCleanup = stubMaker()

    local tools = {
        stub = stub,
        expect = expect,
    }

    local function cleanup()
        stubCleanup()
    end

    return tools, cleanup
end

--- Creates a new environment for a test to run in
--- @return table The test environment
--- @return fun(): nil The cleanup function
local function makeTestEnv()
    local testEnv, envCleanup = makeTestLibStubs()
    local testTools, toolsCleanup = makeTestTools()

    local function cleanup()
        envCleanup()
        toolsCleanup()
    end

    local env = setmetatable(
        testTools,
        {
            __index = function( _, idx )
                return testEnv[idx] or _G[idx]
            end,
        }
    )

    hook.Run( "GLuaTest_EnvCreated", env )

    return env, cleanup
end

--- @class GLuaTest_LocalVariable
--- @field name string
--- @field value string

--- Returns all locals from a given stack level
--- @param level number
--- @return GLuaTest_LocalVariable[]
local function getLocals( level )
    --- @type GLuaTest_LocalVariable[]
    local locals = {}
    local i = 1

    while true do
        local name, value = debug.getlocal( level, i )
        if name == nil then break end
        if name ~= "(*temporary)" then
            table.insert( locals, { name, value == nil and "nil" or value } )
        end
        i = i + 1
    end

    return locals
end

--- Navigates the stack to find the correct stack level and info to report error information
--- @return number The stack level
--- @return debuginfo The stack info
local function findStackInfo()
    -- Step up through the stacks to find the error we care about

    for stack = 1, 12 do
        local info = debug.getinfo( stack, "lnS" )
        if not info then break end

        local emptyName = #info.namewhat == 0
        local notGluatest = not string.match( info.short_src, "/lua/gluatest/" )

        if emptyName and notGluatest then
            return stack, info
        end
    end

    -- This should never happen!!
    ErrorNoHaltWithStack( "Could not find stack info! This should never happen - please report this!" )
    return 2, debug.getinfo( 2, "lnS" )
end

--- @class GLuaTest_FailCallbackInfo
--- @field reason string The error message
--- @field sourceFile? string The file the error occurred in
--- @field lineNumber? number The line number the error occurred on
--- @field locals? GLuaTest_LocalVariable[] The local variables at the time of the error

--- A callback for when a test fails in xpcall
--- @param reason string
--- @return GLuaTest_FailCallbackInfo
function Helpers.FailCallback( reason )
    if reason == "" then
        error( "Received empty error reason in failCallback- ignoring " )
    end

    -- root/file/name.lua:420: Expectation Failed: Failure reason
    -- root/file/name.lua:420: attempt to index nil value 'blah'
    local reasonSpl = string.Split( reason, ": " )

    if reasonSpl[2] == "Expectation Failed" then
        table.remove( reasonSpl, 2 )
    else
        table.insert( reasonSpl, 2, "Unhandled" )
    end

    local cleanReason = table.concat( reasonSpl, ": ", 2, #reasonSpl )

    local level, info = findStackInfo()
    local locals = getLocals( level )

    return {
        reason = cleanReason,
        sourceFile = info.short_src,
        lineNumber = info.currentline,
        locals = locals
    }
end

--- Creates a new environment for a test to run in
--- @param done fun(): nil The function called by the test to signal completion
--- @param fail fun( reason: string ): nil The function called by the test to signal failure
--- @param onFailedExpectation fun( errInfo: GLuaTest_FailCallbackInfo ): nil The function called when an expectation fails
function Helpers.MakeAsyncEnv( done, fail, onFailedExpectation )
    -- TODO: How can we make Stubs safer in Async environments?
    local stub, stubCleanup = stubMaker()
    local testEnv, envCleanup = makeTestLibStubs()

    --- Function that cleans up all actions taken by the test
    local function cleanup()
        envCleanup()
        stubCleanup()
    end

    --- @class GLuaTest_AsyncEnv
    local asyncEnv = {
        -- We manually catch expectation errors here in case
        -- they're called in an async function
        expect = function( subject )
            local built = expect( subject )
            local expected = built.to.expected
            local recordedFailure = false

            -- Wrap the error-throwing function
            -- and handle the error with the correct context
            -- (and to only record the first failure)
            built.to.expected = function( ... )
                if recordedFailure then return end

                local _, errInfo = xpcall( expected, Helpers.FailCallback, ... )
                onFailedExpectation( errInfo )

                recordedFailure = true
                print( "Expectation failed: will not run again" )
            end

            return built
        end,

        done = done,
        fail = fail,
        stub = stub,
    }

    local env = setmetatable(
        asyncEnv,
        {
            __index = function( _, idx )
                return testEnv[idx] or _G[idx]
            end
        }
    )

    hook.Run( "GLuaTest_AsyncEnvCreated", env )

    return env, cleanup
end

--- Runs a function with a given environment, and cleans up after
--- @param defaultEnv table
--- @param before? fun( state: GLuaTest_TestState ): nil The function to run before the test
--- @param func fun( state: GLuaTest_TestState ): nil The test function to run
--- @param state GLuaTest_TestState The state to pass to the test
--- @return GLuaTest_CaseRunResult The result of the test
function Helpers.SafeRunWithEnv( defaultEnv, before, func, state )
    local testEnv, cleanup = makeTestEnv()
    local ranExpect = false

    local ogExpect = testEnv.expect
    testEnv.expect = function( ... )
        ranExpect = true
        testEnv.expect = ogExpect
        return ogExpect( ... )
    end

    if before then
        setfenv( before, testEnv )
        before( state )
        setfenv( before, defaultEnv )
    end

    setfenv( func, testEnv )
    local success, output = xpcall( func, Helpers.FailCallback, state )
    setfenv( func, defaultEnv )

    cleanup()

    if success then
        -- If it succeeded but never ran `expect`, it's an empty test
        if not ranExpect then
            local empty = { result = "empty" } --[[@as GLuaTest_CaseEmpty]]
            return empty
        end

        local successful = { result = "success" } --[[@as GLuaTest_CaseSuccess]]
        return successful
    end

    -- Test failure
    local errInfo = output --[[@as GLuaTest_FailCallbackInfo]]
    local failure = { result = "failure", errInfo = errInfo } --[[@as GLuaTest_CaseFailure]]

    return failure
end

--- Creates a new test state
--- The state is unique to each case, but has a group-level passthrough
--- @return GLuaTest_TestState
function Helpers.CreateCaseState( testGroupState )
    return setmetatable( {}, {
        __index = function( self, idx )
            if testGroupState[idx] ~= nil then
                return testGroupState[idx]
            end

            if rawget( self, idx ) ~= nil then
                return rawget( self, idx )
            end
        end
    } )
end

return Helpers
