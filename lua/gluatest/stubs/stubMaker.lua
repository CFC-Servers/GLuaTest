--- @alias StubFunction fun(tbl: table, key: any): GLuaTest_Stub
--- @alias GLuaTest_StubMaker fun(): StubFunction, fun()

return function()
    --- @type GLuaTest_Stub[]
    local stubs = {}

    --- Cleans up all stubs created by this stub maker
    local function cleanup()
        for _, stub in ipairs( stubs ) do
            if not stub.restored then
                stub:Restore()
            end
        end
    end

    --- @param tbl table
    --- @param key any
    return function( tbl, key )
        local original = tbl and tbl[key]

        --- @class GLuaTest_Stub
        --- @field stubbedFunc? function
        local stubTbl = {
            --- Identifies this object as a stub
            --- @type true
            IsStub = true,

            --- How many times this stub has been called
            callCount = 0,

            --- The arguments passed to this stub for each call
            --- @type any[][]
            callHistory = {},

            --- Whether this stub has been restored
            --- @type boolean
            restored = false
        }

        --- Restores the original function
        function stubTbl:Restore()
            if self.restored then return end
            self.restored = true

            if not tbl then return end
            tbl[key] = original
        end

        --- Stubs the function with the provided function
        function stubTbl.with( func )
            assert( stubTbl.stubbedFunc == nil, "Stub already set" )

            stubTbl.stubbedFunc = func
            return stubTbl
        end

        --- Stubs the function to return the provided value(s)
        --- @vararg any
        function stubTbl.returns( ... )
            assert( stubTbl.stubbedFunc == nil, "Stub already set" )

            local args = { ... }
            stubTbl.stubbedFunc = function()
                return unpack( args )
            end

            return stubTbl
        end

        --- Stubs the function to progresively return the provided values as it is called
        --- @param sequence any[] The sequence of values to return in order as the function is called
        --- @param default? any The value to return if the sequence is exhausted
        function stubTbl.returnsSequence( sequence, default )
            assert( stubTbl.stubbedFunc == nil, "Stub already set" )
            assert( type( sequence ) == "table", "Sequence must be a table" )

            stubTbl.stubbedFunc = function()
                local ret = sequence[stubTbl.callCount]
                if ret == nil then return default end

                return ret
            end

            return stubTbl
        end

        local meta = {
            __name = "GLuaTest::Stub",

            __call = function( _, ... )
                stubTbl.callCount = stubTbl.callCount + 1
                table.insert( stubTbl.callHistory, { ... } )

                if stubTbl.stubbedFunc then
                    return stubTbl.stubbedFunc( ... )
                end

                return nil
            end,

            __tostring = function()
                local base = "GLuaTest::Stub"
                if original then
                    base = base .. " (" .. key .. ")"
                end

                return base
            end
        }

        hook.Run( "GLuaTest_CreateStub", stubTbl, meta, tbl, key )

        local stub = setmetatable( stubTbl, meta )

        table.insert( stubs, stub )
        if tbl then tbl[key] = stub end

        return stub
    end, cleanup
end
