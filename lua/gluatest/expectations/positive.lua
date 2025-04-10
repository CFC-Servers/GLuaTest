local type = type
local TypeID = TypeID
local IsValid = IsValid
local isstring = isstring
local string_format = string.format
local GetDiff = include( "utils/table_diff.lua" )

-- Positive checks
return function( subject, ... )
    -- Args that are passed after the subject, i.e. expect( subject, arg1, arg2 )
    local args = { ... }

    -- Wrap the subject in quotes if if's a string
    local fmtPrefix = "Expectation Failed: Expected %s "
    if isstring( subject ) then
        fmtPrefix = string.Replace( fmtPrefix, "%s", "'%s'" )
    end

    --- @class GLuaTest_PositiveExpectations
    local expectations = {
        --- Handles the error message for the expectation failure
        expected = function( suffix, ... )
            local fmt = fmtPrefix .. suffix
            local message = string_format( fmt, subject, ... )

            error( message )
        end
    }


    local i = expectations

    --- Expects the subject is exactly equal to the comparison
    --- @param comparison any
    function expectations.equal( comparison )
        if subject ~= comparison then
            local expectedMessage = "to equal %s"

            if isstring( comparison ) then
                expectedMessage = "to equal '%s'"
            end

            i.expected( expectedMessage, comparison )
        end
    end

    --- @deprecated
    --- @param comparison any
    function expectations.eq( comparison )
        GLuaTest.DeprecatedNotice( "to.eq( value )", "to.equal( value )" )
        return expectations.equal( comparison )
    end

    --- Expects the subject table is deeply equal to the comparison
    --- @param comparison table
    function expectations.deepEqual( comparison )
        assert( TypeID( subject ) == TYPE_TABLE, "deepEqual expects a table" )
        assert( TypeID( comparison ) == TYPE_TABLE, "deepEqual expects a table" )

        local diff, path = GetDiff( subject, comparison )

        if diff then
            i.expected( "to deeply equal '%s' - found a difference at '%s'", comparison, path )
        end
    end

    --- Expects the subject is approximately equal to the comparison, with a tolerance
    --- @param comparison number
    --- @param tolerance? number Tolerance for the comparison
    function expectations.aboutEqual( comparison, tolerance )
        assert( TypeID( subject ) == TYPE_NUMBER, ".aboutEqual expects a number" )

        tolerance = tolerance or 0.00001
        local difference = math.abs( subject - comparison )

        if difference > tolerance then
            i.expected( "to be within '%s' of '%s' - found a difference of '%s'", tolerance, comparison, difference )
        end
    end

    --- Expects the subject is less than the comparison
    --- @param comparison any
    function expectations.beLessThan( comparison )
        if subject >= comparison then
            i.expected( "to be less than '%s'", comparison )
        end
    end

    --- Expects the subject is greater than the comparison
    --- @param comparison any
    function expectations.beGreaterThan( comparison )
        if subject <= comparison then
            i.expected( "to be greater than '%s'", comparison )
        end
    end

    --- Expects the subject is between the lower and upper bounds
    --- @param lower any
    --- @param upper any
    function expectations.beBetween( lower, upper )
        if subject < lower or subject > upper then
            i.expected( "to be between '%s' and '%s'", lower, upper )
        end
    end

    --- Expects the subject is exactly equal to true
    function expectations.beTrue()
        if subject ~= true then
            i.expected( "to be true" )
        end
    end

    --- Check if the subject is exactly equal to false
    function expectations.beFalse()
        if subject ~= false then
            i.expected( "to be false" )
        end
    end

    --- Expects the subject to pass an IsValid check
    function expectations.beValid()
        if not IsValid( subject ) then
            i.expected( "to be valid" )
        end
    end

    --- Expects the subject to fail an IsValid check
    function expectations.beInvalid()
        if IsValid( subject ) then
            i.expected( "to be invalid" )
        end
    end

    --- Expects the subject to be nil
    function expectations.beNil()
        if subject ~= nil then
            i.expected( "to be nil" )
        end
    end

    --- Expects the subject to be NaN
    function expectations.beNaN()
        assert( TypeID( subject ) == TYPE_NUMBER, ".beNaN expects a number" )

        if subject == subject then
            i.expected( "to be NaN" )
        end
    end

    --- Expects the subject to not be nil
    function expectations.exist()
        if subject == nil then
            i.expected( "to exist, got nil" )
        end
    end

    --- Expects the subject to be of the given type
    --- @param comparison string
    function expectations.beA( comparison )
        local class = type( subject )

        if class ~= comparison then
            i.expected( "to be a '%s'", comparison )
        end
    end

    --- Expect the subject to be of the given type
    function expectations.beAn( comparison )
        local class = type( subject )

        if class ~= comparison then
            i.expected( "to not be an '%s'", comparison )
        end
    end

    --- Expects the subject function to run succesfully
    function expectations.succeed()
        assert( TypeID( subject ) == TYPE_FUNCTION, ".succeed expects a function" )

        local success, err = pcall( subject, unpack( args ) )

        if success == false then
            i.expected( "to succeed, got: %s", err )
        end
    end

    --- Expects the subject function to fail when run
    function expectations.err()
        assert( TypeID( subject ) == TYPE_FUNCTION, ".err expects a function" )

        local success = pcall( subject, unpack( args ) )

        if success == true then
            i.expected( "to error" )
        end
    end

    --- Expects the subject function to fail when run, and produce the given error
    --- @param comparison string
    function expectations.errWith( comparison )
        assert( TypeID( subject ) == TYPE_FUNCTION, ".errWith expects a function" )
        assert( TypeID( comparison ) == TYPE_STRING, ".errWith expects a string" )

        local success, err = pcall( subject, unpack( args ) )

        if success == true then
            i.expected( "to error with '%s'", comparison )
        else
            if string.StartsWith( err, "lua/" ) or string.StartsWith( err, "addons/" ) then
                local _, endOfPath = string.find( err, ":%d+: ", 1 )
                assert( endOfPath, "Could not find end of path in error message: " .. err )

                err = string.sub( err, endOfPath + 1 )
            end

            if err ~= comparison then
                i.expected( "to error with '%s', got '%s'", comparison, err )
            end
        end
    end

    --- Expects the subject stub to have been called, optionally with an expected number of calls
    --- @param n? number
    function expectations.called( n )
        assert( subject.IsStub, ".called expects a stub" )

        local callCount = subject.callCount

        if n == nil then
            if callCount == 0 then
                i.expected( "to have been called at least once " )
            end
        else
            if callCount < n then
                i.expected( "to have been called exactly %d times, got: %d", n, callCount )
            end
        end
    end

    function expectations.haveBeenCalled( n )
        GLuaTest.DeprecatedNotice( "to.haveBeenCalled( number )", "was.called( number )" )
        return expectations.called( n )
    end

    -- Soon..
    --
    -- function expectations.haveBeenCalledWith( ... )
    -- end

    return expectations
end
