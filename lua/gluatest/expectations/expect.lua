--- @type fun(subject: any, vararg): GLuaTest_PositiveExpectations
local makePositive = include( "gluatest/expectations/positive.lua" )

--- @type fun(subject: any, vararg): GLuaTest_NegativeExpectations
local makeNegative = include( "gluatest/expectations/negative.lua" )

return function( subject, ... )
    local positive = makePositive( subject, ... )
    local negative = makeNegative( subject, ... )

    --- @class GLuaTest_Expect
    local expect = {
        to = positive,
        notTo = negative,
        toNot = negative,

        was = positive,
        wasNot = negative
    }

    hook.Run( "GLuaTest_CreateExpect", expect )

    return expect
end
