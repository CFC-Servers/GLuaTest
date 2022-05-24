local string_Explode = string.Explode
local table_concat = table.concat

local LogHelpers = {}

function LogHelpers.GetLeadingWhitespace( line )
    return string.match( line, "^%s+" ) or ""
end

local function cleanPathForRead( path )
    --
    -- Given an absolute path, returns the path required to read
    -- the file in Lua
    --

    -- { "addons", "addon_name", "lua", "tests", "addon_name", "test.lua" }
    local expl = string_Explode( "/", path )

    local startCopy
    for i = 1, #expl do
        local step = expl[i]

        if step == "tests" then
            startCopy = i
            break
        end
    end

    return table_concat( expl, "/", startCopy, #expl )
end

local fileCache = {}
local function getFileLines( filePath )
    --
    -- Reads a given file path and returns the contents split by newline.
    -- Caches the output for future calls.
    --
    local cached = fileCache[filePath]
    if cached then return cached end

    local cleanPath = cleanPathForRead( filePath )
    local testFile = file.Open( cleanPath, "r", "LUA" )
    local fileContents = testFile:Read( testFile:Size() )
    testFile:Close()

    local fileLines = string.Split( fileContents, "\n" )
    fileCache[filePath] = fileLines

    return fileLines
end

local function getLeastSharedIndent( lines )
    --
    -- Given a table of code lines, return a string
    -- containing the leading spacing can be removed
    -- without losing any context
    --

    local leastShared = nil

    for _, lineContent in ipairs( lines ) do
        if #lineContent > 0 then
            local leading = LogHelpers.GetLeadingWhitespace( lineContent )

            if not leastShared or ( #leading < #leastShared ) then
                leastShared = leading
            end
        end
    end

    return leastShared or ""
end

function LogHelpers.NormalizeLinesIndent( lines )
    local leastSharedIndent = getLeastSharedIndent( lines )
    if leastSharedIndent == "" then return lines end

    for i = 1, #lines do
        local lineContent = lines[i]
        lines[i] = string.Replace( lineContent, leastSharedIndent, "" )
    end

    return lines
end


function LogHelpers.GetLineWithContext( path, line, context )
    if not context then context = 5 end
    local fileLines = getFileLines( path )

    local lineWithContext = {}
    for i = line - context, line do
        local lineContent = fileLines[i]
        table.insert( lineWithContext, lineContent )
    end

    return lineWithContext
end


function LogHelpers.GenerateDivider( lines, reason )
    --
    -- Generates an appropriately-sized divider line
    -- based on the longest line and the length of the failure reason
    --
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


return LogHelpers
