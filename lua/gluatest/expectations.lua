local IsValid = IsValid
local string_format = string.format

local function reportFailure( suffix, subject, ... )
    local fmt = "Expectation Failed: Expected %s " .. suffix
    local message = string_format( fmt, subject, ... )

    error( message )
end

local function expect( subject )
    local function expected( suffix, ... )
        reportFailure( suffix, subject, ... )
    end

    return {
        to = {
            -- TODO: Make a comparison table generator that returns this structure
            --  Will allow us to alias beAn to beA, and will allow us to easily add the .not chain modifier
            eq = function( comparison )
                if subject ~= comparison then
                    expected( "to equal '%s'", comparison )
                end
            end,

            beTrue = function()
                if subject ~= true then
                    expected( "to be true" )
                end
            end,

            beFalse = function()
                if subject ~= false then
                    expected( "to be false" )
                end
            end,

            beValid = function()
                if not IsValid( subject ) then
                    expected( "to be valid" )
                end
            end,

            beNil = function()
                if subject ~= nil then
                    expected( "to be nil" )
                end
            end,

            beA = function( comparison )
                if subject.__class ~= comparison then
                    expected( "to be of type '%s'", comparison )
                end
            end,

            beAn = function( comparison )
                if subject.__class ~= comparison then
                    expected( "to be of type '%s'", comparison )
                end
            end
        }
    }
end

return expect
