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

-- TODO: How to prevent this from matching: `customtests/blah/blah.lua`?
local getProjectName = function( dir )
    return string.match( dir, "tests/(.+)/.*$" )
end

local function processFile( dir, fileName, tests )
    if not string.EndsWith( fileName, ".lua" ) then return end

    local filePath = dir .. "/" .. fileName
    local fileOutput = include( filePath )

    if not istable( fileOutput ) then return end
    if not fileOutput.cases then return end

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

local function getTestsInDir( dir, tests )
    if not tests then tests = {} end
    local files, dirs = file.Find( dir .. "/*", "LUA" )

    for _, fileName in ipairs( files ) do
        processFile( dir, fileName, tests )
    end

    for _, dirName in ipairs( dirs ) do
        local newDir = dir .. "/" .. dirName
        getTestsInDir( newDir, tests )
    end

    return tests
end

return getTestsInDir
