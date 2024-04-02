local type = type
local IsValid = IsValid
local string_format = string.format

-- Positive checks
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
        if subject ~= comparison then
            i.expected( "to equal '%s'", comparison )
        end
    end
    expectations.equal = expectations.eq

    function expectations.beLessThan( comparison )

        if subject >= comparison then
            i.expected( "to be less than '%s'", comparison )
        end
    end

    function expectations.beGreaterThan( comparison )

        if subject <= comparison then
            i.expected( "to be greater than '%s'", comparison )
        end
    end

    function expectations.beBetween( lower, upper )
        if subject < lower or subject > upper then
            i.expected( "to be between '%s' and '%s'", lower, upper )
        end
    end

    function expectations.beTrue()
        if subject ~= true then
            i.expected( "to be true" )
        end
    end

    function expectations.beFalse()
        if subject ~= false then
            i.expected( "to be false" )
        end
    end

    function expectations.beValid()
        if not IsValid( subject ) then
            i.expected( "to be valid" )
        end
    end

    function expectations.beInvalid()
        if IsValid( subject ) then
            i.expected( "to be invalid" )
        end
    end

    function expectations.beNil()
        if subject ~= nil then
            i.expected( "to be nil" )
        end
    end

    function expectations.exist()
        if subject == nil then
            i.expected( "to exist, got nil" )
        end
    end

    function expectations.beA( comparison )
        local class = type( subject )

        if class ~= comparison then
            i.expected( "to be a '%s'", comparison )
        end
    end
    expectations.beAn = expectations.beA

    function expectations.succeed()
        local success, err = pcall( subject, unpack( args ) )

        if success == false then
            i.expected( "to succeed, got: %s", err )
        end
    end

    function expectations.err()
        local success = pcall( subject, unpack( args ) )

        if success == true then
            i.expected( "to error" )
        end
    end

    function expectations.errWith( comparison )
        local success, err = pcall( subject, unpack( args ) )

        if success == true then
            i.expected( "to error with '%s'", comparison )
        else
            if string.StartWith( err, "lua/" ) or string.StartWith( err, "addons/" ) then
                local _, endOfPath = string.find( err, ":%d+: ", 1 )
                assert( endOfPath, "Could not find end of path in error message: " .. err )

                err = string.sub( err, endOfPath + 1 )
            end

            if err ~= comparison then
                i.expected( "to error with '%s', got '%s'", comparison, err )
            end
        end
    end

    function expectations.called( n )
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
