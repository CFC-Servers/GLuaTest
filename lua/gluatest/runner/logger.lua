local Helpers = include( "gluatest/runner/log_helpers.lua" )
local GenerateDivider = Helpers.GenerateDivider
local GetLineWithContext = Helpers.GetLineWithContext
local GetLeadingWhitespace = Helpers.GetLeadingWhitespace
local NormalizeLinesIndent = Helpers.NormalizeLinesIndent

local colors = include( "gluatest/runner/colors.lua" )
local MsgC = include( "gluatest/runner/msgc_wrapper.lua" )

local ResultLogger = {}


function ResultLogger.prefixLog( ... )
    MsgC( colors.darkgrey, "[" )
    MsgC( colors.white, "GLuaTest" )
    MsgC( colors.darkgrey, "] " )
    MsgC( ... )
end


function ResultLogger.drawLine( content, lineNumber )
    --
    -- Draws a line of code in the Context Block
    --
    MsgC( colors.grey, string.rep( " ", 4 - #lineNumber ) )
    MsgC( colors.white, lineNumber, " " )
    MsgC( colors.grey, "| ", content )
end


function ResultLogger.drawFailingLine( content, lineNumber, divider, reason )
    --
    -- Draw a given line of code, a pointer-arrow, and the failure reason
    --
    local contentLength = 7 + #content
    local newLineLength = contentLength + 2 + #reason

    local drawAbove = contentLength - #divider > #reason
    local drawBelow = newLineLength > #divider

    -- If the content exceeds the divider by more than the length of the reason
    if drawAbove then
        MsgC( colors.grey, string.rep( " ", 5 ) )
        MsgC( colors.grey, "|" )
        MsgC( colors.grey, string.rep( " ", 1 + #GetLeadingWhitespace( content ) ) )
        MsgC( colors.red, "v ", reason, "\n" )
    end

    ResultLogger.drawLine( content, lineNumber )

    if not drawAbove then
        if drawBelow then
            MsgC( "\n" )
            MsgC( colors.grey, string.rep( " ", 5 ) )
            MsgC( colors.grey, "|" )
            MsgC( colors.grey, string.rep( " ", 1 + #GetLeadingWhitespace( content ) ) )
            MsgC( colors.red, "^ ", reason, "\n" )
        else
            MsgC( colors.red, " <- ", reason, "\n" )
        end
    end
end


function ResultLogger.logCodeContext( errInfo )
    --
    -- Given a test failure, gather info about the failing code
    -- and draw a block of code context with a pointer-arrow to the failure
    --
    local reason = errInfo.reason
    local sourceFile = errInfo.sourceFile
    local lineNumber = errInfo.lineNumber

    if CLIENT then
        -- Clients can't read the failing files to get code context
        -- So we just print some simple output here
        MsgC( colors.white, "    Cause:", "\n" )
        MsgC( colors.white, "       Line ", lineNumber, ": " )
        MsgC( colors.red, reason, "\n" )
        return
    end

    local lines = GetLineWithContext( sourceFile, lineNumber )
    local lineCount = #lines
    lines = NormalizeLinesIndent( lines )

    local divider = GenerateDivider( lines, reason )

    MsgC( colors.white, "    Context:", "\n" )
    MsgC( colors.grey,  "      ", divider, "\n" )
    MsgC( colors.grey,  "     | ", "\n" )

    for i = 1, lineCount do
        local lineContent = lines[i]
        local contextLineNumber = lineNumber - ( lineCount - i )
        local lineNumStr = tostring( contextLineNumber )
        local onFailingLine = contextLineNumber == lineNumber

        if onFailingLine then
            ResultLogger.drawFailingLine( lineContent, lineNumStr, divider, reason )
        else
            ResultLogger.drawLine( lineContent, lineNumStr )
            MsgC( "\n" )
        end
    end

    MsgC( colors.grey,  "     |", divider, "\n" )
end


function ResultLogger.logLocals( errInfo )
    --
    -- Given a test failure with local variables,
    -- draw a section to display the name and values
    -- of up to 5 local variables in the failing test
    --
    local locals = errInfo.locals or {}

    local localCount = math.min( 5, #locals )
    if localCount == 0 then return end

    MsgC( colors.grey, "    " )
    MsgC( colors.white, "Locals: ", "\n" )

    for i = 1, localCount do
        local name, value = unpack( locals[i] )
        MsgC( colors.grey, "       " )
        MsgC( colors.blue, name )
        MsgC( colors.white, " = " )
        MsgC( colors.blue, tostring( value ), "\n" )
    end

    MsgC( "\n" )
end


function ResultLogger.logTestCaseFailure( errInfo )
    --
    -- Draw information about a given test failure
    --
    local sourceFile = errInfo.sourceFile

    MsgC( colors.white, "    File:", "\n" )
    MsgC( colors.grey,  "       ", sourceFile, "\n\n" )

    ResultLogger.logLocals( errInfo )
    ResultLogger.logCodeContext( errInfo )
end


function ResultLogger.getResultCounts( allResults )
    local passed = 0
    local failed = 0
    local empty = 0
    local skipped = 0

    for _, result in ipairs( allResults ) do
        if result.success == true then
            passed = passed + 1
        elseif result.success == false then
            failed = failed + 1
        elseif result.empty then
            empty = empty + 1
        elseif result.skipped then
            skipped = skipped + 1
        end
    end

    return passed, failed, empty, skipped
end


function ResultLogger.getFailuresByGroup( allResults )
    local failuresByGroup = {}

    for _, result in ipairs( allResults ) do
        if result.success == false then
            local group = result.testGroup
            local failures = failuresByGroup[group] or {}
            table.insert( failures, result )
            failuresByGroup[group] = failures
        end
    end

    return failuresByGroup
end


function ResultLogger.LogFileStart( testGroup )
    local fileName = testGroup.fileName
    local groupName = testGroup.groupName
    local project = testGroup.project

    local identifier = project .. "/" .. ( groupName or fileName )

    MsgC( "\n" )
    ResultLogger.prefixLog( colors.blue, "=== Running ", identifier, "... ===", "\n" )
end


function ResultLogger.LogTestResult( result, usePrefix )
    if usePrefix == nil then usePrefix = true end

    local case = result.case
    local success = result.success

    local plog = usePrefix and ResultLogger.prefixLog or MsgC

    if success == true then
        plog( colors.green, "PASS " )
    elseif success == false then
        plog( colors.red, "FAIL " )
    elseif result.empty then
        plog( colors.darkgrey, "EMPT " )
    elseif result.skipped then
        plog( colors.darkgrey, "SKIP " )
    else
        ErrorNoHaltWithStack( "Improper success type" )
        PrintTable( result )
        return
    end

    MsgC( colors.grey, "[" )
    MsgC( colors.white, case.name )
    MsgC( colors.grey, "]" )
    MsgC( "\n" )
end


function ResultLogger.LogTestFailureDetails( failure )
    local case = failure.case
    local errInfo = failure.errInfo

    -- If the error came through without a source line,
    -- we'll use the function definition
    if not errInfo.sourceFile then
        local debugInfo = debug.getinfo( case.func )
        errInfo.sourceFile = debugInfo.short_src
        errInfo.lineNumber = debugInfo.linedefined
    end

    ResultLogger.logTestCaseFailure( errInfo )
    hook.Run( "GLuaTest_LoggedTestFailure", errInfo )

    MsgC( "\n" )
end


function ResultLogger.logSummaryIntro( testGroups, allResults, duration )
    local niceDuration = string.format( "%.3f", duration )
    local white = colors.white
    local blue = colors.blue

    ResultLogger.prefixLog( colors.white, "Test run complete! 🎉", "\n" )
    ResultLogger.prefixLog(
        white, "Ran ",
        blue, #allResults,
        white, " tests from ",
        blue, #testGroups,
        white, " test groups in ",
        blue, niceDuration,
        white, " seconds",
        "\n"
    )
end


function ResultLogger.logSummaryCounts( allResults )
    local white = colors.white
    local blue = colors.blue
    local red = colors.red
    local green = colors.green
    local darkgrey = colors.darkgrey

    local passed, failed, empty, skipped = ResultLogger.getResultCounts( allResults )
    ResultLogger.prefixLog( white, "| ", green,    "PASS: ", blue, passed, "\n" )
    ResultLogger.prefixLog( white, "| ", red,      "FAIL: ", blue, failed, "\n" )
    ResultLogger.prefixLog( white, "| ", darkgrey, "EMPT: ", blue, empty,  "\n" )
    ResultLogger.prefixLog( white, "| ", darkgrey, "SKIP: ", blue, skipped,  "\n" )
end


function ResultLogger.logFailureSummary( allResults )
    local allFailures = ResultLogger.getFailuresByGroup( allResults )
    if table.Count( allFailures ) == 0 then return end

    MsgC( "\n" )
    MsgC( colors.blue, "Test failures:", "\n" )

    for group, failures in pairs( allFailures ) do
        local fileName = group.fileName
        local groupName = group.groupName
        local project = group.project

        local identifier = project .. "/" .. ( groupName or fileName )
        MsgC( colors.blue, "=== ", identifier, " ===", "\n" )

        for _, failure in ipairs( failures ) do
            ResultLogger.LogTestResult( failure, false )
        end

        MsgC( "\n" )
    end
end


function ResultLogger.LogTestsComplete( testGroups, allResults, duration )
    MsgC( "\n", "\n" )
    ResultLogger.logSummaryIntro( testGroups, allResults, duration )
    ResultLogger.logSummaryCounts( allResults )
    ResultLogger.logFailureSummary( allResults )
    MsgC( "\n" )
    ResultLogger.PlainLogEnd()
end

-- External parsers rely on the output of this function it should not be changed often
function ResultLogger.PlainLogStart()
    print( "[GLuaTest]: Test run starting..." )
end

-- External parsers rely on the output of this function it should not be changed often
function ResultLogger.PlainLogEnd()
    print( "[GLuaTest]: Test run complete!" )
end

hook.Run( "GLuaTest_MakeResultLogger", ResultLogger )

return ResultLogger
