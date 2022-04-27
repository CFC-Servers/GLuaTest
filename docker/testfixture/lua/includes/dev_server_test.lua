local table_concat = table.concat
local table_insert = table.insert
local string_Split = string.Split
local string_format = string.format

local failures = {}
local ghOutput = CreateConVar( "gluatest_github_output", true, FCVAR_ARCHIVE, "", 0, 1 )

local function cleanSource( fileName )
    local spl = string_Split( fileName, "/" )
    for i, step in ipairs( spl ) do
        if step == "lua" then
            return table_concat( spl, "/", i, #spl )
        end
    end

    return spl
end

hook.Add( "GLuaTest_RanTestCase", "TestLog", function( _, _, success, errInfo )
    if success then return end
    local failInfo = {
        reason = errInfo.reason,
        lineNumber = errInfo.lineNumber,
        sourceFile = cleanSource( errInfo.sourceFile )
    }
    table_insert( failures, failInfo )

    -- TODO: Clean this up
    print( ghOutput:GetBool() )
    if ghOutput:GetBool() or true then
        local fi = failInfo
        local str = "::error file=%s,line=%s::%s"
        print( string_format( str, fi.sourceFile, fi.lineNumber, fi.reason ) )
    end
end )

hook.Add( "GLuaTest_RanTestFiles", "TestComplete", function()
    if #failures > 0 then
        print( tostring( #failures ) .. "test failures detected, writing to log.." )
        file.Write( "gluatest_failures.json", util.TableToJSON( failures ) )
    end

    print( "Got GLuaTest TestComplete callback, exiting" )
    file.Write( "gluatest_clean_exit.txt", "true" )
    timer.Simple( 1, engine.CloseServer )
end )
