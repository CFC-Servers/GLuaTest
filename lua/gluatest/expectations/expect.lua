local makePositive = include( "gluatest/expectations/positive.lua" )
local makeNegative = include( "gluatest/expectations/negative.lua" )

return function( subject, ... )
    local positive = makePositive( subject, ... )
    local negative = makeNegative( subject, ... )

    return {
        to = positive,
        notTo = negative,
        toNot = negative
    }
end
