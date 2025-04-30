return {
    groupName = "checkSendToClients",
    beforeEach = function( state )
        state.Loader = include( "gluatest/loader.lua" )
    end,

    cases = {
        {
            name = "Exists on the Loader table",
            func = function( state )
                local Loader = state.Loader

                expect( Loader.checkSendToClients ).to.beA( "function" )
            end
        },

        {
            name = "Sends clientside cases when the gluatest_client_enable ConVar is enabled",
            func = function( state )
                local Loader = state.Loader
                state.currentRunClientside = GLuaTest.RunClientsideConVar:GetBool()

                GLuaTest.RunClientsideConVar:SetBool( true )
                local AddCSLuaFileStub = stub( _G, "AddCSLuaFile" )

                local cases = { { clientside = true } }
                Loader.checkSendToClients( "test.lua", cases )
                expect( AddCSLuaFileStub ).was.called()
            end,
            cleanup = function( state )
                GLuaTest.RunClientsideConVar:SetBool( state.currentRunClientside )
            end
        },

        {
            name = "Does not send clientside cases if the gluatest_client_enable ConVar is disabled",
            func = function( state )
                local Loader = state.Loader
                state.currentRunClientside = GLuaTest.RunClientsideConVar:GetBool()

                GLuaTest.RunClientsideConVar:SetBool( false )
                local AddCSLuaFileStub = stub( _G, "AddCSLuaFile" )

                local cases = { { clientside = true } }
                Loader.checkSendToClients( "test.lua", cases )
                expect( AddCSLuaFileStub ).wasNot.called()
            end,

            cleanup = function( state )
                GLuaTest.RunClientsideConVar:SetBool( state.currentRunClientside )
            end
        },

        {
            name = "Does not send non-clientside cases when the gluatest_client_enable ConVar is enabled",
            func = function( state )
                local Loader = state.Loader
                state.currentRunClientside = GLuaTest.RunClientsideConVar:GetBool()

                GLuaTest.RunClientsideConVar:SetBool( true )
                local AddCSLuaFileStub = stub( _G, "AddCSLuaFile" )

                local cases = { { clientside = false } }
                Loader.checkSendToClients( "test.lua", cases )
                expect( AddCSLuaFileStub ).wasNot.called()
            end,

            cleanup = function( state )
                GLuaTest.RunClientsideConVar:SetBool( state.currentRunClientside )
            end
        }
    }
}
