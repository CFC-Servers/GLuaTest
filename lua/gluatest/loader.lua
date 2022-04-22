local istable = istable

local function getTestsInDir( dir, tests )
    if not tests then tests = {} end
    local files, dirs = file.Find( "*.lua", dir )

    for _, fileName in ipairs( files ) do
        local fileOutput = include( dir .. "/" .. fileName )
        if istable( fileOutput ) then
            table.insert( tests, fileOutput )
        end
    end

    for _, dirName in ipairs( dirs ) do
        getTestsInDir( tests, dir .. "/" .. dirName )
    end

    return tests
end

return getTestsInDir
