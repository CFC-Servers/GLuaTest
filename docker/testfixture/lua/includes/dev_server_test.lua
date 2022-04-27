local table_concat = table.concat
local table_insert = table.insert
local string_Split = string.Split

local failures = {}

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
    if not success then
        table_insert( failures, {
            reason = errInfo.reason,
            lineNumber = errInfo.lineNumber,
            sourceFile = cleanSource( errInfo.sourceFile )
        })
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
