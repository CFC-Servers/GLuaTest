local LogHelpers = include( "gluatest/runner/log_helpers.lua" )
local NormalizeLinesIndent = LogHelpers.NormalizeLinesIndent

return {
    groupName = "NormalizeLinesIndent",

    cases = {
        {
            name = "Dedents lines with uniform indentation",
            func = function()
                local lines = {
                    "    Line with four spaces",
                    "    Another line with four spaces"
                }

                local result = NormalizeLinesIndent( lines )
                expect( result[1] ).to.equal( "Line with four spaces" )
                expect( result[2] ).to.equal( "Another line with four spaces" )
            end
        },
        {
            name = "Dedents lines with varying indentation",
            func = function()
                local lines = {
                    "        Eight spaces",
                    "    Four spaces",
                    "            Twelve spaces"
                }

                local result = NormalizeLinesIndent( lines )
                expect( result[1] ).to.equal( "    Eight spaces" )
                expect( result[2] ).to.equal( "Four spaces" )
                expect( result[3] ).to.equal( "        Twelve spaces" )
            end
        },
        {
            name = "Handles already unindented lines",
            func = function()
                local lines = {
                    "No indent here",
                    "Also no indent"
                }

                local result = NormalizeLinesIndent( lines )
                expect( result[1] ).to.equal( "No indent here" )
                expect( result[2] ).to.equal( "Also no indent" )
            end
        },
        {
            name = "Returns lines unchanged if only empty lines",
            func = function()
                local lines = {
                    "",
                    "",
                    ""
                }

                local result = NormalizeLinesIndent( lines )
                expect( result[1] ).to.equal( "" )
                expect( result[2] ).to.equal( "" )
                expect( result[3] ).to.equal( "" )
            end
        },
        {
            name = "Dedents lines with mixed content and empty lines",
            func = function()
                local lines = {
                    "    Four spaces",
                    "",
                    "    Another line with four spaces",
                    ""
                }

                local result = NormalizeLinesIndent( lines )
                expect( result[1] ).to.equal( "Four spaces" )
                expect( result[2] ).to.equal( "" )
                expect( result[3] ).to.equal( "Another line with four spaces" )
                expect( result[4] ).to.equal( "" )
            end
        },

        {
            name = "Dedents a single indented line",
            func = function()
                local lines = {
                    "        Single line with eight spaces"
                }

                local result = NormalizeLinesIndent( lines )
                expect( result[1] ).to.equal( "Single line with eight spaces" )
            end
        },
        {
            name = "Dedents lines containing only whitespace",
            func = function()
                local lines = {
                    "        ",
                    "    ",
                    "            "
                }

                local result = NormalizeLinesIndent( lines )
                expect( result[1] ).to.equal( "    " )
                expect( result[2] ).to.equal( "" )
                expect( result[3] ).to.equal( "        " )
            end
        },
        {
            name = "Returns empty array for empty input",
            func = function()
                local lines = {}
                local result = NormalizeLinesIndent( lines )
                expect( #result ).to.equal( 0 )
            end
        }
    }
}
