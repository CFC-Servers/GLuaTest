---@diagnostic disable: param-type-mismatch
return {
    groupName = "callerRecovery",
    cases = {
        {
            name = "Called function name is included in error message",
            func = function()
                -- This never worked, instead of 'Left' it had given '?'
                expect( string.Left, nil ).to.errWith( "bad argument #1 to 'Left' (string expected, got nil)" )

                -- This is how it always had worked fine
                local testFunc = function() string.Left( nil, nil ) end
                expect( testFunc ).to.errWith( "bad argument #1 to 'Left' (string expected, got nil)" )
            end
        }
    }
}
