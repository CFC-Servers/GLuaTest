local table_concat = table.concat
local table_insert = table.insert
local table_Copy = table.Copy
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
        local errCopy = table_Copy( errInfo )
        errCopy.locals = nil
        errCopy.sourceFile = cleanSource( errCopy.sourceFile )
        table_insert( failures, errInfo )
    end
end )

hook.Add( "GLuaTest_RanTestFiles", "TestComplete", function()
    if #failures > 0 then
        file.Write( "gluatest_failures.json", util.TableToJSON( failures ) )
    end

    print("Got GLuaTest TestComplete callback, exiting")
    file.Write( "gluatest_clean_exit.txt", "true" )
    timer.Simple( 1, engine.CloseServer )
end )
