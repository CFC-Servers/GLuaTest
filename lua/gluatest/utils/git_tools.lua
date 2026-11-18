--- @class GitTools
local GitTools = {}

local SHORT_COMMIT_LENGTH = 7

--- Returns the name of the addon directory we're running from
function GitTools.whereAmI()
    -- addons/cfc_err_forwarder/lua/autorun/server/cfc_err_fwd.lua
    local path = debug.getinfo( 1, "S" ).short_src

    -- { "addons", "cfc_err_forwarder", "lua", "autorun", "server", "cfc_err_fwd.lua" }
    local spl = string.Split( path, "/" )

    local addonName = spl[2]
    return addonName
end

--- @param addonName string The name of the addon directory
--- @param path string The path to the file within .git
--- @return string? The file contents, or nil if it could not be read
local function readGitFile( addonName, path )
    -- "addons/gluatest/.git/refs/heads/feature/runner-improvement"
    return file.Read( "addons/" .. addonName .. "/.git/" .. path, "GAME" )
end

--- @param commit string
--- @return string
local function shortenCommit( commit )
    return string.sub( commit, 1, SHORT_COMMIT_LENGTH )
end

--- @param remoteUrl string
--- @return string
local function getRepoName( remoteUrl )
    -- "https://github.com/CFC-Servers/GLuaTest.git" or "git@github.com:CFC-Servers/GLuaTest.git"
    local repo = string.Trim( remoteUrl )
    repo = string.gsub( repo, "^%a+://", "" )
    repo = string.gsub( repo, "^[^/]*@", "" )
    repo = string.gsub( repo, ":", "/" )
    repo = string.gsub( repo, "%.git$", "" )

    -- "github.com/CFC-Servers/GLuaTest"
    return repo
end

--- Attempts to get the commit of a given branch from .git/<refPath>, or from .git/packed-refs
--- @param addonName string The name of the addon directory
--- @param refPath string The path to the reference file within .git
--- @return string? The commit hash, or nil if it could not be read
function GitTools.getCommit( addonName, refPath )
    -- 6181553d068c4fc4da00d6ef99e7ebb2b59e3126
    local looseRef = readGitFile( addonName, refPath )
    if looseRef then return string.Trim( looseRef ) end

    local packedRefs = readGitFile( addonName, "packed-refs" )
    if not packedRefs then return nil end

    -- 6181553d068c4fc4da00d6ef99e7ebb2b59e3126 refs/heads/feature/runner-improvement
    for commit, packedRefPath in string.gmatch( packedRefs, "(%x+) ([^\r\n]+)" ) do
        if packedRefPath == refPath then return commit end
    end

    return nil
end

--- Attempts to get the url of the first remote listed in .git/config
--- @param addonName string The name of the addon directory
--- @return string? The remote url, or nil if it could not be read
function GitTools.getRemoteUrl( addonName )
    local config = readGitFile( addonName, "config" )
    if not config then return nil end

    -- url = https://github.com/CFC-Servers/GLuaTest
    return string.match( config, "url = ([^\r\n]+)" )
end

--- Attempts to get the url, branch, and commit of a cloned GLuaTest repo
--- @return string?
function GitTools.getClonedInfo()
    local addonName = GitTools.whereAmI()

    -- "ref: refs/heads/feature/runner-improvement", or a commit hash when no branch is checked out
    local head = readGitFile( addonName, "HEAD" )
    if not head then return nil end
    head = string.Trim( head )

    local remoteUrl = GitTools.getRemoteUrl( addonName )
    if not remoteUrl then return nil end

    local repo = getRepoName( remoteUrl )

    -- "refs/heads/feature/runner-improvement"
    local refPath = string.match( head, "^ref: (.+)$" )
    if not refPath then
        -- "github.com/CFC-Servers/GLuaTest#6679969"
        return string.format( "%s#%s", repo, shortenCommit( head ) )
    end

    -- "feature/runner-improvement"
    local branch = string.gsub( refPath, "^refs/heads/", "" )

    local commit = GitTools.getCommit( addonName, refPath )
    local commitLabel = commit and shortenCommit( commit ) or "<unknown commit>"

    -- "github.com/CFC-Servers/GLuaTest@main#6679969"
    return string.format( "%s@%s#%s", repo, branch, commitLabel )
end

return GitTools
