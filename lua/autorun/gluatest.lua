if SERVER then
    include( "gluatest/init.lua" )
else
    if file.Exists( "gluatest/init.lua", "LUA" ) then
        include( "gluatest/init.lua" )
    end
end
