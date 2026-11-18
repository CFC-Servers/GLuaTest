--- @type GitTools
local GitTools = include( "git_tools.lua" )

--- @class VersionTools
local VersionTools = {}

local RELEASE_VERSION_FILE = "data_static/gluatest_version.txt"

--- Reads the version written into the docker image
--- @return string?
local function readReleaseVersion()
    if not file.Exists( RELEASE_VERSION_FILE, "GAME" ) then return nil end

    local versionContents = file.Read( RELEASE_VERSION_FILE, "GAME" )
    return string.Trim( versionContents )
end

--- Attempts the read the version of GLuaTest
--- First checks data_static/gluatest_version.txt (when running in docker)
--- Then, attempts to read the git commit of the cloned GLuaTest repository
--- Then, gives up
function VersionTools.getVersion()
    return readReleaseVersion() or GitTools.getClonedInfo() or "unknown"
end

--- The version sent in the usage ping
--- A cloned GLuaTest reports only its commit, without the name of its repository or branch
function VersionTools.getAnonymousVersion()
    local releaseVersion = readReleaseVersion()
    if releaseVersion then return releaseVersion end

    local clonedInfo = GitTools.getClonedInfo()
    if not clonedInfo then return "unknown" end

    -- "github.com/CFC-Servers/GLuaTest@main#6679969"
    local commit = string.match( clonedInfo, "#(%x+)$" )
    if not commit then return "clone" end

    return "clone#" .. commit
end

return VersionTools
