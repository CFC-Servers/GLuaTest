local LogHelpers = include( "gluatest/runner/log_helpers.lua" )

-- Define getFileLines locally for testing
local getFileLines = LogHelpers.getFileLines

-- Temporary fileLinesCache for test isolation
local function makeFakeCache()
    return {
        cache = {},
        get = function( self, key ) return self.cache[key] end,
        set = function( self, key, value ) self.cache[key] = value end
    }
end

local function fakeFileOpenResponse( read, size )
    return {
        Read = function() return read end,
        Size = function() return size end,
        Close = function() end
    }
end

-- We need this for getFileLines because LuaLS loves to complain even though expect( lines ).toNot.beNil() checks for it!
---@diagnostic disable: need-check-nil
return {
    groupName = "LogHelpers.getFileLines Tests",

    beforeEach = function()
        LogHelpers.fileLinesCache = makeFakeCache()
    end,

    cases = {
        {
            name = "Reads file and returns lines",
            func = function()
                local filePath = "addons/testaddon/lua/tests/sample.txt"

                stub( file, "Open" ).returns(
                    fakeFileOpenResponse( "Line1\nLine2\nLine3", 14 )
                )

                local lines = getFileLines( filePath )
                expect( lines ).toNot.beNil()
                expect( #lines ).to.equal( 3 )
                expect( lines[1] ).to.equal( "Line1" )
                expect( lines[2] ).to.equal( "Line2" )
                expect( lines[3] ).to.equal( "Line3" )
            end
        },
        {
            name = "Returns cached lines on second read",
            func = function()
                local filePath = "addons/testaddon/lua/tests/sample.txt"

                local fileStub = stub( file, "Open" ).returns(
                    fakeFileOpenResponse( "CachedLine1\nCachedLine2", 19 )
                )

                -- First call should open the file
                local initialLines = getFileLines( filePath )
                expect( initialLines ).toNot.beNil()
                expect( #initialLines ).to.equal( 2 )
                expect( initialLines[1] ).to.equal( "CachedLine1" )
                expect( initialLines[2] ).to.equal( "CachedLine2" )
                expect( fileStub ).was.called()

                fileStub:Restore()
                fileStub = stub( file, "Open" ).returns(
                    fakeFileOpenResponse( "CachedLine1\nCachedLine2", 19 )
                )

                -- Second call should use cache and not invoke file.Open
                local cachedLines = getFileLines( filePath )
                expect( cachedLines ).toNot.beNil()
                expect( #cachedLines ).to.equal( 2 )
                expect( cachedLines[1] ).to.equal( "CachedLine1" )
                expect( cachedLines[2] ).to.equal( "CachedLine2" )
                expect( fileStub ).wasNot.called()
            end
        },
        {
            name = "Handles single line file correctly",
            func = function()
                local filePath = "addons/testaddon/lua/tests/single_line.txt"

                stub( file, "Open" ).returns(
                    fakeFileOpenResponse( "SingleLineContent", 16 )
                )

                local lines = getFileLines( filePath )
                expect( lines ).toNot.beNil()
                expect( #lines ).to.equal( 1 )
                expect( lines[1] ).to.equal( "SingleLineContent" )
            end
        },
        {
            name = "Handles empty file correctly",
            func = function()
                local filePath = "addons/testaddon/lua/tests/empty.txt"

                stub( file, "Open" ).returns(
                    fakeFileOpenResponse( "", 0 )
                )

                local lines = getFileLines( filePath )
                expect( lines ).toNot.beNil()
                expect( #lines ).to.equal( 1 )
                expect( lines[1] ).to.equal( "" )
            end
        },
        {
            name = "Errors on non-existent file",
            func = function()
                local filePath = "addons/testaddon/lua/tests/non_existent.txt"

                stub( file, "Open" ).returns( nil )

                local lines = getFileLines( filePath )
                expect( lines ).to.beNil()
            end
        }
    }
}
