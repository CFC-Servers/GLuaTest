local LogHelpers = include( "gluatest/runner/log_helpers.lua" )
local GetLineWithContext = LogHelpers.GetLineWithContext

return {
    groupName = "GetLineWithContext",

    beforeEach = function( state )
        state.fileStub = stub( LogHelpers, "getFileLines" ).with( function()
            return {
                "Line 1",
                "Line 2",
                "Line 3",
                "Line 4",
                "Line 5",
                "Line 6",
                "Line 7",
                "Line 8",
                "Line 9",
                "Line 10"
            }
        end )
    end,

    cases = {
        {
            name = "Retrieves line with default context",
            func = function()
                local result = GetLineWithContext( "dummy_path", 5 )
                expect( result ).to.deepEqual( {
                    "Line 1",
                    "Line 2",
                    "Line 3",
                    "Line 4",
                    "Line 5"
                } )
            end
        },
        {
            name = "Retrieves line with specified context",
            func = function()
                local result = GetLineWithContext( "dummy_path", 5, 2 )
                expect( result ).to.deepEqual( {
                    "Line 3",
                    "Line 4",
                    "Line 5"
                } )
            end
        },
        {
            name = "Handles context at the beginning of the file",
            func = function()
                local result = GetLineWithContext( "dummy_path", 2 )
                expect( result ).to.deepEqual( {
                    "Line 1",
                    "Line 2"
                } )
            end
        },
        {
            name = "Handles context at the end of the file",
            func = function()
                local result = GetLineWithContext( "dummy_path", 10 )
                expect( result ).to.deepEqual( {
                    "Line 5",
                    "Line 6",
                    "Line 7",
                    "Line 8",
                    "Line 9",
                    "Line 10"
                } )
            end
        },
        {
            name = "Handles no context (context set to 0)",
            func = function()
                local result = GetLineWithContext( "dummy_path", 5, 0 )
                expect( result ).to.deepEqual( { "Line 5" } )
            end
        },
        {
            name = "Handles out-of-bounds line number",
            func = function()
                local result = GetLineWithContext( "dummy_path", 15 )
                expect( result ).to.deepEqual( { "Line 10" } )
            end
        },
        {
            name = "Handles out-of-bounds line number with no context",
            func = function()
                local result = GetLineWithContext( "dummy_path", 15, 0 )
                expect( result ).to.deepEqual( {} )
            end
        }
    }
}
