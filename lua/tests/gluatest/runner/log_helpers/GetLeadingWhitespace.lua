local LogHelpers = include( "gluatest/runner/log_helpers.lua" )
local GetLeadingWhitespace = LogHelpers.GetLeadingWhitespace

return {
    groupName = "GetLeadingWhitespace",

    cases = {
        {
            name = "Returns empty string for no leading whitespace",
            func = function()
                local result = GetLeadingWhitespace( "NoLeadingWhitespace" )
                expect( result ).to.equal( "" )
            end
        },
        {
            name = "Returns single space for one leading space",
            func = function()
                local result = GetLeadingWhitespace( " SingleSpace" )
                expect( result ).to.equal( " " )
            end
        },
        {
            name = "Returns multiple spaces for leading spaces",
            func = function()
                local result = GetLeadingWhitespace( "    FourSpaces" )
                expect( result ).to.equal( "    " )
            end
        },
        {
            name = "Returns tabs as leading whitespace",
            func = function()
                local result = GetLeadingWhitespace( "\t\tTabsBeforeText" )
                expect( result ).to.equal( "\t\t" )
            end
        },
        {
            name = "Returns mixed spaces and tabs as leading whitespace",
            func = function()
                local result = GetLeadingWhitespace( " \t MixedWhitespace" )
                expect( result ).to.equal( " \t " )
            end
        },
        {
            name = "Returns empty string for an empty line",
            func = function()
                local result = LogHelpers.GetLeadingWhitespace( "" )
                expect( result ).to.equal( "" )
            end
        },
        {
            name = "Returns empty string for a line with no whitespace and special characters",
            func = function()
                local result = LogHelpers.GetLeadingWhitespace( "!@#%&" )
                expect( result ).to.equal( "" )
            end
        },
        {
            name = "Handles only whitespace input",
            func = function()
                local result = LogHelpers.GetLeadingWhitespace( "     " )
                expect( result ).to.equal( "     " )
            end
        }
    }
}
