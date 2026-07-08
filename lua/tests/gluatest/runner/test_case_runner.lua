include( "gluatest/runner/test_case_runner.lua" )

local noop = function() end

local function makeTestGroupRunner( group )
    local results = {}
    local runner = {
        group = group,
        results = results
    }

    function runner:SetSucceeded( case )
        table.insert( results, { case = case, success = true } )
    end

    function runner:SetFailed( case, errInfo )
        table.insert( results, { case = case, success = false, errInfo = errInfo } )
    end

    function runner:SetEmpty( case )
        table.insert( results, { case = case, empty = true } )
    end

    return runner
end

local function makeCase( name, func )
    return {
        name = name,
        func = func,
        cleanup = noop,
        id = name,
        state = {}
    }
end

return {
    groupName = "TestCaseRunner",

    cases = {
        {
            name = "Records sync beforeEach errors as failures",
            func = function()
                local caseRan = false
                local group = {
                    beforeEach = function()
                        error( "sync beforeEach failed" )
                    end
                }
                local testGroupRunner = makeTestGroupRunner( group )
                local case = makeCase( "sync_before_each_failure", function()
                    caseRan = true
                end )
                local caseRunner = GLuaTest.TestCaseRunner( testGroupRunner, case )
                local completed = false

                caseRunner:RunSync( function()
                    completed = true
                end )

                expect( completed ).to.beTrue()
                expect( caseRan ).to.beFalse()
                expect( #testGroupRunner.results ).to.equal( 1 )
                expect( testGroupRunner.results[1].success ).to.beFalse()
                expect( testGroupRunner.results[1].errInfo.reason ).to.equal( "Unhandled: sync beforeEach failed" )
            end
        },
        {
            name = "Records async beforeEach errors as failures",
            func = function()
                local caseRan = false
                local group = {
                    beforeEach = function()
                        error( "async beforeEach failed" )
                    end
                }
                local testGroupRunner = makeTestGroupRunner( group )
                local case = makeCase( "async_before_each_failure", function()
                    caseRan = true
                    done()
                end )
                local caseRunner = GLuaTest.TestCaseRunner( testGroupRunner, case )
                local completed = false

                caseRunner:RunAsync( function()
                    completed = true
                end )

                expect( completed ).to.beTrue()
                expect( caseRan ).to.beFalse()
                expect( #testGroupRunner.results ).to.equal( 1 )
                expect( testGroupRunner.results[1].success ).to.beFalse()
                expect( testGroupRunner.results[1].errInfo.reason ).to.equal( "Unhandled: async beforeEach failed" )
            end
        }
    }
}
