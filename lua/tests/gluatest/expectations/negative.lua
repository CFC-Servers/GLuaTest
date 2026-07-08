local Helpers = include( "gluatest/runner/helpers.lua" )

return {
    groupName = "Negative Expectations",

    cases = {
        {
            name = "called requires a stub",
            func = function()
                expect( function()
                    expect( {} ).wasNot.called()
                end ).to.errWith( ".called expects a stub" )
            end
        },
        {
            name = "errWith passes when the function succeeds",
            func = function()
                expect( function()
                    expect( function() end ).notTo.errWith( "boom" )
                end ).to.succeed()
            end
        },
        {
            name = "async negated expectation failures are recorded",
            func = function()
                local recordedFailure
                local env, cleanupFuncs = Helpers.MakeAsyncEnv( function() end, function() end, function( errInfo )
                    recordedFailure = errInfo
                end )
                local defaultEnv = getfenv( 1 )
                local testFunc = function()
                    expect( true ).notTo.beTrue()
                end

                setfenv( testFunc, env )
                testFunc()
                setfenv( testFunc, defaultEnv )

                for _, cleanup in ipairs( cleanupFuncs ) do
                    cleanup()
                end

                expect( recordedFailure ).to.exist()
                expect( recordedFailure.reason ).to.equal( "Expected true to not be true" )
            end
        }
    }
}
