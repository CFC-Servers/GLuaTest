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
            callCount = 0,
            callHistory = {},
            restored = false,
            Restore = function( self )
                if not original then return end
                if self.restored then return end

                self.restored = true
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
                end

                return rawget( self, idx )
            end,

            __call = function( ... )
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
