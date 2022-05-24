local Helpers = include( "gluatest/runner/log_helpers.lua" )
local GenerateDivider = Helpers.GenerateDivider
local GetLineWithContext = Helpers.GetLineWithContext
local GetLeadingWhitespace = Helpers.GetLeadingWhitespace
local NormalizeLinesIndent = Helpers.NormalizeLinesIndent

local colors = include( "gluatest/runner/colors.lua" )
local MsgC = include( "gluatest/runner/msgc_wrapper.lua" )

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

local function logTestCaseFailure( errInfo )
    --
    -- Draw information about a given test failure
    --
    local sourceFile = errInfo.sourceFile

    MsgC( colors.white, "    File:", "\n" )
    MsgC( colors.grey,  "       ", sourceFile, "\n\n" )

    logLocals( errInfo )
    logCodeContext( errInfo )
end

function ResultLogger.LogFileStart( testGroup )
    local fileName = testGroup.fileName
    local groupName = testGroup.groupName
    local project = testGroup.project

    local identifier = project .. "/" .. fileName
    if groupName then
        identifier = identifier .. ": " .. groupName
    end

    prefixLog( colors.blue, "Starting tests cases for: [", identifier , "]...", "\n" )
end

function ResultLogger.LogTestResult( result )
    local case = result.case
    local success = result.success

    if success then
        prefixLog( colors.green, "PASS " )
    else
        prefixLog( colors.red, "FAIL " )
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

    logTestCaseFailure( errInfo )
    hook.Run( "GLuaTest_LoggedTestFailure", errInfo )

    MsgC( "\n" )
end

function ResultLogger.LogTestsComplete()
    MsgC( "\n", "\n" )
    prefixLog( colors.white, "Test run complete! 🎉")
    MsgC( "\n" )
end

return ResultLogger