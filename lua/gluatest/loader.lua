local istable = istable

local function getTestsInDir( dir, tests )
    if not tests then tests = {} end
    print(dir, #tests)

    local files, dirs = file.Find( dir .. "/*.lua", "LUA" )
    PrintTable( files )
    PrintTable( dirs )

    for _, fileName in ipairs( files ) do
        print(dir, fileName)

        local fileOutput = include( dir .. "/" .. fileName )
        if istable( fileOutput ) then
            table.insert( tests, { fileName = fileName, cases = fileOutput } )
        end
    end

    for _, dirName in ipairs( dirs ) do
        print( dir, dirName )
        getTestsInDir( tests, dir .. "/" .. dirName )
    end

    return tests
end

return getTestsInDir
