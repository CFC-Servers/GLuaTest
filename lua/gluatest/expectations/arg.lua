local argMeta = {
    __tostring = function( self )
        return "Arg Matcher: " .. self.name
    end,
}

--- Creates a new argument matcher
--- @param name string The name of the matcher (for use in error messages)
--- @param check fun(any): boolean A function that returns true if the argument matches
local function New( name, check )
    --- @class GLuaTest_ArgMatcher
    local arg = {
        --- Identifies this object as an argument matcher
        --- @type true
        IsArgMatcher = true,

        --- @type string
        --- The name of the matcher, used in error messages
        name = name,

        --- A function that returns true if the argument matches
        check = check,
    }

    return setmetatable( arg, argMeta )
end

--- Creates a matcher for arguments whose `type()` is exactly the given name, the same comparison `beA` makes
--- @param typeName string
local function Type( typeName )
    return New( "Any " .. typeName, function( arg )
        return type( arg ) == typeName
    end )
end

--- @class GLuaTest_ArgMatchers
local Arg = {
    New = New,
    Type = Type,

    --- Matches any argument, including nil
    Any = New( "Any", function( _ )
        return true
    end ),

    String = Type( "string" ),
    Number = Type( "number" ),
    Boolean = Type( "boolean" ),
    Table = Type( "table" ),
    Function = Type( "function" ),

    --- Matches any Entity, including Players, Weapons, Vehicles, and NPCs
    Entity = New( "Any Entity", function( arg )
        return isentity( arg )
    end ),
}

return Arg
