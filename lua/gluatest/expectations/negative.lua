local type = type
local TypeID = TypeID
local IsValid = IsValid
local isstring = isstring
local string_format = string.format
local GetDiff = include( "utils/table_diff.lua" )

-- Inverse checks
return function( subject, ... )
    -- Args that are passed after the subject, i.e. expect( subject, arg1, arg2 )
    local args = { ... }

    -- Wrap the subject in quotes if if's a string
    local fmtPrefix = "Expectation Failed: Expected %s "
    if isstring( subject ) then
        fmtPrefix = string.Replace( fmtPrefix, "%s", "'%s'" )
    end

    --- @class GLuaTest_NegativeExpectations
    local expectations = {
        expected = function( suffix, ... )
            local fmt = fmtPrefix .. suffix
            local message = string_format( fmt, subject, ... )

            error( message )
        end
    }


    local i = expectations

    --- Expects the subject is not equal to the comparison
    --- @param comparison any
    function expectations.equal( comparison )
        if subject == comparison then
            i.expected( "to not equal '%s'", comparison )
        end
    end

    --- @deprecated
    --- @param comparison any
    function expectations.eq( comparison )
        GLuaTest.DeprecatedNotice( "toNot.eq( value )", "toNot.equal( value )" )
        return expectations.equal( comparison )
    end

    --- Expects the subject table is not deeply equal to the comparison
    --- @param comparison table
    function expectations.deepEqual( comparison )
        assert( TypeID( subject ) == TYPE_TABLE, ".deepEqual expects a table" )
        assert( TypeID( comparison ) == TYPE_TABLE, ".deepEqual expects a table" )

        local diff = GetDiff( subject, comparison )

        if not diff then
            i.expected( "to not deeply equal '%s' - found identical contents", comparison )
        end
    end

    --- Expects the subject is not approximately equal to the comparison, with a tolerance
    --- @param comparison number
    --- @param tolerance? number Tolerance for the comparison
    function expectations.aboutEqual( comparison, tolerance )
        assert( TypeID( subject ) == TYPE_NUMBER, ".aboutEqual expects a number" )
        assert( TypeID( comparison ) == TYPE_NUMBER, ".aboutEqual expects a number" )

        tolerance = tolerance or 0.00001
        local difference = math.abs( subject - comparison )

        if difference <= tolerance then
            i.expected( "to not be within '%s' of '%s' - found a difference of '%s'", tolerance, comparison, difference )
        end
    end

    --- Expects the subject is not less than the comparison
    --- @param comparison any
    function expectations.beLessThan( comparison )
        if subject < comparison then
            i.expected( "to not be less than '%s'", comparison )
        end
    end

    --- Expects the subject is not greater than the comparison
    --- @param comparison any
    function expectations.beGreaterThan( comparison )
        if subject > comparison then
            i.expected( "to not be greater than '%s'", comparison )
        end
    end

    --- Expects the subject is not between the lower and upper bounds
    --- @param lower any
    --- @param upper any
    function expectations.beBetween( lower, upper )
        if subject >= lower and subject <= upper then
            i.expected( "to not be between '%s' and '%s'", lower, upper )
        end
    end

    --- Expects the subject is not exactly equal to true
    function expectations.beTrue()
        if subject == true then
            i.expected( "to not be true" )
        end
    end

    --- Expects the subject is not exactly equal to false
    function expectations.beFalse()
        if subject == false then
            i.expected( "to not be false" )
        end
    end

    --- Expects the subject to not pass an IsValid check
    function expectations.beValid()
        if IsValid( subject ) then
            i.expected( "to not be valid" )
        end
    end

    --- Expects the subject to not fail an IsValid check
    function expectations.beInvalid()
        if not IsValid( subject ) then
            i.expected( "to not be invalid" )
        end
    end

    --- Expects the subject to not be nil
    function expectations.beNil()
        if subject == nil then
            i.expected( "to not be nil" )
        end
    end

    --- Expects the subject to not be NaN
    --- (Meaning it's just a number)
    function expectations.beNaN()
        assert( TypeID( subject ) == TYPE_NUMBER, ".beNaN expects a number" )

        if subject ~= subject then
            i.expected( "to not be NaN" )
        end
    end

    --- Expects the subject to be nil
    function expectations.exist()
        if subject ~= nil then
            i.expected( "to not exist" )
        end
    end

    --- Expects the subject to not be of the given type
    --- @param comparison string
    function expectations.beA( comparison )
        local class = type( subject )

        if class == comparison then
            i.expected( "to not be a '%s'", comparison )
        end
    end

    --- Expect the subject to not be of the given type
    function expectations.beAn( comparison )
        local class = type( subject )

        if class == comparison then
            i.expected( "to not be an '%s'", comparison )
        end
    end

    --- Expects the subject function to not run succesfully
    function expectations.succeed()
        assert( TypeID( subject ) == TYPE_FUNCTION, ".succeed expects a function" )

        local success = pcall( subject, unpack( args ) )

        if success ~= false then
            i.expected( "to not succeed" )
        end
    end

    --- Expects the subject function to not fail when run
    function expectations.err()
        assert( TypeID( subject ) == TYPE_FUNCTION, ".err expects a function" )

        local success = pcall( subject, unpack( args ) )

        if success ~= true then
            i.expected( "to not error" )
        end
    end

    --- Expects the subject function to fail when run, and not produce the given error
    --- @param comparison string
    function expectations.errWith( comparison )
        assert( TypeID( subject ) == TYPE_FUNCTION, ".errWith expects a function" )
        assert( isstring( comparison ), "errWith expects a string" )

        local success, err = pcall( subject, unpack( args ) )

        if success == true then
            i.expected( "to error" )
        else
            if string.StartsWith( err, "lua/" ) or string.StartsWith( err, "addons/" ) then
                local _, endOfPath = string.find( err, ":%d+: ", 1 )
                assert( endOfPath, "Could not find end of path in error message: " .. err )

                err = string.sub( err, endOfPath + 1 )
            end

            if err == comparison then
                i.expected( "to not error with '%s'", comparison )
            end
        end
    end

    --- Expects the subject stub to not have been called
    --- An important distinction between this and the Positive version:
    --- the Positive expectation lets you specify how many times it
    --- should have been called, but this one does not
    function expectations.called()
        local callCount = subject.callCount
        if callCount > 0 then
            i.expected( "to not have been called, got: %d", callCount )
        end
    end

    function expectations.haveBeenCalled()
        GLuaTest.DeprecatedNotice( "to.haveBeenCalled()", "was.called()" )
        return expectations.called()
    end

    return expectations
end
