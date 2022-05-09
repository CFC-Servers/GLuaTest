local mockPlayers = {}
local playerMeta = FindMetaTable( "Player" )

local playerOverrides = {
    "SteamID",
    "SteamID64",
    "Nick",

}

playerMeta._Nick = playerMeta._Nick or playerMeta.Nick
playerMeta.Nick = function( self )
    local subject = mockPlayer[self] or self
    return subject.Nick( subject )
end


local usedSteamIDs = {}

local function generateSteamID()
    local Y = random( 0, 1 )
    local accountID = random( 100, 9999999999 )

    local steamID = string.format( "STEAM_0:%d:%d", Y, accountID )
    if usedSteamIDs[steamID] then return generateSteamID() end
    usedSteamIDs[steamID] = true

    return steamID
end

-- Generates a function that returns the given values
local f = function( ... )
    local args = { ... }
    return function()
        return unpack( args )
    end
end

local function mockPlayer( properties )
    local steamID = properties.steamID or generateSteamID()
    local steamID64 = util.SteamIDTo64( steamID )

    return {
        Nick = f( properties.name or nil ),
        SteamID = f( steamID ),
        SteamID64 = f( steamID64 ),
    }

end

return mockPlayer
