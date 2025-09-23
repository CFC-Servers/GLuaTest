local argMeta = {
    __tostring = function( self )
        return "Arg Matcher: " .. self.name
    end,
}

--- Creates a new argument matcher
--- @param name string The name of the matcher (for use in error messages)
--- @param check fun(any): boolean A function that returns true if the argument matches
local function New( name, check )
    --- @class GLuaTest_StubArg
    local arg = {
        --- @type string
        --- The name of the matcher, used in error messages
        name = name,

        --- A function that returns true if the argument matches
        check = check,
    }

    return setmetatable( arg, argMeta )
end

--- @alias GLuaTest_StubArg_Matcher fun(any): boolean

--- @class GLuaTest_StubArgs
local Arg = {
    --- The metatable for all argument matchers
    argMeta = argMeta,

    New = New,

    --- Checks if the given argument is an argument matcher
    --- @param arg any The argument to check
    IsArgMatcher = function( arg )
        return getmetatable( arg ) == argMeta
    end,

    --- Matches any argument
    Any = New( "Any", function( _ )
        return true
    end ),

    --- Matches nil
    Nil = New( "Nil", function( arg )
        return arg == nil
    end ),

    --- Matches any boolean
    Boolean = New( "Any Boolean", function( arg )
        return arg == true or arg == false
    end ),

    --- Matches any number
    Number = New( "Any Number", function( arg )
        return type( arg ) == "number"
    end ),

    --- Matches any string
    String = New( "Any String", function( arg )
        return type( arg ) == "string"
    end ),

    --- Matches any table
    Table = New( "Any Table", function( arg )
        return type( arg ) == "table"
    end ),

    --- Matches any function
    Function = New( "Any Function", function( arg )
        return type( arg ) == "function"
    end ),

    --- Matches any userdata
    Userdata = New( "Any Userdata", function( arg )
        return type( arg ) == "userdata"
    end ),

    --- Matches any thread
    Thread = New( "Any Thread", function( arg )
        return type( arg ) == "thread"
    end ),

    -- GMod Types

    --- Matches any Vector
    Vector = New( "Any Vector", function( arg )
        return type( arg ) == "Vector"
    end ),

    --- Matches any Angle
    Angle = New( "Any Angle", function( arg )
        return type( arg ) == "Angle"
    end ),

    --- Matches any Color
    Color = New( "Any Color", function( arg )
        return debug.getmetatable( arg ) == FindMetaTable( "Color" )
    end ),

    --- Matches any VMatrix
    Matrix = New( "Any Matrix", function( arg )
        return type( arg ) == "VMatrix"
    end ),

    --- Matches any Entity
    Entity = New( "Any Entity", function( arg )
        return type( arg ) == "Entity"
    end ),

    --- Matches any Player
    Player = New( "Any Player", function( arg )
        return type( arg ) == "Player"
    end ),

    --- Matches any Weapon
    Weapon = New( "Any Weapon", function( arg )
        return type( arg ) == "Weapon"
    end ),

    --- Matches any Vehicle
    Vehicle = New( "Any Vehicle", function( arg )
        return type( arg ) == "Vehicle"
    end ),

    --- Matches any Material
    Material = New( "Any Material", function( arg )
        return type( arg ) == "IMaterial"
    end ),

    --- Matches any PhysObj
    PhysObj = New( "Any PhysObj", function( arg )
        return type( arg ) == "PhysObj"
    end ),

    --- Matches any CTakeDamageInfo
    DamageInfo = New( "Any CTakeDamageInfo", function( arg )
        return type( arg ) == "CTakeDamageInfo"
    end ),

    --- Matches any CMoveData
    MoveData = New( "Any CMoveData", function( arg )
        return type( arg ) == "CMoveData"
    end ),

    --- Matches any CUserCmd
    UserCmd = New( "Any CUserCmd", function( arg )
        return type( arg ) == "CUserCmd"
    end ),

    --- Matches any CSoundPatch
    SoundPatch = New( "Any CSoundPatch", function( arg )
        return type( arg ) == "CSoundPatch"
    end ),

    --- Matches any File
    File = New( "Any File", function( arg )
        -- Apparently if the file doesn't exist, type( arg) will return "no value" ?
        return type( arg ) == "File"
    end ),

    --- Matches any SurfaceInfo
    SurfaceInfo = New( "Any SurfaceInfo", function( arg )
        return type( arg ) == "SurfaceInfo"
    end ),

    --- Matches any ConVar
    ConVar = New( "Any ConVar", function( arg )
        return type( arg ) == "ConVar"
    end ),


    -- Clientside


    --- Matches any Panel
    Panel = New( "Any Panel", function( arg )
        return type( arg ) == "Panel"
    end ),

    --- Matches any CLuaParticle
    Particle = New( "Any Particle", function( arg )
        return type( arg ) == "CLuaParticle"
    end ),

    --- Matches any CLuaEmitter
    ParticleEmitter = New( "Any ParticleEmitter", function( arg )
        return type( arg ) == "CLuaEmitter"
    end ),

    --- Matches any IMesh
    Mesh = New( "Any Mesh", function( arg )
        return type( arg ) == "IMesh"
    end ),
}

return Arg
