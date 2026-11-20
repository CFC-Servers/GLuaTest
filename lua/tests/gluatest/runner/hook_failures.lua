local function throw()
    error( "hook failure" )
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

return {
    groupName = "Hook failures",

    cases = {
        {
            name = "A failing beforeAll fails the group, skips its cases, and still runs afterAll",
            func = function()
                local caseFunc = stub()
                local afterAll = stub()

                local run = runGroup( {
                    beforeAll = throw,
                    afterAll = afterAll,
                    cases = { { name = "case", func = caseFunc } }
                } )

                expect( run.finished ).to.beTrue()
                expect( #run.results ).to.equal( 1 )
                expect( run.results[1].case.name ).to.equal( "beforeAll" )
                expect( run.results[1].success ).to.beFalse()
                expect( caseFunc ).wasNot.called()
                expect( afterAll ).was.called()
            end
        },

        {
            name = "A failing afterAll is reported and the group still finishes",
            func = function()
                local run = runGroup( {
                    afterAll = throw,
                    cases = { { name = "case", func = function() end } }
                } )

                expect( run.finished ).to.beTrue()
                expect( #run.results ).to.equal( 2 )
                expect( run.results[2].case.name ).to.equal( "afterAll" )
                expect( run.results[2].success ).to.beFalse()
            end
        },

        {
            name = "A failing beforeEach fails the case without running it, and still runs afterEach",
            func = function()
                local caseFunc = stub()
                local afterEach = stub()

                local run = runGroup( {
                    beforeEach = throw,
                    afterEach = afterEach,
                    cases = { { name = "case", func = caseFunc } }
                } )

                expect( run.finished ).to.beTrue()
                expect( run.results[1].success ).to.beFalse()
                expect( caseFunc ).wasNot.called()
                expect( afterEach ).was.called()
            end
        },

        {
            name = "A failing afterEach fails the case and the next case still runs",
            func = function()
                local run = runGroup( {
                    afterEach = throw,
                    cases = {
                        { name = "first", func = function() end },
                        { name = "second", func = function() end }
                    }
                } )

                expect( run.finished ).to.beTrue()
                expect( #run.results ).to.equal( 2 )
                expect( run.results[1].success ).to.beFalse()
                expect( run.results[2].success ).to.beFalse()
            end
        },

        {
            name = "A failing cleanup fails the case and still runs afterEach",
            func = function()
                local afterEach = stub()

                local run = runGroup( {
                    afterEach = afterEach,
                    cases = { { name = "case", func = function() end, cleanup = throw } }
                } )

                expect( run.finished ).to.beTrue()
                expect( run.results[1].success ).to.beFalse()
                expect( afterEach ).was.called()
            end
        },

        {
            name = "A failing when function fails the case and the next case still runs",
            func = function()
                local secondRan = false

                local run = runGroup( {
                    cases = {
                        { name = "first", func = function() end, when = throw },
                        { name = "second", func = function() secondRan = true end }
                    }
                } )

                expect( run.finished ).to.beTrue()
                expect( #run.results ).to.equal( 2 )
                expect( run.results[1].case.name ).to.equal( "first" )
                expect( run.results[1].success ).to.beFalse()
                expect( secondRan ).to.beTrue()
            end
        },

        {
            name = "A failing afterEach fails an async case",
            async = true,
            timeout = 2,
            func = function()
                local run

                run = runGroup( {
                    afterEach = function()
                        timer.Simple( 0, function()
                            expect( run.finished ).to.beTrue()
                            expect( run.results[1].success ).to.beFalse()
                            done()
                        end )

                        throw()
                    end,
                    cases = {
                        {
                            name = "case",
                            async = true,
                            func = function()
                                done()
                            end
                        }
                    }
                } )
            end
        }
    }
}
