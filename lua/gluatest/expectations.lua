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
        if subject.__class ~= comparison then
            expected( "to be of type '%s'", comparison )
        end
    end
    expectations.beAn = expectations.beA

    return expectations
end

local function expect( subject )
    return { to = makeExpectations( subject ) }
end

return expect
