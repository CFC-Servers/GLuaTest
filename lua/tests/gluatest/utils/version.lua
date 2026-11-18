local VersionTools = include( "gluatest/utils/version.lua" )

local CLONED_GIT_FILES = {
    ["HEAD"] = "ref: refs/heads/main\n",
    ["config"] = "[remote \"origin\"]\n\turl = https://github.com/someone/private-fork\n",
    ["refs/heads/main"] = "0baf4b89aecb4d76c12898dea00482eabaa989bd\n",
}

--- @param releaseVersion string? The contents of the version file in the docker image
--- @param gitFiles table<string, string> File contents, keyed by their path within .git
--- @return fun( path: string ): string?
local function readFrom( releaseVersion, gitFiles )
    return function( path )
        if path == "data_static/gluatest_version.txt" then return releaseVersion end

        local gitPath = string.match( path, "%.git/(.+)$" )
        return gitFiles[gitPath]
    end
end

return {
    groupName = "VersionTools",

    cases = {
        {
            name = "Reports the version written into the docker image",
            func = function()
                stub( file, "Exists" ).returns( true )
                stub( file, "Read" ).with( readFrom( "0.38.0\n", CLONED_GIT_FILES ) )

                expect( VersionTools.getVersion() ).to.equal( "0.38.0" )
                expect( VersionTools.getAnonymousVersion() ).to.equal( "0.38.0" )
            end
        },

        {
            name = "Reports the repository, branch, and commit of a clone",
            func = function()
                stub( file, "Exists" ).returns( false )
                stub( file, "Read" ).with( readFrom( nil, CLONED_GIT_FILES ) )

                expect( VersionTools.getVersion() ).to.equal( "github.com/someone/private-fork@main#0baf4b8" )
            end
        },

        {
            name = "Leaves the repository and branch of a clone out of the anonymous version",
            func = function()
                stub( file, "Exists" ).returns( false )
                stub( file, "Read" ).with( readFrom( nil, CLONED_GIT_FILES ) )

                expect( VersionTools.getAnonymousVersion() ).to.equal( "clone#0baf4b8" )
            end
        },

        {
            name = "Reports unknown without a version file or a clone",
            func = function()
                stub( file, "Exists" ).returns( false )
                stub( file, "Read" ).with( readFrom( nil, {} ) )

                expect( VersionTools.getVersion() ).to.equal( "unknown" )
                expect( VersionTools.getAnonymousVersion() ).to.equal( "unknown" )
            end
        },
    }
}
