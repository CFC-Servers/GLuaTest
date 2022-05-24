local type = type
local IsValid = IsValid
local string_format = string.format

local function reportFailure( suffix, subject, ... )
    local fmt = "Expectation Failed: Expected %s " .. suffix
    local message = string_format( fmt, subject, ... )

    error( message )
end

local function makeExpectations( subject )
    local expectations = {
        expected = function( suffix, ... )
            reportFailure( suffix, subject, ... )
        end
    }

    local expected = expectations.expected

    function expectations.eq( comparison )
        if subject ~= comparison then
            expected( "to equal '%s'", comparison )
        end
    end
    expectations.equal = expectations.eq

    function expectations.beLessThan( comparison )
        if subject >= comparison then
            expected( "to be less than '%s'", comparison )
        end
    end

    function expectations.beGreaterThan( comparison )
        if subject <= comparison then
            expected( "to be greater than '%s'", comparison )
        end
    end

    function expectations.beTrue()
        if subject ~= true then
            expected( "to be true" )
        end
    end

    function expectations.beFalse()
        if subject ~= false then
            expected( "to be false" )
        end
    end

    function expectations.beValid()
        if not IsValid( subject ) then
            expected( "to be valid" )
        end
    end

    function expectations.beNil()
        if subject ~= nil then
            expected( "to be nil" )
        end
    end

    function expectations.beA( comparison )
        local class = type( subject )

        if class ~= comparison then
            expected( "to be a '%s'", comparison )
        end
    end
    expectations.beAn = expectations.beA

    function expectations.succeed()
        local success, err = pcall( subject )

        if success == false then
            expected( "to succeed, got: %s", err )
        end
    end

    function expectations.err()
        local success = pcall( subject )

        if success == true then
            expected( "to error" )
        end
    end

    function expectations.errWith( comparison )
        local success, err = pcall( subject )

        if success == true then
            expected( "to error with '%s'", comparison )
        else
            err = string.Split( err, ": " )[2]

            if err ~= comparison then
                expected( "to error with '%s', got '%s'", comparison, err )
            end
        end
    end

    return expectations
end

local function expect( subject )
    local expectations = makeExpectations( subject )

    return { to = expectations }
end

return expect
