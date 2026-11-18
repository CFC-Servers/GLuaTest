local VersionTools = include( "gluatest/utils/version.lua" )

return {
    groupName = "Usage ping",

    beforeEach = function( state )
        state.previousHttpHello = GLuaTest.HttpHelloConVar:GetBool()
        state.previousProjectName = GLuaTest.HttpHelloProjectConVar:GetString()
        state.previousRunner = GLuaTest.HttpHelloRunnerConVar:GetString()
        state.httpStub = stub( _G, "HTTP" )

        state.groups = {
            { cases = { {}, {} } },
            { cases = { {} } },
        }
    end,

    afterEach = function( state )
        GLuaTest.HttpHelloConVar:SetBool( state.previousHttpHello )
        GLuaTest.HttpHelloProjectConVar:SetString( state.previousProjectName )
        GLuaTest.HttpHelloRunnerConVar:SetString( state.previousRunner )
    end,

    cases = {
        {
            name = "Sends the version, branch, and test counts as strings",
            func = function( state )
                GLuaTest.HttpHelloConVar:SetBool( true )
                GLuaTest.HttpHelloProjectConVar:SetString( "" )
                GLuaTest.HttpHelloRunnerConVar:SetString( "" )

                GLuaTest.sendUsagePing( state.groups )

                expect( state.httpStub ).was.called()

                local request = state.httpStub.callHistory[1][1]
                expect( request.url ).to.equal( "https://hello.gluatest.com/ping" )
                expect( request.parameters ).to.deepEqual( {
                    version = VersionTools.getAnonymousVersion(),
                    branch = BRANCH or "unknown",
                    groups = "2",
                    cases = "3",
                } )
            end
        },

        {
            name = "Includes the project name when one is set",
            func = function( state )
                GLuaTest.HttpHelloConVar:SetBool( true )
                GLuaTest.HttpHelloProjectConVar:SetString( "my_addon" )

                GLuaTest.sendUsagePing( state.groups )

                local request = state.httpStub.callHistory[1][1]
                expect( request.parameters.project ).to.equal( "my_addon" )
            end
        },

        {
            name = "Includes the runner when one is set",
            func = function( state )
                GLuaTest.HttpHelloConVar:SetBool( true )
                GLuaTest.HttpHelloRunnerConVar:SetString( "agent/claude-code" )

                GLuaTest.sendUsagePing( state.groups )

                local request = state.httpStub.callHistory[1][1]
                expect( request.parameters.runner ).to.equal( "agent/claude-code" )
            end
        },

        {
            name = "Sends nothing when gluatest_http_hello is off",
            func = function( state )
                GLuaTest.HttpHelloConVar:SetBool( false )

                GLuaTest.sendUsagePing( state.groups )

                expect( state.httpStub ).wasNot.called()
            end
        },
    }
}
