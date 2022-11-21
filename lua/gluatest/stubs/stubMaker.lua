return function()

    local stubs = {}

    local function cleanup()
        for _, stub in ipairs( stubs ) do
            if not stub.restored then
                stub:Restore()
            end
        end
    end

    return function( tbl, key )
        local original = tbl and tbl[key]

        local stubTbl = {
            IsStub = true,
            callCount = 0,
            callHistory = {},
            restored = false,
            Restore = function( self )
                if self.restored then return end
                self.restored = true

                if not tbl then return end
                tbl[key] = original
            end,
        }

        local meta = {
            __index = function( self, idx )
                local stubSet = rawget( self, "stubbedFunc" )

                if not stubSet then
                    if idx == "with" then
                        return function( func )
                            rawset( self, "stubbedFunc", func )
                            return self
                        end
                    end

                    if idx == "returns" then
                        return function( ... )
                            local args = { ... }

                            rawset( self, "stubbedFunc", function()
                                return unpack( args )
                            end )
                            return self
                        end
                    end

                    if idx == "returnsSequence" then
                        return function( sequence, default )
                            assert( type( sequence ) == "table", "Sequence must be a table" )

                            rawset( self, "stubbedFunc", function()
                                local ret = sequence[stubTbl.callCount]
                                if ret == nil then return default end
                                return ret
                            end )
                            return self
                        end
                    end
                end

                return rawget( self, idx )
            end,

            __call = function( _, ... )
                stubTbl.callCount = stubTbl.callCount + 1
                table.insert( stubTbl.callHistory, { ... } )

                if stubTbl.stubbedFunc then
                    return stubTbl.stubbedFunc( ... )
                end

                return nil
            end,

            __name = "GLuaTest::Stub",
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
