local Helpers = {}
local expect = include( "gluatest/expectations.lua" )

------------------
-- Cleanup stuff--
------------------

-- TODO: Make these explicitly per-test so it can work with async
local trackedHooks = {}
local hook_Add = function( event, name, func, ... )
    if not trackedHooks[event] then trackedHooks[event] = {} end
    table.insert( trackedHooks[event], name )

    return hook.Add( event, name, func, ... )
end

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

function Helpers.CleanupPostTest()
    for event, names in pairs( trackedHooks ) do
        for _, name in ipairs( names ) do
            hook.Remove( event, name )
        end
    end

    for _, name in ipairs( timerNames ) do
        timer.Remove( name )
    end

    trackedHooks = {}
    timerNames = {}
    timerCount = 0
end

local testHook = table.Inherit( { Add = hook_Add }, hook )
local testTimer = table.Inherit( { Create = timer_Create, Simple = timer_Simple }, timer )

local function makeTestEnv()
    return setmetatable(
    {
        expect = expect,
        _R = _R,
    },
    {
        __index = function( _, idx )
            if idx == "hook" then
                return testHook
            end

            if idx == "timer" then
                return testTimer
            end

            return _G[idx]
        end
    }
    )
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

local function findStackInfo()
    -- Step up through the stacks to find the error we care about

    for stack = 3, 12 do
        local info = debug.getinfo( stack, "lnS" )
        if not info then break end

        if #info.namewhat == 0 then return stack, info end
    end

    -- This should never happen!!
    print("The bad thing happened!!!!!")
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

                    local _, errInfo = xpcall( expected, FailCallback, ... )
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
    setfenv( func, makeTestEnv() )
    local success, errInfo = xpcall( func, Helpers.FailCallback, ... )
    setfenv( func, defaultEnv )

    return success, errInfo
end

return Helpers
