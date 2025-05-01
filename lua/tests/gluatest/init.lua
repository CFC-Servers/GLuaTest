--- @type GLuaTest_TestGroup
return {
    groupName = "Initialization",

    cases = {
        {
            name = "Table exists",
            func = function()
                expect( _G.GLuaTest ).to.exist()
            end
        },

        {
            name = "gluatest_run_tests concommand exists",
            func = function()
                local commands = concommand.GetTable()
                expect( commands["gluatest_run_tests"] ).to.beA( "function" )
            end
        },

        {
            name = "Convars exist",
            func = function()
                expect( ConVarExists( "gluatest_server_enable" ) ).to.beTrue()
                expect( ConVarExists( "gluatest_client_enable" ) ).to.beTrue()
                expect( ConVarExists( "gluatest_selftest_enable" ) ).to.beTrue()
            end
        },

        {
            name = "Convars have correct defaults",
            func = function()
                local gluatest_server_enable = GetConVar( "gluatest_server_enable" )
                expect( gluatest_server_enable:GetDefault() ).to.equal( "1" )

                local gluatest_client_enable = GetConVar( "gluatest_client_enable" )
                expect( gluatest_client_enable:GetDefault() ).to.equal( "0" )

                local gluatest_selftest_enable = GetConVar( "gluatest_selftest_enable" )
                expect( gluatest_selftest_enable:GetDefault() ).to.equal( "0" )
            end
        },
    }
}
