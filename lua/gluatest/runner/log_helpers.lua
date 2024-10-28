local string_Explode = string.Explode
local table_concat = table.concat

--- @class GLuaTest_LogHelpers
local LogHelpers = {}

--- Given a line of code, returns the leading whitespace
--- @param line string
--- @return string
function LogHelpers.GetLeadingWhitespace( line )
    return string.match( line, "^%s+" ) or ""
end

--- Given an absolute path, returns the path required to read the file in Lua
--- @param path string
--- @return string
function LogHelpers.cleanPathForRead( path )
    -- { "addons", "addon_name", "lua", "tests", "addon_name", "test.lua" }
    -- { "gamemodes", "darkrp", "gamemode", "tests", "darkrp", "main.lua" }
    local expl = string_Explode( "/", path )

    local startCopy
    for i = 1, #expl do
        local step = expl[i]

        if step == "lua" or step == "gamemodes" then
            startCopy = i + 1
            assert( startCopy < #expl )
            break
        end
    end

    return table_concat( expl, "/", startCopy, #expl )
end

--- filePath -> fileLines
--- @type table<string, string[]>
LogHelpers.fileCache = {}

--- Reads a given file path and returns the contents split by newline
--- Cached for future calls
--- @param filePath string
--- @return string[]
function LogHelpers.getFileLines( filePath )
    --
    -- Reads a given file path and returns the contents split by newline.
    -- Caches the output for future calls.
    --
    local cached = LogHelpers.fileCache[filePath]
    if cached then return cached end

    local cleanPath = LogHelpers.cleanPathForRead( filePath )
    local testFile = file.Open( cleanPath, "r", "LUA" ) --[[@as File]]
    local fileContents = testFile:Read( testFile:Size() )
    testFile:Close()

    local fileLines = string.Split( fileContents, "\n" )
    LogHelpers.fileCache[filePath] = fileLines

    return fileLines
end
hook.Add( "GLuaTest_Finished", "GLuaTest_FileCacheCleanup", function()
    LogHelpers.fileCache = {}
end )

--- Given a table of code lines, return a string
--- containing the leading spacing can be removed
--- without losing any context
--- @param lines string[]
--- @return number The number of characters that are safe to remove
function LogHelpers.getLeastSharedIndent( lines )
    local leastShared = math.huge

    for _, lineContent in ipairs( lines ) do
        if #lineContent > 0 then
            local leading = LogHelpers.GetLeadingWhitespace( lineContent )

            if #leading < leastShared then
                leastShared = #leading
            end
        end
    end

    return leastShared or 0
end

--- Given lines of code, dedent them by the least shared indent
--- (i.e. dedent the code as much as possible without losing meaningful indentation)
--- @param lines string[] The lines of code to dedent
--- @return string[] The dedented lines
function LogHelpers.NormalizeLinesIndent( lines )
    local leastSharedIndent = LogHelpers.getLeastSharedIndent( lines )
    if leastSharedIndent == 0 then return lines end

    for i = 1, #lines do
        local lineContent = lines[i]
        lines[i] = string.Right( lineContent, #lineContent - leastSharedIndent )
    end

    return lines
end

--- Return the desired line of code with a configurable amount of context above/below
--- @param path string The path to the file
--- @param line number The line number to get
--- @param context? number The number of lines above and below to include (Default: 5)
--- @return string[] The lines of code with context
function LogHelpers.GetLineWithContext( path, line, context )
    if not context then context = 5 end
    local fileLines = LogHelpers.getFileLines( path )

    local lineWithContext = {}
    for i = line - context, line do
        local lineContent = fileLines[i]
        table.insert( lineWithContext, lineContent )
    end

    return lineWithContext
end

--- Generates an appropriately-sized divider line
--- based on the longest line and the length of the failure reason
--- @param lines string[] The lines of code
--- @param reason string The reason for the failure
--- @return string The divider line
function LogHelpers.GenerateDivider( lines, reason )
    local longestLine = 0

    for i = 1, #lines do
        local line = lines[i]
        local lineLength = #line
        if lineLength > longestLine then
            longestLine = lineLength
        end
    end

    local dividerLength = math.min( longestLine + #reason, 110 )
    return string.rep( "_", dividerLength )
end

hook.Run( "GLuaTest_MakeLogHelpers", LogHelpers )
return LogHelpers
