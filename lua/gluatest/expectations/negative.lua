local type = type
local IsValid = IsValid
local string_format = string.format

-- Inverse checks
return function( subject, ... )
    local args = { ... }

    local expectations = {
        expected = function( suffix, ... )
            local fmt = "Expectation Failed: Expected %s " .. suffix
            local message = string_format( fmt, subject, ... )

            error( message )
        end
    }

    local i = expectations

    function expectations.eq( comparison )
        if subject == comparison then
            i.expected( "to not equal '%s'", comparison )
        end
    end
    expectations.equal = expectations.eq

    function expectations.beLessThan( comparison )
        if subject < comparison then
            i.expected( "to not be less than '%s'", comparison )
        end
    end

    function expectations.beGreaterThan( comparison )
        if subject > comparison then
            i.expected( "to not be greater than '%s'", comparison )
        end
    end

    function expectations.beBetween( lower, upper )
        if subject >= lower and subject <= upper then
            i.expected( "to not be between '%s' and '%s'", lower, upper )
        end
    end

    function expectations.beTrue()
        if subject == true then
            i.expected( "to not be true" )
        end
    end

    function expectations.beFalse()
        if subject == false then
            i.expected( "to not be false" )
        end
    end

    function expectations.beValid()
        if IsValid( subject ) then
            i.expected( "to not be valid" )
        end
    end

    function expectations.beInvalid()
        if not IsValid( subject ) then
            i.expected( "to not be invalid" )
        end
    end

    function expectations.beNil()
        if subject == nil then
            i.expected( "to not be nil" )
        end
    end

    function expectations.exist()
        if subject ~= nil then
            i.expected( "to not exist" )
        end
    end

    function expectations.beA( comparison )
        local class = type( subject )

        if class == comparison then
            i.expected( "to not be a '%s'", comparison )
        end
    end

    function expectations.beAn( comparison )
        local class = type( subject )

        if class == comparison then
            i.expected( "to not be an '%s'", comparison )
        end
    end

    function expectations.succeed()
        local success = pcall( subject, unpack( args ) )

        if success ~= false then
            i.expected( "to not succeed" )
        end
    end

    function expectations.err()
        local success = pcall( subject, unpack( args ) )

        if success ~= true then
            i.expected( "to not error" )
        end
    end

    function expectations.errWith( comparison )
        local success, err = pcall( subject, unpack( args ) )

        if success == true then
            i.expected( "to error" )
        else
            if string.StartWith( err, "lua/" ) or string.StartWith( err, "addons/" ) then
                local _, endOfPath = string.find( err, ":%d+: ", 1 )
                assert( endOfPath, "Could not find end of path in error message: " .. err )

                err = string.sub( err, endOfPath + 1 )
            end

            if err == comparison then
                i.expected( "to not error with '%s'", comparison )
            end
        end
    end

    -- An important distinction between this and the Positive version:
    -- the Positive expectation lets you specify how many times it
    -- should have been called, but this one does not
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
