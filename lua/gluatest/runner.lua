local function logFileStart( name )
    print( name )
end

local function logTestStart( name )
    print( name )
end

local function logTestResults( results )
    print( results )
end

return function( testFiles )
    local results = {}
    local fileCount = #testFiles

    local defaultEnv = getfenv( 1 )
    local testEnv = setmetatable(
        {
            expect = include( "expectations.lua" ),
            _R = _R
        },
        { __index = _G }
    )

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
            local success, errInfo = xpcall( func, cb )
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
