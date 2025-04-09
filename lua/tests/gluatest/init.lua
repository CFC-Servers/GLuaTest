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
                expect( ConVarExists( "gluatest_enable" ) ).to.beTrue()
            end
        }
    }
}
