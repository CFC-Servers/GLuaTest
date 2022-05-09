local type = type
local isbool = isbool
local IsValid = IsValid
local string_format = string.format

local function reportFailure( suffix, subject, ... )
    local fmt = "Expectation Failed: Expected %s " .. suffix
    local message = string_format( fmt, subject, ... )

    error( message )
end

local function makeExpectations( subject )
    local expectations = {}

    local function expected( suffix, ... )
        reportFailure( suffix, subject, ... )
    end

    function expectations.eq( comparison )
        if subject ~= comparison then
            expected( "to equal '%s'", comparison )
        end
    end

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
end

local function expect( subject )
    local expectations = makeExpectations( subject )

    if isbool( subject ) then
        return expectations.beTrue()
    end

    return { to = expectations }
end

return expect
