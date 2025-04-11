--- @class GitTools
local GitTools = {}

--- Returns the name of the addon directory we're running from
function GitTools.whereAmI()
    -- addons/cfc_err_forwarder/lua/autorun/server/cfc_err_fwd.lua
    local path = debug.getinfo( 1, "S" ).short_src

    -- { "addons", "cfc_err_forwarder", "lua", "autorun", "server", "cfc_err_fwd.lua" }
    local spl = string.Split( path, "/" )

    local addonName = spl[2]
    return addonName
end

--- Attempts to get the commit of a given branch by reading .git/<refPath>
--- @param addonName string The name of the addon directory
--- @param refPath string The path to the reference file within .git
--- @return string? The commit hash, or nil if it could not be read
function GitTools.getCommit( addonName, refPath )
    -- "addons/gluatest/.git/refs/heads/feature/runner-improvement"
    local fullPath = "addons/" .. addonName .. "/.git/" .. refPath

    -- 6181553d068c4fc4da00d6ef99e7ebb2b59e3126
    local refContent = file.Read( fullPath, "GAME" )

    return refContent
end

--- Attempts to get the url, branch, and commit of a cloned GLuaTest repo
--- @return string?
function GitTools.getClonedInfo()
    local addonName = GitTools.whereAmI()

    local headPath = "addons/" .. addonName .. "/.git/HEAD"
    -- ref: refs/heads/feature/runner-improvement
    local headContent = file.Read( headPath, "GAME" )
    if not headContent then return nil end

    -- "feature/runner-improvement"
    local currentBranch = string.Replace( headContent, "ref: refs/heads/", "" )
    currentBranch = string.Trim( currentBranch )

    -- "refs/heads/feature/runner-improvement"
    local currentRefPath = string.Replace( headContent, "ref: ", "" )
    currentRefPath = string.Trim( currentRefPath )

    -- Current status of all branches
    local fetchPath = "addons/" .. addonName .. "/.git/FETCH_HEAD"
    local fetchContent = file.Read( fetchPath, "GAME" )
    if not fetchContent then return nil end

    local branchLine = nil
    local fetchLines = string.Split( fetchContent, "\n" )
    for i = 1, #fetchLines do
        local line = fetchLines[i]
        if string.find( line, currentBranch, 1, true ) then
            -- 808ff35547ca8fd7efe50ef9a214fbd32b4dbefc        not-for-merge   branch 'feature/runner-improvement' of github.com:CFC-Servers/GLuaTest
            branchLine = line
            break
        end
    end
    if not branchLine then return nil end

    -- 808ff35547ca8fd7efe50ef9a214fbd32b4dbefc not-for-merge branch 'feature/runner-improvement' of github.com:CFC-Servers/GLuaTest
    branchLine = string.gsub( branchLine, "%s+", " " )

    -- "feature/runner-improvement", "github.com:CFC-Servers/GLuaTest"
    local _, _, branch, repo = string.find( branchLine, "branch '(.+)' of (.+)$" )
    if not branch or not repo then return end

    local commit = GitTools.getCommit( addonName, currentRefPath )
    if commit then
        -- Commit shortcode
        commit = string.sub( commit, 1, 7 )
    else
        commit = "<unknown commit>"
    end

    -- "github.com/CFC-Servers/GLuaTest"
    repo = string.gsub( repo, "https://", "" )
    repo = string.gsub( repo, "http://", "" )
    repo = string.gsub( repo, ":", "/" )
    repo = string.gsub( repo, ".git", "" )

    -- "github.com/CFC-Servers/GLuaTest@main#(6679969)"
    return string.format( "%s@%s#%s", repo, branch, commit )
end

return GitTools
