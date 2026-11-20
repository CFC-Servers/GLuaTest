local SHORT_HOOK_TIMEOUT = 0.1

local waitCount = 0

--- Calls the callback as soon as the condition holds, so a test only waits as long as it has to
--- @param condition fun(): boolean
--- @param callback fun(): nil
local function whenTrue( condition, callback )
    waitCount = waitCount + 1
    local identifier = "GLuaTest_WaitingHooksTest_" .. waitCount

    hook.Add( "Think", identifier, function()
        if not condition() then return end

        hook.Remove( "Think", identifier )
        callback()
    end )
end

--- Runs a group through a real TestGroupRunner and collects what it reports
--- @param group table
local function runGroup( group )
    local run = { results = {}, finished = false }

    local testRunner = {
        AddResult = function( _, result )
            table.insert( run.results, result )
        end
    }

    local groupRunner = GLuaTest.TestGroupRunner( testRunner, group )
    groupRunner:Run( function()
        run.finished = true
    end )

    return run
end

--- Makes a hook that yields, and records its coroutine so the test can resume it
--- @param afterResume? fun(): nil Runs inside the hook once it has been resumed
local function makeYieldingHook( afterResume )
    local yieldingHook = {}

    yieldingHook.func = function()
        yieldingHook.coroutine = coroutine.running()
        coroutine.yield()

        if afterResume then afterResume() end
    end

    yieldingHook.resume = function()
        coroutine.resume( yieldingHook.coroutine )
    end

    return yieldingHook
end

--- Makes a test case that records whether it ran and which coroutine it ran in
local function makeRecordingCase()
    local recordingCase = { ran = false }

    recordingCase.case = {
        name = "case",
        func = function()
            recordingCase.ran = true
            recordingCase.coroutine = coroutine.running()
        end
    }

    return recordingCase
end

local function throw()
    error( "hook failure" )
end

return {
    groupName = "Waiting hooks",

    beforeAll = function( state )
        local beforeAllCoroutine = coroutine.running()
        timer.Simple( 0, function()
            coroutine.resume( beforeAllCoroutine )
        end )

        coroutine.yield()
        state.waitedInBeforeAll = true
    end,

    cases = {
        {
            name = "The beforeAll of this group waited before its cases started",
            func = function( state )
                expect( state.waitedInBeforeAll ).to.beTrue()
            end
        },

        -- Holding the group until a hook is resumed

        {
            name = "A beforeAll that yields holds the cases until it is resumed",
            async = true,
            timeout = 2,
            func = function()
                local recordingCase = makeRecordingCase()
                local beforeAll = makeYieldingHook()

                local run = runGroup( {
                    beforeAll = beforeAll.func,
                    cases = { recordingCase.case }
                } )

                expect( recordingCase.ran ).to.beFalse()
                expect( run.finished ).to.beFalse()

                beforeAll.resume()

                whenTrue( function() return run.finished end, function()
                    expect( recordingCase.ran ).to.beTrue()
                    expect( #run.results ).to.equal( 1 )
                    done()
                end )
            end
        },

        {
            name = "An afterAll that yields holds the group until it is resumed",
            async = true,
            timeout = 2,
            func = function()
                local recordingCase = makeRecordingCase()
                local afterAll = makeYieldingHook()

                local run = runGroup( {
                    afterAll = afterAll.func,
                    cases = { recordingCase.case }
                } )

                expect( recordingCase.ran ).to.beTrue()
                expect( run.finished ).to.beFalse()

                afterAll.resume()

                whenTrue( function() return run.finished end, function()
                    expect( #run.results ).to.equal( 1 )
                    done()
                end )
            end
        },

        -- Timing out

        {
            name = "A beforeAll that is never resumed times out, skips its cases, and still runs afterAll",
            async = true,
            timeout = 2,
            func = function()
                local recordingCase = makeRecordingCase()
                local afterAll = stub()
                local beforeAll = makeYieldingHook()

                local run = runGroup( {
                    hookTimeout = SHORT_HOOK_TIMEOUT,
                    beforeAll = beforeAll.func,
                    afterAll = afterAll,
                    cases = { recordingCase.case }
                } )

                whenTrue( function() return run.finished end, function()
                    expect( #run.results ).to.equal( 1 )
                    expect( run.results[1].case.name ).to.equal( "beforeAll" )
                    expect( run.results[1].success ).to.beFalse()
                    expect( run.results[1].errInfo.reason ).to.equal( "Timeout" )
                    expect( recordingCase.ran ).to.beFalse()
                    expect( afterAll ).was.called()
                    done()
                end )
            end
        },

        {
            name = "An afterAll that is never resumed times out and the group still finishes",
            async = true,
            timeout = 2,
            func = function()
                local recordingCase = makeRecordingCase()
                local afterAll = makeYieldingHook()

                local run = runGroup( {
                    hookTimeout = SHORT_HOOK_TIMEOUT,
                    afterAll = afterAll.func,
                    cases = { recordingCase.case }
                } )

                whenTrue( function() return run.finished end, function()
                    expect( #run.results ).to.equal( 2 )
                    expect( run.results[2].case.name ).to.equal( "afterAll" )
                    expect( run.results[2].errInfo.reason ).to.equal( "Timeout" )
                    done()
                end )
            end
        },

        {
            name = "A callable table used as a beforeAll times out without stalling the group",
            async = true,
            timeout = 2,
            func = function()
                local beforeAll = setmetatable( {}, { __call = function() coroutine.yield() end } )

                local run = runGroup( {
                    hookTimeout = SHORT_HOOK_TIMEOUT,
                    beforeAll = beforeAll,
                    cases = { { name = "case", func = function() end } }
                } )

                whenTrue( function() return run.finished end, function()
                    expect( run.results[1].errInfo.reason ).to.equal( "Timeout" )
                    done()
                end )
            end
        },

        {
            name = "A timeout points at the function that was waiting",
            async = true,
            timeout = 2,
            func = function()
                local beforeAll = makeYieldingHook()
                local definedAt = debug.getinfo( beforeAll.func, "S" )

                local run = runGroup( {
                    hookTimeout = SHORT_HOOK_TIMEOUT,
                    beforeAll = beforeAll.func,
                    cases = { { name = "case", func = function() end } }
                } )

                whenTrue( function() return run.finished end, function()
                    expect( run.results[1].errInfo.sourceFile ).to.equal( definedAt.short_src )
                    expect( run.results[1].errInfo.lineNumber ).to.equal( definedAt.linedefined )
                    done()
                end )
            end
        },

        {
            name = "A beforeAll that finishes in time is not reported again when its timeout passes",
            async = true,
            timeout = 2,
            func = function()
                local PAST_SHORT_HOOK_TIMEOUT = SHORT_HOOK_TIMEOUT * 3

                local recordingCase = makeRecordingCase()
                local beforeAll = makeYieldingHook()

                local run = runGroup( {
                    hookTimeout = SHORT_HOOK_TIMEOUT,
                    beforeAll = beforeAll.func,
                    cases = { recordingCase.case }
                } )

                beforeAll.resume()

                timer.Simple( PAST_SHORT_HOOK_TIMEOUT, function()
                    expect( run.finished ).to.beTrue()
                    expect( #run.results ).to.equal( 1 )
                    expect( run.results[1].case.name ).to.equal( "case" )
                    done()
                end )
            end
        },

        -- Failing after a hook has waited

        {
            name = "A beforeAll that errors after yielding fails the group and skips its cases",
            async = true,
            timeout = 2,
            func = function()
                local recordingCase = makeRecordingCase()
                local beforeAll = makeYieldingHook( throw )

                local run = runGroup( {
                    beforeAll = beforeAll.func,
                    cases = { recordingCase.case }
                } )

                beforeAll.resume()

                whenTrue( function() return run.finished end, function()
                    expect( #run.results ).to.equal( 1 )
                    expect( run.results[1].case.name ).to.equal( "beforeAll" )
                    expect( run.results[1].success ).to.beFalse()
                    expect( recordingCase.ran ).to.beFalse()
                    done()
                end )
            end
        },

        -- Coroutines

        {
            name = "The cases do not run inside the coroutine of a beforeAll that yielded",
            async = true,
            timeout = 2,
            func = function()
                local recordingCase = makeRecordingCase()
                local beforeAll = makeYieldingHook()

                runGroup( {
                    beforeAll = beforeAll.func,
                    cases = { recordingCase.case }
                } )

                beforeAll.resume()

                whenTrue( function() return recordingCase.ran end, function()
                    expect( recordingCase.coroutine ).toNot.equal( beforeAll.coroutine )
                    done()
                end )
            end
        }
    }
}
