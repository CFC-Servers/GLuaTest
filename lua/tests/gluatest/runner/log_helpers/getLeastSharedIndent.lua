local LogHelpers = include( "gluatest/runner/log_helpers.lua" )
local getLeastSharedIndent = LogHelpers.getLeastSharedIndent

return {
    groupName = "getLeastSharedIndent",

    cases = {
        {
            name = "Calculates least shared indent for uniform indentation",
            func = function()
                local lines = {
                    "    Line with indent",
                    "    Another line with same indent"
                }

                local result = getLeastSharedIndent( lines )
                expect( result ).to.equal( 4 )
            end
        },
        {
            name = "Handles lines with varying indentation correctly",
            func = function()
                local lines = {
                    "        Eight spaces",
                    "    Four spaces",
                    "            Twelve spaces"
                }

                local result = getLeastSharedIndent( lines )
                expect( result ).to.equal( 4 )
            end
        },
        {
            name = "Ignores empty lines",
            func = function()
                local lines = {
                    "    Line with indent",
                    "",
                    "    Another line with indent",
                    ""
                }

                local result = getLeastSharedIndent( lines )
                expect( result ).to.equal( 4 )
            end
        },
        {
            name = "Returns 0 for unindented lines",
            func = function()
                local lines = {
                    "No indent here",
                    "Also no indent"
                }

                local result = getLeastSharedIndent( lines )
                expect( result ).to.equal( 0 )
            end
        },
        {
            name = "Returns 0 for all empty lines",
            func = function()
                local lines = {
                    "",
                    "",
                    ""
                }

                local result = getLeastSharedIndent( lines )
                expect( result ).to.equal( 0 )
            end
        }
    }
}
