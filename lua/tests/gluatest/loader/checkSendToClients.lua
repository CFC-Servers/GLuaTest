return {
    groupName = "GLuaTest: Loader.checkSendToClients",
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
            name = "Sends clientside cases when RUN_CLIENTSIDE is enabled",
            func = function( state )
                local Loader = state.Loader
                state.currentRunClientside = GLuaTest.RUN_CLIENTSIDE

                GLuaTest.RUN_CLIENTSIDE = true
                local AddCSLuaFileStub = stub( _G, "AddCSLuaFile" )

                local cases = { { clientside = true } }
                Loader.checkSendToClients( "test.lua", cases )
                expect( AddCSLuaFileStub ).was.called()
            end,

            cleanup = function( state )
                GLuaTest.RUN_CLIENTSIDE = state.currentRunClientside
            end
        },

        {
            name = "Does not send clientside cases if RUN_CLIENTSIDE is disabled",
            func = function( state )
                local Loader = state.Loader
                state.currentRunClientside = GLuaTest.RUN_CLIENTSIDE

                GLuaTest.RUN_CLIENTSIDE = false
                local AddCSLuaFileStub = stub( _G, "AddCSLuaFile" )

                local cases = { { clientside = true } }
                Loader.checkSendToClients( "test.lua", cases )
                expect( AddCSLuaFileStub ).wasNot.called()
            end,

            cleanup = function( state )
                GLuaTest.RUN_CLIENTSIDE = state.currentRunClientside
            end
        },

        {
            name = "Does not send non-clientside cases when RUN_CLIENTSIDE is enabled",
            func = function( state )
                local Loader = state.Loader
                state.currentRunClientside = GLuaTest.RUN_CLIENTSIDE

                GLuaTest.RUN_CLIENTSIDE = true
                local AddCSLuaFileStub = stub( _G, "AddCSLuaFile" )

                local cases = { { clientside = false } }
                Loader.checkSendToClients( "test.lua", cases )
                expect( AddCSLuaFileStub ).wasNot.called()
            end,

            cleanup = function( state )
                GLuaTest.RUN_CLIENTSIDE = state.currentRunClientside
            end
        }
    }
}
