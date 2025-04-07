--- @type GitTools
local GitTools = include( "git_tools.lua" )

--- @class VersionTools
local VersionTools = {}

--- Attempts the read the version of GLuaTest
--- First checks data_static/gluatest_version.txt (when running in docker)
--- Then, attempts to read the git commit of the cloned GLuaTest repository
--- Then, gives up
function VersionTools.getVersion()
    local version = "unknown"

    if file.Exists( "data_static/gluatest_version.txt", "DATA" ) then
        local file = file.Read( "data_static/gluatest_version.txt", "DATA" )
        version = string.Trim( file )
    else
        -- See if it's cloned into the addons folder
        local clonedInfo = GitTools.getClonedInfo()
        if clonedInfo then version = clonedInfo end
    end

    return version
end

return VersionTools
