--- @class GLuaTest_Loader
local Loader = {}

--- If the file has clientside cases, send it to the client
--- @param filePath string
--- @param cases GLuaTest_TestCase[]
function Loader.checkSendToClients( filePath, cases )
    if not GLuaTest.RUN_CLIENTSIDE then return end

    for _, case in ipairs( cases ) do
        if case.clientside then
            return AddCSLuaFile( filePath )
        end
    end
end

--- Given a full path to a test file or directory, return the project name (the folder under tests/ it exists within)
--- @param dir string The full path to the test file or directory
--- @return string
function Loader.getProjectName( dir )
    return string.match( dir, "tests/(.*)/.*$" )
end

--- Given a directory and a file name, try to load the file as a TestGroup and build a RunnableTestGroup from it
--- @param dir string The directory the file is in
--- @param fileName string The name of the file
--- @param groups GLuaTest_RunnableTestGroup[]
function Loader.processFile( dir, fileName, groups )
    if not string.EndsWith( fileName, ".lua" ) then return end

    local filePath = dir .. "/" .. fileName
    local fileOutput = include( filePath )

    if not istable( fileOutput ) then
        print( "GLuaTest: File " .. fullPath .. " did not return a table - ignoring" )
        return
    end
    if not fileOutput.cases then
        print( "GLuaTest: File " .. fullPath .. " did not have a 'cases' field - ignoring" )
        return
    end

    local testGroup = fileOutput --[[@as GLuaTest_TestGroup]]

    if SERVER then Loader.checkSendToClients( filePath, testGroup.cases ) end

    local group = testGroup
    group.fileName = fileName
    group.project = Loader.getProjectName( filePath )

    table.insert( groups, group --[[@as GLuaTest_RunnableTestGroup]] )
end


--- Given a directory, recursively search for test files and load them into the given tests table
--- @param dir string The directory to search in
--- @param tests? GLuaTest_RunnableTestGroup[]
function Loader.getTestsInDir( dir, tests )
    if not tests then tests = {} end
    local files, dirs = file.Find( dir .. "/*", "LUA" )

    for _, fileName in ipairs( files ) do
        Loader.processFile( dir, fileName, tests )
    end

    for _, dirName in ipairs( dirs ) do
        local newDir = dir .. "/" .. dirName
        Loader.getTestsInDir( newDir, tests )
    end

    return tests
end

return Loader
