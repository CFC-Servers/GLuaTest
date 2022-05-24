local istable = istable

local checkSendToClients = function( filePath, cases )
    for _, case in ipairs( cases ) do
        if case.clientside then
            print( "Found clientside test case, sending file to clients: ", filePath )
            return AddCSLuaFile( filePath )
        end
    end
end

local getProjectName = function( dir )
    return string.match( dir, "^tests/(.+)/.*$" )
end

local function getTestsInDir( dir, tests )
    if not tests then tests = {} end
    local files, dirs = file.Find( dir .. "/*.lua", "LUA" )

    for _, fileName in ipairs( files ) do
        local filePath = dir .. "/" .. fileName
        local fileOutput = include( filePath )

        if istable( fileOutput ) then
            if SERVER then checkSendToClients( filePath, fileOutput ) end

            table.insert( tests, {
                fileName = fileName,
                project = getProjectName( filePath ),
                cases = fileOutput
            } )
        end
    end

    for _, dirName in ipairs( dirs ) do
        getTestsInDir( tests, dir .. "/" .. dirName )
    end

    return tests
end

return getTestsInDir
