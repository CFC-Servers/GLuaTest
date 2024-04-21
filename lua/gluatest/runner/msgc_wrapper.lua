-- == MsgC Ansi Wrapper == --
local MsgC = _G["MsgC"]

if SERVER then
    if system.IsWindows() and BRANCH ~= "x86-64" then return MsgC end

    local shouldWrap = GetConVar( "gluatest_use_ansi" )

    _G["_MsgC"] = _G["MsgC"]
    local _MsgC = _G["_MsgC"]

    local startColor = "\x1b[38;2;"
    local endColor = "\x1b[0m"

    local function colorToAnsi( col )
        local r = col.r
        local g = col.g
        local b = col.b
        return string.format( "%s%d;%d;%dm", startColor, r, g, b )
    end

    MsgC = function( ... )
        --
        -- Wraps MsgC to convert colors to ANSI
        --
        if shouldWrap:GetBool() == false then
            return _MsgC( ... )
        end

        local line = ""

        for _, t in ipairs( { ... } ) do
            if IsColor( t ) then
                line = line .. colorToAnsi( t )
            else
                line = line .. tostring( t )
            end
        end

        line = string.Replace( line, "\n", endColor .. "\n" )

        return _MsgC( line )
    end
end

return MsgC
