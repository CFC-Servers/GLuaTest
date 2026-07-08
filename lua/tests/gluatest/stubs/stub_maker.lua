return {
    groupName = "Stub Maker",

    cases = {
        {
            name = "returns preserves trailing nil values",
            func = function()
                local testStub = stub().returns( "value", nil )
                local value, trailingNil = testStub()

                expect( value ).to.equal( "value" )
                expect( trailingNil ).to.beNil()
                expect( select( "#", testStub() ) ).to.equal( 2 )
            end
        }
    }
}
