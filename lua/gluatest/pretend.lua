-- Q: What do we do if two async tests in the same file need to mock the same function?
--


local function setup()
    -- =======================================
    --
    -- local mockTime = setup( os.time )
    --
    -- mockTime.returns( 0 )
    -- -- or
    -- stub( mockTime ).with(function()
    --     return 0
    -- end )
    --
    -- doStuff()
    --
    -- expect( #mockTime.calls ).to.eq( 1 )
    --
    -- =======================================
    --
    -- local mockBan = setup( ULib.ban )
    --
    -- local ply = make( "player" )
    -- maybeBanPlayer( ply )
    --
    -- expect( mockBan ).to.haveBeenCalledWith( ply, 100, "Loser idiot" )
    -- expect( #mockTime.calls ).to.eq( 1 )
    --
    -- =======================================
    --
    -- local mockBan = setup( ULib.ban )
    --
    -- local ply = make( "player" )
    -- dontBanPlayer( ply )
    --
    -- expect( #mockBan.calls ).to.eq( 0 )
    --
    -- =======================================
end
