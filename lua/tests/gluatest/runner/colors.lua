local function getColors()
    return include( "gluatest/runner/colors.lua" )
end

return {
    groupName = "Colors",

    cases = {
        {
            name = "Returns a table of colors",
            func = function()
                stub( hook, "Run" )
                local colors = getColors()

                for name, value in pairs( colors ) do
                    expect( name ).to.beA( "string" )
                    expect( IsColor( value ) ).to.beTrue()
                end
            end
        },

        {
            name = "Calls hook.Run when the color table is created",
            func = function()
                local hookRunStub = stub( hook, "Run" ) --[[@as GLuaTest_Stub]]

                local colors = getColors()

                local callHistory = hookRunStub.callHistory
                expect( callHistory[1] ).to.deepEqual( { "GLuaTest_MakeColors", colors } )
            end
        }
    }
}
