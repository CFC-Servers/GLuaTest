local GetDiff = include( "table_diff.lua" )

local maxReportedCalls = 5

--- @class GLuaTest_CalledWith
local CalledWith = {}

--- @param given any
--- @param expected any A literal value or an Arg matcher
local function argMatches( given, expected )
    if given == expected then return true end
    if not istable( expected ) then return false end
    if expected.IsArgMatcher then return expected.check( given ) end
    if not istable( given ) then return false end

    local isDifferent = GetDiff( given, expected )

    return not isDifferent
end

--- @param call any[]
--- @param expected any[]
local function callMatches( call, expected )
    -- a trailing nil cannot be told apart from an argument that was never passed
    local argCount = math.max( table.maxn( call ), table.maxn( expected ) )

    for k = 1, argCount do
        if not argMatches( call[k], expected[k] ) then return false end
    end

    return true
end

--- @param stub GLuaTest_Stub
--- @param expected any[]
--- @return boolean
function CalledWith.wasCalledWith( stub, expected )
    for _, call in ipairs( stub.callHistory ) do
        if callMatches( call, expected ) then return true end
    end

    return false
end

--- @param arg any
local function formatArg( arg )
    if isstring( arg ) then return "\"" .. arg .. "\"" end

    return tostring( arg )
end

--- @param args any[]
--- @return string
function CalledWith.formatArgs( args )
    local formatted = {}

    for k = 1, table.maxn( args ) do
        formatted[k] = formatArg( args[k] )
    end

    if #formatted == 0 then return "()" end

    return "( " .. table.concat( formatted, ", " ) .. " )"
end

--- @param stub GLuaTest_Stub
--- @return string
function CalledWith.formatCalls( stub )
    local history = stub.callHistory
    local callCount = #history
    if callCount == 0 then return "it was never called" end

    local reportedCount = math.min( callCount, maxReportedCalls )
    local formatted = {}

    for k = 1, reportedCount do
        formatted[k] = CalledWith.formatArgs( history[k] )
    end

    local summary = "it was called with: " .. table.concat( formatted, ", " )
    if callCount == reportedCount then return summary end

    return summary .. " and " .. ( callCount - reportedCount ) .. " more"
end

return CalledWith
