local Helpers = include( "gluatest/log_helpers.lua" )
local GenerateDivider = Helpers.GenerateDivider
local GetLineWithContext = Helpers.GetLineWithContext
local GetLeadingWhitespace = Helpers.GetLeadingWhitespace
local NormalizeLinesIndent = Helpers.NormalizeLinesIndent

local colors = include( "gluatest/colors.lua" )
local MsgC = include( "gluatest/msgc_wrapper.lua" )

local ResultLogger = {}

local function prefixLog( ... )
    MsgC( colors.darkgrey, "[GLuaTest] " )
    MsgC( ... )
end

local function drawLine( content, lineNumber )
    --
    -- Draws a line of code in the Context Block
    --
    MsgC( colors.grey, string.rep( " ", 4 - #lineNumber ) )
    MsgC( colors.white, lineNumber, " " )
    MsgC( colors.grey, "| ", content )
end

local function drawFailingLine( content, lineNumber, divider, reason )
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

    drawLine( content, lineNumber )

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

local function logCodeContext( errInfo )
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
            drawFailingLine( lineContent, lineNumStr, divider, reason )
        else
            drawLine( lineContent, lineNumStr )
            MsgC( "\n" )
        end
    end

    MsgC( colors.grey,  "     |", divider, "\n" )
end

local function logLocals( errInfo )
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

local function logFailedTest( errInfo )
    --
    -- Draw information about a given test failure
    --
    local sourceFile = errInfo.sourceFile

    MsgC( colors.white, "    File:", "\n" )
    MsgC( colors.grey,  "       ", sourceFile, "\n\n" )

    logLocals( errInfo )
    logCodeContext( errInfo )
end

function ResultLogger.logFileStart( name )
    prefixLog( colors.blue, "Starting tests cases from: [", name , "]...", "\n" )
end

function ResultLogger.LogTestResults( results )
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

        MsgC( colors.grey, "[" )
        MsgC( colors.white, case.name )
        MsgC( colors.grey, "]" )

        if not success then
            MsgC( "\n" )

            -- If the error came through without a source line,
            -- we'll use the function definition
            if not errInfo.sourceFile then
                local debugInfo = debug.getinfo( case.func )
                errInfo.sourceFile = debugInfo.short_src
                errInfo.lineNumber = debugInfo.linedefined
            end

            logFailedTest( errInfo )
        end

        hook.Run( "GLuaTest_LoggedTestResult", success, result, case, errInfo )
        MsgC( "\n" )
    end
end

return ResultLogger
