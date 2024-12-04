local TypeID = TypeID
local TYPE_TABLE = TYPE_TABLE
local TYPE_STRING = TYPE_STRING

local function stringifyKey( key )
    if TypeID( key ) == TYPE_STRING then
        -- check if it is a key that we can do a dot access on
        if key:match( "^[%a_][%w_]*$" ) then
            return "." .. key
        end

        key = "\"" .. key:gsub( "\"", "\\\"" ) .. "\""
    end

    return "[" .. key .. "]"
end

local function GetDiff( t1, t2, path )
    path = path or "tableA"
    if t1 == t2 then
        return false
    end

    for k, v in pairs( t1 ) do
        local currentPath = path .. stringifyKey( k )

        -- Key is missing from k2
        if t2[k] == nil then
            return true, currentPath
        end

        if TypeID( v ) == TYPE_TABLE and TypeID( t2[k] ) == TYPE_TABLE then
            local isDifferent, diffPath = GetDiff( v, t2[k], currentPath )
            if isDifferent then
                return true, diffPath
            end
        elseif v ~= t2[k] then
            return true, currentPath
        end
    end

    -- Extra key in t2
    for k in pairs( t2 ) do
        if t1[k] == nil then
            return true, path .. stringifyKey( k )
        end
    end

    return false
end

return GetDiff
