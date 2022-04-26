local failures = {}

hook.Add( "GLuaTest_RanTestCase", "TestLog", function( _, _, success, errInfo )
    if not success then table.insert( failures, errInfo ) end
end )

hook.Add( "GLuaTest_RanTestFiles", "TestComplete", function()
    if #failures > 0 then
        file.Write( "gluatest_failures.json", util.TableToJSON( failures ) )
    end

    print("Got GLuaTest finsihed callback, exiting")
    engine.CloseServer()
end )
