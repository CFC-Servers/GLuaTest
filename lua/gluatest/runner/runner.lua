local Helpers = include( "gluatest/runner/helpers.lua" )
local MakeTestEnv = Helpers.MakeTestEnv
local FailCallback = Helpers.FailCallback
local CleanupPostTest = Helpers.CleanupPostTest

local ResultLogger = include( "gluatest/runner/logger.lua" )
local LogTestResults = ResultLogger.LogTestResults
local LogFileStart = ResultLogger.LogFileStart

return function( testFiles )
    if CLIENT and not GLuaTest.RUN_CLIENTSIDE then return end

    -- TODO: Scope these by file or print/clear results after each file
    local results = {}

    -- TODO: Move the environment creation elsewhere
    local defaultEnv = getfenv( 1 )
    local testEnv = MakeTestEnv()

    hook.Run( "GLuaTest_StartedTestRun", testFiles )

    local function runNextTest( tests )
        local test = table.remove( tests )
        if not test then
            -- TODO: Log failure details here, log the one-line results during the loop
            LogTestResults( results )
            hook.Run( "GLuaTest_RanTestFiles", testFiles, results )
            return
        end

        local fileName = test.fileName
        local cases = test.cases
        local caseCount = #cases

        hook.Run( "GLuaTest_RunningTestFile", test )
        LogFileStart( fileName )

        local asyncCases = {}

        for c = 1, caseCount do
            local case = cases[c]

            local shared = case.shared
            local clientside = case.clientside
            local serverside = not case.clientside
            local shouldRun = shared or ( clientside and CLIENT ) or ( serverside and SERVER )

            if shouldRun then
                if case.async then
                    asyncCases[case.name] = case
                else
                    local func = case.func

                    setfenv( func, testEnv )
                    local success, errInfo = xpcall( func, FailCallback )
                    setfenv( func, defaultEnv )

                    CleanupPostTest()

                    hook.Run( "GLuaTest_RanTestCase", test, case, success, errInfo )

                    table.insert( results, {
                        success = success,
                        case = case,
                        errInfo = success and nil or errInfo
                    } )
                end
            end
        end

        local asyncCount = table.Count( asyncCases )
        if asyncCount == 0 then
            runNextTest( tests )
            return
        end

        local callbacks = {}
        local checkComplete = function()
            local cbCount = table.Count( callbacks )
            if cbCount ~= asyncCount then return end

            timer.Remove( "GLuaTest_AsyncWaiter" )
            runNextTest( tests )
        end

        for name, case in pairs( asyncCases ) do
            local caseFunc = case.func
            local caseTimeout = case.timeout

            local asyncEnv = setmetatable(
                {
                    -- We manually catch expectation errors here in case
                    -- they're called in an async function
                    expect = function( subject )
                        local built = expect( subject )

                        -- Wrap the error-throwing function
                        -- and handle the error with the correct context
                        built.to.expected = function( ... )
                            local success, errInfo = xpcall( expect, FailCallback, subject )
                            setfenv( caseFunc, defaultEnv )

                            -- Record the failure
                            hook.Run( "GLuaTest_RanTestCase", test, case, success, errInfo )

                            table.insert( results, {
                                success = false,
                                case = case,
                                errInfo = errInfo
                            })

                            timer.Remove( "GLuaTest_AsyncTimeout_" .. name )

                            callbacks[name] = false
                            checkComplete()

                            -- Halt the test?
                            -- (Should be caught by the outer xpcall)
                            error( "" )
                        end

                        return built
                    end,

                    done = function()
                        if callbacks[name] ~= nil then
                            ErrorNoHaltWithStack( "Tried to call done() after we already recorded a result?" )
                            print( name )
                            return
                        end

                        hook.Run( "GLuaTest_RanTestCase", test, case, true )
                        table.insert( results, {
                            success = true,
                            case = case
                        } )

                        callbacks[name] = true
                        setfenv( caseFunc, defaultEnv )
                        checkComplete()
                    end,

                    _R = _R
                },
                { __index = _G }
            )

            setfenv( caseFunc, asyncEnv )
            local success, errInfo = xpcall( caseFunc, FailCallback )

            if caseTimeout then
                timer.Create( "GluaTest_AsyncTimeout_" .. name, caseTimeout, 1, function()
                    local timeoutInfo = { reason = "Timeout" }

                    hook.Run( "GLuaTest_RanTestCase", test, case, success, timeoutInfo )
                    callbacks[name] = false
                    table.insert( results, {
                        success = false,
                        case = case,
                        errInfo = timeoutInfo
                    })

                    setfenv( caseFunc, defaultEnv )
                end )
            end

            -- If the test failed while calling it
            -- (Async expectation failures handled in asyncEnv.expect)
            -- (Async unhandled failures handled with timeouts)
            if not success then
                callbacks[name] = false
                timer.Remove( "GLuaTest_AsyncTimeout_" .. name )
                hook.Run( "GLuaTest_RanTestCase", test, case, success, errInfo )
                table.insert( results, {
                    success = success,
                    case = case,
                    errInfo = errInfo
                })
            end
        end

        timer.Create( "GLuaTest_AsyncWaiter", 60, 1, function()
            for name, case in pairs( asyncCases ) do
                if callbacks[name] == nil then
                    hook.Run( "GLuaTest_TestCaseTimeout", test, case )
                    table.insert( results, {
                        success = false,
                        case = case,
                        errInfo = { reason = "Timeout" }
                    })
                end
            end

            runNextTest( tests )
        end )
    end

    runNextTest( testFiles )
end
