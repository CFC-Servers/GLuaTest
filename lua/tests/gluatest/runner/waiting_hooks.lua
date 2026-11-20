local AFTER_RESUME = 0.1
local SHORT_HOOK_TIMEOUT = 0.1
local AFTER_SHORT_HOOK_TIMEOUT = 0.3

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
local function makeYieldingHook()
    local yieldingHook = {}

    yieldingHook.func = function()
        yieldingHook.coroutine = coroutine.running()
        coroutine.yield()
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

return {
    groupName = "Waiting hooks",

    beforeAll = function( state )
        local beforeAllCoroutine = coroutine.running()
        timer.Simple( AFTER_RESUME, function()
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

                timer.Simple( AFTER_RESUME, function()
                    expect( recordingCase.ran ).to.beTrue()
                    expect( run.finished ).to.beTrue()
                    expect( #run.results ).to.equal( 1 )
                    expect( run.results[1].case.name ).to.equal( "case" )
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

                timer.Simple( AFTER_RESUME, function()
                    expect( run.finished ).to.beTrue()
                    expect( #run.results ).to.equal( 1 )
                    done()
                end )
            end
        },

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

                timer.Simple( AFTER_SHORT_HOOK_TIMEOUT, function()
                    expect( run.finished ).to.beTrue()
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

                timer.Simple( AFTER_SHORT_HOOK_TIMEOUT, function()
                    expect( run.finished ).to.beTrue()
                    expect( #run.results ).to.equal( 2 )
                    expect( run.results[2].case.name ).to.equal( "afterAll" )
                    expect( run.results[2].errInfo.reason ).to.equal( "Timeout" )
                    done()
                end )
            end
        },

        {
            name = "A beforeAll that errors after yielding fails the group and skips its cases",
            async = true,
            timeout = 2,
            func = function()
                local recordingCase = makeRecordingCase()
                local beforeAllCoroutine

                local run = runGroup( {
                    beforeAll = function()
                        beforeAllCoroutine = coroutine.running()
                        coroutine.yield()

                        error( "hook failure" )
                    end,
                    cases = { recordingCase.case }
                } )

                coroutine.resume( beforeAllCoroutine )

                timer.Simple( AFTER_RESUME, function()
                    expect( run.finished ).to.beTrue()
                    expect( #run.results ).to.equal( 1 )
                    expect( run.results[1].case.name ).to.equal( "beforeAll" )
                    expect( run.results[1].success ).to.beFalse()
                    expect( recordingCase.ran ).to.beFalse()
                    done()
                end )
            end
        },

        {
            name = "A beforeAll that finishes in time is not reported again when its timeout passes",
            async = true,
            timeout = 2,
            func = function()
                local recordingCase = makeRecordingCase()
                local beforeAll = makeYieldingHook()

                local run = runGroup( {
                    hookTimeout = SHORT_HOOK_TIMEOUT,
                    beforeAll = beforeAll.func,
                    cases = { recordingCase.case }
                } )

                beforeAll.resume()

                timer.Simple( AFTER_SHORT_HOOK_TIMEOUT, function()
                    expect( run.finished ).to.beTrue()
                    expect( #run.results ).to.equal( 1 )
                    expect( run.results[1].case.name ).to.equal( "case" )
                    done()
                end )
            end
        },

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

                timer.Simple( AFTER_RESUME, function()
                    expect( recordingCase.ran ).to.beTrue()
                    expect( recordingCase.coroutine ).toNot.equal( beforeAll.coroutine )
                    done()
                end )
            end
        }
    }
}
