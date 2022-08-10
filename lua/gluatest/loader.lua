local istable = istable
local runClientside = GLuaTest.RUN_CLIENTSIDE
local noop = function() end

local checkSendToClients = function( filePath, cases )
    if not runClientside then return end

    for _, case in ipairs( cases ) do
        if case.clientside then
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

        if istable( fileOutput ) and fileOutput.cases then
            if SERVER then checkSendToClients( filePath, fileOutput.cases ) end

            table.insert( tests, {
                fileName = fileName,
                groupName = fileOutput.groupName,
                cases = fileOutput.cases,
                project = getProjectName( filePath ),
                beforeAll = fileOutput.beforeAll or noop,
                beforeEach = fileOutput.beforeEach or noop,
                afterAll = fileOutput.afterAll or noop,
                afterEach = fileOutput.afterEach or noop
            } )
        end
    end

    for _, dirName in ipairs( dirs ) do
        getTestsInDir( dir .. "/" .. dirName, tests )
    end

    return tests
end

return getTestsInDir
