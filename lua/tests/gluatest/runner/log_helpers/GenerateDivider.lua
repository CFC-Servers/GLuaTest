local LogHelpers = include( "gluatest/runner/log_helpers.lua" )
local GenerateDivider = LogHelpers.GenerateDivider

return {
    groupName = "GenerateDivider",

    cases = {
        {
            name = "Generates divider based on longest line length and reason length",
            func = function()
                local lines = { "Short line", "This is a longer line of text" }
                local reason = "Reason for failure"
                local result = GenerateDivider( lines, reason )

                local expected = #lines[2] + #reason
                expect( #result ).to.equal( expected )
            end
        },
        {
            name = "Respects 110 character limit",
            func = function()
                local lines = { "A very long line that is repeated multiple times to exceed the limit" }
                local reason = "This reason text is also quite long to test the limit."
                local result = GenerateDivider( lines, reason )

                local total = #lines[1] + #reason
                expect( total ).to.beGreaterThan( 110 )
                expect( #result ).to.equal( 110 )
            end
        },
        {
            name = "Handles case with very short lines and reason",
            func = function()
                local lines = { "Tiny", "Small" }
                local reason = "Oops!"
                local result = LogHelpers.GenerateDivider( lines, reason )

                local expected = #lines[2] + #reason
                expect( #result ).to.equal( expected )
            end
        },
        {
            name = "Returns and empty string when empty lines and reason",
            func = function()
                local lines = { "", "", "" }
                local reason = ""
                local result = LogHelpers.GenerateDivider( lines, reason )

                expect( result ).to.equal( "" )
            end
        },
        {
            name = "Handles empty reason with non-empty lines",
            func = function()
                local lines = { "Line with some content", "Another line" }
                local reason = ""
                local result = LogHelpers.GenerateDivider( lines, reason )

                local expected = #lines[1]
                expect( #result ).to.equal( expected )
            end
        },
        {
            name = "Handles empty lines with non-empty reason",
            func = function()
                local lines = { "", "", "" }
                local reason = "Failure reason"
                local result = LogHelpers.GenerateDivider( lines, reason )

                expect( #result ).to.equal( #reason )
            end
        }
    }
}
