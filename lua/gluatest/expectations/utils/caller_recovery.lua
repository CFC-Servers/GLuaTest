-- As the name implies, finds the last occurrence of the given needle
local function findLast( haystack, needle )
    local lastPos = string.find( haystack, needle, nil, true )
    local nextPos = lastPos and string.find( haystack, needle, lastPos + 1, true )
    while nextPos ~= nil do
        lastPos = nextPos
        nextPos = string.find( haystack, needle, lastPos + 1, true )
    end

    return lastPos
end

-- Removes ( and ) without breaking stuff hopefully
-- This means you can do crazy stuff like expect( test123(test456(test789(123))) ) which will be stripped to just test123
local function removeBraces( line )
    local findStartPos = findLast( line, "(" )
    while findStartPos do
        local findEndPos = string.find( line, ")", findStartPos + 1 )
        if not findEndPos then break end

        line = string.Trim( line:sub( 0, findStartPos - 1 ) .. line:sub( findEndPos + 1 ) )

        findStartPos = findLast( line, "(" )
    end

    return line
end


--[[
    Name recovery function for expect( test.123 )
    to retrieve 123 so that functions like errWith will work properly if given directly the function that will error

    This is mainly required due to Lua losing track of the caller function resulting in '?' inside an error message
    you could always wrap it like this to workaround this issue: local testFunc = function(...) test.123(...) end
    Using which this entire stuff would not be necessary, as then the function you pass to pcall will not be the one erroring.
    and since you call your function inside of it, Lua still knows the name of it, causing errWith to work properly.
]]
local function GetExpectationSubjectName( additionalShift )
    additionalShift = additionalShift or 0
    -- We gotta figure out the caller name as its lost when we get called as it isn't kept track off
    local ourDebugInfo = debug.getinfo( 2 + additionalShift, "n" ) -- Makes copy-pasting this easier (also allows us to move this somewhere else later)
    local callerDebugInfo = debug.getinfo( 3 + additionalShift, "Sln" ) -- 3 = caller, 2 = expect.errWith or such, 1 = us
    if callerDebugInfo and ourDebugInfo and ourDebugInfo.name ~= "" and callerDebugInfo.currentline ~= 1 then
        -- ToDo: Cache the file content to reduce filesystem usage (Could quickly escalate, slowing everything down immensely)
        local fileHandle = file.Open( callerDebugInfo.short_src, "rb", "GAME" ) --[[@as File]]
        if fileHandle then
            -- Skipping to our current line
            for _ = 1, callerDebugInfo.currentline - 1 do
                fileHandle:ReadLine()
            end
            local line = string.Trim( fileHandle:ReadLine() )
            fileHandle:Close() -- No longer need our handle

            -- Remove expected
            local _, findPos = string.find( line, "expect" )
            if findPos then
                line = string.Trim( line:sub( findPos + 1 ) )
            end

            -- Remove everything after "errWith" including itself
            findPos = string.find( line, ourDebugInfo.name )
            if findPos then
                line = string.Trim( line:sub( 0, findPos - 1 ) )
            end

            -- First remove the left over . from ".errWith" as we only removed errWith
            findPos = findLast( line, "." )
            if findPos then
                line = string.Trim( line:sub( 0, findPos - 1 ) )
            end

            -- Now remove the ".to"
            findPos = findLast( line, "." )
            if findPos then
                line = string.Trim( line:sub( 0, findPos - 1 ) )
            end

            -- Remove leftover "(" wrapping
            if line:StartsWith( "(" ) then
                line = string.Trim( line:sub( 2 ) )
            end

            -- Remove leftover ")" wrapping
            if line:EndsWith( ")" ) then
                line = string.Trim( line:sub( 0, line:len() - 1 ) )
            end

            line = removeBraces( line )

            -- Now, finally remove the the rest in case it had arguments like expect( test123, 123 )
            findPos = string.find( line, "," )
            if findPos then
                line = string.Trim( line:sub( 0, findPos - 1 ) )
            end

            findPos = findLast( line, "." )
            if findPos then
                line = string.Trim( line:sub( findPos + 1 ) )
            end

            findPos = findLast( line, ":" )
            if findPos then
                line = string.Trim( line:sub( findPos + 1 ) )
            end

            return line
        end
    end

    return "?"
end

local function DoPCallWithSubject( subject, ... )
    local callerName = GetExpectationSubjectName( 1 ) -- 1 since this function also shifts things again

    __GLUA_RUN = {} -- To not conflict and to avoid setting up an entire fenv
    local callSubject = callerName ~= "?" and CompileString( [[__GLUA_RUN.]] .. callerName .. [[( ... )]], "", false ) or subject
    -- Instead of doing __GLUA_RUN_callerName, we do __GLUA_RUN.callerName
    -- so that the name won't be modified in the resulting error messsage as it ignores the table name
    __GLUA_RUN[callerName] = subject

    local success, err = pcall( callSubject, ... )
    __GLUA_RUN = nil -- Cleanup :^

    -- This can exist because of the use of CompileString, so nuke it
    if err and err:StartsWith( ":1: " ) then
        err = err:sub( 5 )
    end

    return success, err
end

return DoPCallWithSubject