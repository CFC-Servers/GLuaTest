local colors = {
    red = Color( 255, 0, 0 ),
    green = Color( 0, 255, 0 ),
    grey = Color( 136, 151, 158 ),
    darkgrey = Color( 85, 85, 85 ),
    yellow = Color( 235, 226, 52 ),
    white = Color( 220, 220, 220 ),
    blue = Color( 120, 162, 204 )
}

-- == MsgC Ansi Wrapper == --
local _MsgC = _G["MsgC"]
local endColor = "\x1b[0m"
local startColor = "\x1b[38;2;"

local function colorToAnsi( col )
    local r = col.r
    local g = col.g
    local b = col.b
    return string.format( "%s%d;%d;%dm", startColor, r, g, b )
end

local MsgC = function( ... )
    local line = ""

    for _, t in ipairs( {...} ) do
        if IsColor( t ) then
            line = line .. colorToAnsi( t )
        else
            line = line .. tostring( t )
        end
    end

    line = string.Replace( line, "\n", endColor .. "\n" )

    return _MsgC( line )
end

-- == Logging == --
local function prefixLog( ... )
    MsgC( colors.darkgrey, "[GLuaTest] " )
    MsgC( ... )
end

local function logFileStart( name )
    prefixLog( colors.blue, "Starting tests cases from: [", name , "]...", "\n" )
end

-- local fileReadCache = {}
local function cleanPathForRead( path )
    -- { "addons", "addon_name", "lua", "tests", "addon_name", "test.lua" }
    local expl = string.Explode( "/", path )

    local startCopy
    for i = 1, #expl do
        local step = expl[i]

        if step == "tests" then
            startCopy = i
            break
        end
    end

    return table.concat( expl, "/", startCopy, #expl )
end

local function getLeadingWhitespace( line )
    return string.match( line, "^%s+" ) or ""
end

local fileCache = {}
local function getFileLines( filePath )
    local cached = fileCache[filePath]
    if cached then return cached end

    local cleanPath = cleanPathForRead( filePath )
    local testFile = file.Open( cleanPath, "r", "LUA" )
    local fileContents = testFile:Read( testFile:Size() )
    testFile:Close()

    local fileLines = string.Split( fileContents, "\n" )
    fileCache[filePath] = fileLines

    return fileLines
end

local function getLeastSharedIndent( lines )
    local leastSharedLeft = ""

    for i = 1, #lines do
        local lineContent = lines[i]

        local leading = getLeadingWhitespace( lineContent )
        if #leastSharedLeft == 0 then
            leastSharedLeft = leading
        else
            local leadingLen = #leading
            if leadingLen > 0 and leadingLen < #leastSharedLeft then
                leastSharedLeft = leading
            end
        end
    end

    return leastSharedLeft
end

local function getLineWithContext( path, line, context )
    if not context then context = 5 end
    local fileLines = getFileLines( path )

    local lineWithContext = {}
    for i = line - context, line do
        local lineContent = fileLines[i]
        table.insert( lineWithContext, lineContent )
    end

    return lineWithContext
end

local function normalizeLinesIndent( lines )
    local leastSharedIndent = getLeastSharedIndent( lines )

    for i = 1, #lines do
        local lineContent = lines[i]
        lines[i] = string.Replace( lineContent, leastSharedIndent, "" )
    end

    return lines
end

local function generateDivider( lines, reason )
    local longestLine = 0

    for i = 1, #lines do
        local line = lines[i]
        local lineLength = #line
        if lineLength > longestLine then
            longestLine = lineLength
        end
    end

    local dividerLength = math.min( longestLine + #reason, 110 )
    return string.rep( "_", dividerLength )
end

local function drawLine( content, lineNumber )
    MsgC( colors.grey, string.rep( " ", 4 - #lineNumber ) )
    MsgC( colors.white, lineNumber, " " )
    MsgC( colors.grey, "| ", content )
end

local function drawFailingLine( content, lineNumber, divider, reason )
    local contentLength = 7 + #content
    local newLineLength = contentLength + 2 + #reason

    local drawAbove = contentLength - #divider > #reason
    local drawBelow = newLineLength > #divider

    -- If the content exceeds the divider by more than the length of the reason
    if drawAbove then
        MsgC( colors.grey, string.rep( " ", 5 ) )
        MsgC( colors.grey, "|" )
        MsgC( colors.grey, string.rep( " ", 1 + #getLeadingWhitespace( content ) ) )
        MsgC( colors.red, "v ", reason, "\n" )
    end

    drawLine( content, lineNumber )

    if not drawAbove then
        if drawBelow then
            MsgC( "\n" )
            MsgC( colors.grey, string.rep( " ", 5 ) )
            MsgC( colors.grey, "|" )
            MsgC( colors.grey, string.rep( " ", 1 + #getLeadingWhitespace( content ) ) )
            MsgC( colors.red, "^ ", reason, "\n" )
        else
            MsgC( colors.red, " <- ", reason, "\n" )
        end
    end
end

local function logCodeContext( errInfo )
    local reason = errInfo.reason
    local sourceFile = errInfo.sourceFile
    local lineNumber = errInfo.lineNumber

    local lines = getLineWithContext( sourceFile, lineNumber )
    local lineCount = #lines
    lines = normalizeLinesIndent( lines )

    local divider = generateDivider( lines, reason )

    MsgC( colors.white, "    Context:", "\n" )
    MsgC( colors.grey,  "      ", divider, "\n" )
    MsgC( colors.grey,  "     | ", "\n" )

    for i = 1, lineCount do
        local lineContent = lines[i]
        local contextLineNumber = lineNumber - ( lineCount - i )
        local lineNumStr = tostring( contextLineNumber )
        local onFailingLine = contextLineNumber == lineNumber

        if onFailingLine then
            drawFailingLine( lineContent, lineNumStr, divider, reason )
        else
            drawLine( lineContent, lineNumStr )
            MsgC( "\n" )
        end

    end

    MsgC( colors.grey,  "     |", divider, "\n" )
end

local function logLocals( errInfo )
    local locals = errInfo.locals

    local localCount = #locals
    if localCount == 0 then return end

    MsgC( colors.grey, "    " )
    MsgC( colors.white, "Locals: ", "\n" )

    for i = 1, #locals do
        local name, value = unpack( locals[i] )
        MsgC( colors.grey, "       " )
        MsgC( colors.blue, name )
        MsgC( colors.white, " = " )
        MsgC( colors.blue, tostring( value ), "\n" )
    end

    MsgC( "\n" )
end

local function logFailedTest( errInfo )
    local sourceFile = errInfo.sourceFile

    MsgC( colors.white, "    File:", "\n" )
    MsgC( colors.grey,  "       ", sourceFile, "\n\n" )

    logLocals( errInfo )
    logCodeContext( errInfo )
end

local function logTestResults( results )
    local resultCount = #results

    for i = 1, resultCount do
        local result = results[i]
        local case = result.case
        local success = result.success
        local errInfo = result.errInfo

        if success then
            prefixLog( colors.green, "PASS " )
        else
            prefixLog( colors.red, "FAIL " )
        end

        MsgC( colors.grey, "[", case.name, "]" )

        if not success then
            MsgC( "\n" )
            logFailedTest( errInfo )
        end

        hook.Run( "GLuaTest_LoggedTestResult", success, result, case, errInfo )
        MsgC( "\n" )
    end
end

local expect = include( "gluatest/expectations.lua" )

return function( testFiles )
    local results = {}

    local defaultEnv = getfenv( 1 )
    local testEnv = setmetatable(
        {
            expect = expect,
            _R = _R
        },
        { __index = _G }
    )

    local function getLocals( level )
        local locals = {}
        local i = 1

        while true do
            local name, value = debug.getlocal( level, i )
            if name == nil then break end
            if name ~= "(*temporary)" then
                table.insert( locals, { name, value == nil and "nil" or value } )
            end
            i = i + 1
        end

        return locals
    end

    local function findStackInfo()
        -- Step up through the stacks to find the error we care about

        for stack = 3, 12 do
            local info = debug.getinfo( stack, "lnS" )
            if not info then break end

            if #info.namewhat == 0 then return stack, info end
        end

        -- This should never happen!!
        print("The bad thing happened!!!!!")
        return 2, debug.getinfo( 2, "lnS" )
    end

    local function failCallback( reason )
        if reason == "" then
            print( "Received empty error reason in failCallback- ignoring " )
            return
        end

        -- root/file/name.lua:420: Expectation Failed: Failure reason
        -- root/file/name.lua:420: attempt to index nil value 'blah'
        local reasonSpl = string.Split( reason, ": " )

        if reasonSpl[2] == "Expectation Failed" then
            table.remove( reasonSpl, 2 )
        else
            table.insert( reasonSpl, 2, "Unhandled" )
        end

        local cleanReason = table.concat( reasonSpl, ": ", 2, #reasonSpl )

        local level, info = findStackInfo()
        local locals = getLocals( level )

        return {
            reason = cleanReason,
            sourceFile = info.short_src,
            lineNumber = info.currentline,
            locals = locals or {}
        }
    end

    hook.Run( "GLuaTest_StartedTestRun", testFiles )

    local function runNextTest( tests )
        local test = table.remove( tests )
        if not test then
            -- TODO: Log failure details here, log the one-line results during the loop
            logTestResults( results )
            return
        end

        local fileName = test.fileName
        local cases = test.cases
        local caseCount = #cases

        hook.Run( "GLuaTest_RunningTestFile", test )
        logFileStart( fileName )

        local asyncCases = {}

        for c = 1, caseCount do
            local case = cases[c]
            if case.async then
                asyncCases[case.name] = case
            else
                local func = case.func

                setfenv( func, testEnv )
                local success, errInfo = xpcall( func, failCallback )
                setfenv( func, defaultEnv )

                hook.Run( "GLuaTest_RanTestCase", test, case, success, errInfo )

                table.insert( results, {
                    success = success,
                    case = case,
                    errInfo = success and nil or errInfo
                } )
            end
        end

        local asyncCount = table.Count( asyncCases )
        if asyncCount == 0 then
            runNextTest( tests )
            return
        end

        local callbacks = {}
        local checkComplete = function()
            local cbCount = table.Count( callbacks )
            if cbCount ~= asyncCount then return end

            timer.Remove( "GLuaTest_AsyncWaiter" )
            runNextTest( tests )
        end

        for name, case in pairs( asyncCases ) do
            local caseFunc = case.func
            local caseTimeout = case.timeout

            local asyncEnv = setmetatable(
                {
                    -- We manually catch expectation errors here in case
                    -- they're called in an async function
                    expect = function( subject )
                        local built = expect( subject )

                        -- Wrap the error-throwing function
                        -- and handle the error with the correct context
                        built.to.expected = function( ... )
                            local success, errInfo = xpcall( expect, failCallback, subject )
                            setfenv( caseFunc, defaultEnv )

                            -- Record the failure
                            hook.Run( "GLuaTest_RanTestCase", test, case, success, errInfo )

                            table.insert( results, {
                                success = false,
                                case = case,
                                errInfo = errInfo
                            })

                            timer.Remove( "GLuaTest_AsyncTimeout_" .. name )

                            callbacks[name] = false
                            checkComplete()

                            -- Halt the test?
                            -- (Should be caught by the outer xpcall)
                            error( "" )
                        end

                        return built
                    end,

                    done = function()
                        if callbacks[name] ~= nil then
                            print( "Tried to call done() after we already recorded a result?" )
                            print( name )
                            return
                        end

                        callbacks[name] = true
                        setfenv( caseFunc, defaultEnv )
                        checkComplete()
                    end,

                    _R = _R
                },
                { __index = _G }
            )

            setfenv( caseFunc, asyncEnv )
            local success, errInfo = xpcall( caseFunc, failCallback )

            if caseTimeout then
                timer.Create( "GluaTest_AsyncTimeout_" .. name, caseTimeout, 1, function()
                    local timeoutInfo = { reason = "Timeout" }

                    hook.Run( "GLuaTest_RanTestCase", test, case, success, timeoutInfo )
                    table.insert( results, {
                        success = success,
                        case = case,
                        errInfo = timeoutInfo
                    })
                end )
            end

            -- If the test failed while calling it
            -- (Async expectation failures handled in asyncEnv.expect)
            -- (Async unhandled failures handled with timeouts)
            if not success then
                callbacks[name] = false
                timer.Remove( "GLuaTest_AsyncTimeout_" .. name )
                hook.Run( "GLuaTest_RanTestCase", test, case, success, errInfo )
                table.insert( results, {
                    success = success,
                    case = case,
                    errInfo = errInfo
                })
            end
        end

        timer.Create( "GLuaTest_AsyncWaiter", 60, 1, function()
            for name, case in pairs( asyncCases ) do
                if callbacks[name] == nil then
                    hook.Run( "GLuaTest_TestCaseTimeout", test, case )
                    table.insert( results, {
                        success = success,
                        case = case,
                        errInfo = errInfo
                    })
                end
            end

            runNextTest( tests )
        end )
    end


    hook.Run( "GLuaTest_RanTestFiles", testFiles, results )
end
