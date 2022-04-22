local colors = {
    red = Color( 255, 0, 0 ),
    green = Color( 0, 255, 0 ),
    grey = Color( 136, 151, 158 ),
    darkgrey = Color( 85, 85, 85 ),
    yellow = Color( 235, 226, 52 ),
    white = Color( 220, 220, 220 ),
    blue = Color( 120, 162, 204 )
}

local function log( ... )
    MsgC( colors.darkgrey, "[GLuaTest] " )
    MsgC( ... )
end

local function logFileStart( name )
    log( colors.blue, "Starting tests cases from: [", name , "]...", "\n" )
end

local function logTestStart( name )
    log( colors.grey, "Running: [", name , "]...", "\n" )
end

local function logTestResults( results )
    local resultCount = #results

    for i = 1, resultCount do
        local result = results[i]
        local case = result.case
        local success = result.success

        if success then
            log( colors.green, "PASS " )
        else
            log( colors.red, "FAIL" )
        end

        log( colors.grey, case.name, "\n" )

        if not success then
            local errInfo = result.errInfo
            local reason = errInfo.reason

            log( "    ", colors.white, "Reason: " )
            log( colors.red, reason, "\n" )
        end
    end
end

return function( testFiles )
    local results = {}
    local fileCount = #testFiles

    local defaultEnv = getfenv( 1 )
    local testEnv = setmetatable(
        {
            expect = include( "gluatest/expectations.lua" ),
            _R = _R
        },
        { __index = _G }
    )

    local function failCallback( reason )
        -- TODO: get stack info, locals, line number, etc.
        return {
            reason = reason
        }
    end

    -- TODO: Make sure a test file can't return garbage data that makes this error
    for f = 1, fileCount do
        local test = testFiles[f]
        local fileName = test.fileName
        local cases = test.cases
        local caseCount = #cases

        logFileStart( fileName )

        for c = 1, caseCount do
            local case = cases[c]
            local func = case.func
            local name = case.name

            logTestStart( name )


            setfenv( func, testEnv )
            local success, errInfo = xpcall( func, failCallback )
            setfenv( func, defaultEnv )

            table.insert( results, {
                success = success,
                case = case,
                errInfo = success and nil or errInfo
            } )
        end
    end

    logTestResults( results )
end
