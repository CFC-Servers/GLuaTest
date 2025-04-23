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

--- Returns a simple error table for when a file fails to load
--- @param reason string
--- @param filePath string
--- @return table
function Loader.simpleError( reason, filePath )
    return {
        reason = string.sub( reason, string.find( reason, ":" ) + 1 ),
        sourceFile = filePath,
        lineNumber = -1,
        locals = {}
    }
end

--- Given a directory and a file name, try to load the file as a TestGroup and build a RunnableTestGroup from it
--- @param dir string The directory the file is in
--- @param fileName string The name of the file
--- @param groups GLuaTest_RunnableTestGroup[]
function Loader.processFile( dir, fileName, groups )
    if not string.EndsWith( fileName, ".lua" ) then return end

    local filePath = dir .. "/" .. fileName
    local success, result = pcall( function( givenFilePath )
        local fileContent = file.Read( givenFilePath, "LUA" )
        local compiled = CompileString( fileContent, "lua/" .. givenFilePath, false )

        if not isfunction( compiled ) then
            return Loader.simpleError( compiled --[[@as string]], givenFilePath )
        end

        return compiled()
    end, filePath )

    success = success and istable( result ) and not result.sourceFile

    local fileOutput
    if success then
        fileOutput = result
    else
        fileOutput = {
            includeError = istable( result ) and result or Loader.simpleError( result --[[@as string]], filePath ),
            groupName = fileName,
            cases = {}
        }
    end

    if not fileOutput.cases then
        print( "GLuaTest: File " .. filePath .. " did not have a 'cases' field - ignoring" )
        return
    end

    local testGroup = fileOutput --[[@as GLuaTest_TestGroup]]

    if SERVER and success then Loader.checkSendToClients( filePath, testGroup.cases ) end

    --- @type GLuaTest_RunnableTestGroup
    local group = {
        cases = testGroup.cases,
        groupName = testGroup.groupName,
        beforeAll = testGroup.beforeAll,
        beforeEach = testGroup.beforeEach,
        afterAll = testGroup.afterAll,
        afterEach = testGroup.afterEach,

        fileName = fileName,
        project = Loader.getProjectName( filePath )
    }

    hook.Run( "GLuaTest_TestGroupLoaded", group, testGroup )

    table.insert( groups, group )
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

--- Loads all lua files in the given directory
--- @param dir string
function Loader.loadExtensions( dir )
    local files = file.Find( dir .. "/*.lua", "LUA" )

    for _, fileName in ipairs( files ) do
        local filePath = dir .. "/" .. fileName
        print( "[GLuaTest] Loading extension: " .. filePath )
        include( filePath )
    end
end

return Loader
