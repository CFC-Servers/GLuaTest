local Helpers = {}
local expect = include( "gluatest/expectations/expect.lua" )
local stubMaker = include( "gluatest/stubs/stubMaker.lua" )

------------------
-- Cleanup stuff--
------------------

local makeHookTable = function()
    local trackedHooks = {}
    local hook_Add = function( event, name, func, ... )
        if not trackedHooks[event] then trackedHooks[event] = {} end
        table.insert( trackedHooks[event], name )

        return hook.Add( event, name, func, ... )
    end

    local function cleanup()
        for event, names in pairs( trackedHooks ) do
            for _, name in ipairs( names ) do
                hook.Remove( event, name )
            end
        end
    end

    return table.Inherit( { Add = hook_Add }, hook ), cleanup
end

local function makeTimerTable()
    local timerCount = 0
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
        _R = _R,
        stub = stub,
        expect = expect,
    }

    local function cleanup()
        stubCleanup()
    end

    return tools, cleanup
end

local function makeTestEnv()
    local testEnv, envCleanup = makeTestLibStubs()
    local testTools, toolsCleanup = makeTestTools()

    local function cleanup()
        envCleanup()
        toolsCleanup()
    end

    return setmetatable(
        testTools,
        {
            __index = function( _, idx )
                return testEnv[idx] or _G[idx]
            end
        }
    ), cleanup
end

local function getLocals( level )
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

-- FIXME: There has to be a better way to do this
local function findStackInfo()
    -- Step up through the stacks to find the error we care about

    for stack = 1, 12 do
        local info = debug.getinfo( stack, "lnS" )
        if not info then break end

        local emptyName = #info.namewhat == 0
        local notGluatest = not string.StartWith( info.short_src, "addons/gluatest" )

        if emptyName and notGluatest then
            return stack, info
        end
    end

    -- This should never happen!!
    ErrorNoHaltWithStack("The bad thing happened!!!!!")
    return 2, debug.getinfo( 2, "lnS" )
end

function Helpers.FailCallback( reason )
    if reason == "" then
        ErrorNoHaltWithStack( "Received empty error reason in failCallback- ignoring " )
        return
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

function Helpers.MakeAsyncEnv( onDone, onFailedExpectation )
    return setmetatable(
        {
            -- We manually catch expectation errors here in case
            -- they're called in an async function
            expect = function( subject )
                local built = expect( subject )
                local expected = built.to.expected
                local recordedFailure = false

                -- Wrap the error-throwing function
                -- and handle the error with the correct context
                built.to.expected = function( ... )
                    if recordedFailure then return end

                    local _, errInfo = xpcall( expected, Helpers.FailCallback, ... )
                    onFailedExpectation( errInfo )

                    recordedFailure = true
                end

                return built
            end,

            done = onDone,
            _R = _R
        },
        { __index = _G }
    )
end

function Helpers.SafeRunWithEnv( defaultEnv, func, ... )
    local testEnv, cleanup = makeTestEnv()
    local ranExpect = false

    local ogExpect = testEnv.expect
    testEnv.expect = function( ... )
        ranExpect = true
        testEnv.expect = ogExpect
        return ogExpect( ... )
    end

    setfenv( func, testEnv )
    local success, errInfo = xpcall( func, Helpers.FailCallback, ... )
    setfenv( func, defaultEnv )

    cleanup()

    -- If it succeeded but never ran `expect`, it's an empty test
    if success and not ranExpect then
        return nil, nil
    end

    return success, errInfo
end

return Helpers
