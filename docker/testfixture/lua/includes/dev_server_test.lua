local table_concat = table.concat
local table_insert = table.insert
local string_Split = string.Split
local string_format = string.format

local failures = {}
local ghOutput = CreateConVar( "gluatest_github_output", "1", FCVAR_UNREGISTERED, "", 0, 1 )

local function cleanSource( fileName )
    local spl = string_Split( fileName, "/" )
    for i, step in ipairs( spl ) do
        if step == "lua" then
            return table_concat( spl, "/", i, #spl )
        end
    end

    return spl
end

hook.Add( "GLuaTest_LoggedTestResult", "TestLog", function( success, _, _, errInfo )
    if success then return end
    local failInfo = {
        reason = errInfo.reason,
        lineNumber = errInfo.lineNumber,
        sourceFile = cleanSource( errInfo.sourceFile )
    }
    table_insert( failures, failInfo )

    if ghOutput:GetBool() then
        local fi = failInfo
        local str = "::error file=%s,line=%s::%s"
        print( string_format( str, fi.sourceFile, fi.lineNumber, fi.reason ) )
    end
end )

hook.Add( "GLuaTest_RanTestFiles", "TestComplete", function()
    if #failures > 0 then
        print( tostring( #failures ) .. " test failures detected, writing to log.." )
        PrintTable( failures )
        local failureJSON = util.TableToJSON( failures )
        print( failureJSON )
        file.Write( "gluatest_failures.json", failureJSON )
    end

    print( "Got GLuaTest TestComplete callback, exiting" )
    file.Write( "gluatest_clean_exit.txt", "true" )
    engine.CloseServer()
end )
