local colors = {
    red = Color( 255, 0, 0 ),
    green = Color( 0, 255, 0 ),
    grey = Color( 136, 151, 158 ),
    darkgrey = Color( 85, 85, 85 ),
    yellow = Color( 235, 226, 52 ),
    white = Color( 220, 220, 220 ),
    blue = Color( 120, 162, 204 )
}

if CLIENT then
    -- The default darkgrey is too dark for gmod terminal
    colors.darkgrey = Color( 125, 125, 125 )
end

return colors
