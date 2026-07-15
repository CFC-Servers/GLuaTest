return {
    groupName = "Positive Expectations",

    cases = {
        {
            name = "called with a count fails when the stub was called too many times",
            func = function()
                local testStub = stub()

                testStub()
                testStub()

                expect( function()
                    expect( testStub ).was.called( 1 )
                end ).to.errWith( "Expectation Failed: Expected GLuaTest::Stub to have been called exactly 1 times, got: 2" )
            end
        },
        {
            name = "aboutEqual requires a numeric comparison",
            func = function()
                expect( function()
                    expect( 1 ).to.aboutEqual( "1" )
                end ).to.errWith( ".aboutEqual expects a number" )
            end
        },
        {
            name = "beAn failure message uses positive wording",
            func = function()
                expect( function()
                    expect( "value" ).to.beAn( "number" )
                end ).to.errWith( "Expectation Failed: Expected 'value' to be an 'number'" )
            end
        }
    }
}
