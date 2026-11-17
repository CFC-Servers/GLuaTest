return {
    groupName = "calledWith",

    cases = {
        {
            name = "Passes when any call received exactly the given arguments",
            func = function()
                local myStub = stub()
                myStub( "1", "2", "3" )
                myStub( "a", "b", "c" )

                expect( myStub ).was.calledWith( "1", "2", "3" )
                expect( myStub ).was.calledWith( "a", "b", "c" )
            end
        },

        {
            name = "Fails on missing, mixed, or reordered arguments",
            func = function()
                local myStub = stub()
                myStub( "1", "2", "3" )
                myStub( "a", "b", "c" )

                expect( function() expect( myStub ).was.calledWith( "1", "2" ) end ).to.err()
                expect( function() expect( myStub ).was.calledWith( "1", "b", "3" ) end ).to.err()
                expect( function() expect( myStub ).was.calledWith( "2", "3", "1" ) end ).to.err()
            end
        },

        {
            name = "Fails when the stub was never called",
            func = function()
                local myStub = stub()

                expect( function() expect( myStub ).was.calledWith( "1" ) end ).to.err()
            end
        },

        {
            name = "Matches a call that had no arguments",
            func = function()
                local myStub = stub()
                myStub()

                expect( myStub ).was.calledWith()
                expect( myStub ).wasNot.calledWith( "1" )
            end
        },

        {
            name = "Accepts Arg matchers in place of literal values",
            func = function()
                local myStub = stub()
                myStub( "1", 2, {} )

                expect( myStub ).was.calledWith( Arg.Any, 2, Arg.Table )
                expect( myStub ).was.calledWith( Arg.String, Arg.Number, Arg.Any )
                expect( function() expect( myStub ).was.calledWith( Arg.Number, 2, Arg.Table ) end ).to.err()
            end
        },

        {
            name = "Accepts custom matchers made with Arg.New",
            func = function()
                local positive = Arg.New( "a positive number", function( n ) return isnumber( n ) and n > 0 end )
                local myStub = stub()
                myStub( 5 )

                expect( myStub ).was.calledWith( positive )
                expect( tostring( positive ) ).to.equal( "Arg Matcher: a positive number" )

                local otherStub = stub()
                otherStub( -5 )

                expect( otherStub ).wasNot.calledWith( positive )
            end
        },

        {
            name = "Compares nil arguments by position",
            func = function()
                local myStub = stub()
                myStub( "1", nil, "3" )

                expect( myStub ).was.calledWith( "1", nil, "3" )
                expect( myStub ).was.calledWith( "1", Arg.Any, "3" )
                expect( myStub ).wasNot.calledWith( "1", "3" )
            end
        },

        {
            name = "Compares table arguments by their contents",
            func = function()
                local myStub = stub()
                myStub( { id = 1, tags = { "a" } } )

                expect( myStub ).was.calledWith( { id = 1, tags = { "a" } } )
                expect( myStub ).wasNot.calledWith( { id = 1, tags = { "b" } } )
                expect( myStub ).wasNot.calledWith( { id = 1 } )
            end
        },

        {
            name = "Arg.Entity matches entity subclasses",
            func = function()
                local weapon = ents.Create( "weapon_pistol" )
                local myStub = stub()
                myStub( weapon )

                expect( type( weapon ) ).to.equal( "Weapon" )
                expect( myStub ).was.calledWith( Arg.Entity )
                expect( myStub ).was.calledWith( Arg.Type( "Weapon" ) )
                expect( myStub ).wasNot.calledWith( Arg.Type( "Entity" ) )

                weapon:Remove()
            end
        },

        {
            name = "Reports the expected arguments and the recorded calls on failure",
            func = function()
                local myStub = stub()
                myStub( "1", 2 )
                myStub()

                local expectedMessage = "Expectation Failed: Expected GLuaTest::Stub to have been called with "
                    .. "( 1, Arg Matcher: Any table, nil, true ), but it was called with: ( \"1\", 2 ), ()"

                expect( function()
                    expect( myStub ).was.calledWith( 1, Arg.Table, nil, true )
                end ).to.errWith( expectedMessage )
            end
        },

        {
            name = "Reports when the stub was never called",
            func = function()
                local myStub = stub()
                local expectedMessage = "Expectation Failed: Expected GLuaTest::Stub to have been called with ( \"a\" ), but it was never called"

                expect( function()
                    expect( myStub ).was.calledWith( "a" )
                end ).to.errWith( expectedMessage )
            end
        },

        {
            name = "Truncates long call histories in the failure message",
            func = function()
                local myStub = stub()
                for callNumber = 1, 7 do myStub( callNumber ) end

                local expectedMessage = "Expectation Failed: Expected GLuaTest::Stub to have been called with ( 0 ), "
                    .. "but it was called with: ( 1 ), ( 2 ), ( 3 ), ( 4 ), ( 5 ) and 2 more"

                expect( function()
                    expect( myStub ).was.calledWith( 0 )
                end ).to.errWith( expectedMessage )
            end
        },

        {
            name = "wasNot passes only when no call matches",
            func = function()
                local myStub = stub()
                myStub( "1", "2" )

                expect( myStub ).wasNot.calledWith( "1" )
                expect( function() expect( myStub ).wasNot.calledWith( "1", "2" ) end ).to.err()
                expect( function() expect( myStub ).wasNot.calledWith( Arg.String, Arg.Any ) end ).to.err()
            end
        },

        {
            name = "Rejects subjects that are not stubs",
            func = function()
                expect( function() expect( {} ).was.calledWith( "1" ) end ).to.err()
            end
        },
    }
}
