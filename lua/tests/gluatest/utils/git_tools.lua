local GitTools = include( "gluatest/utils/git_tools.lua" )

local MAIN_COMMIT = "0baf4b89aecb4d76c12898dea00482eabaa989bd"

--- @param gitFiles table<string, string> File contents, keyed by their path within .git
--- @return fun( path: string ): string?
local function readFrom( gitFiles )
    return function( path )
        local gitPath = string.match( path, "%.git/(.+)$" )
        return gitFiles[gitPath]
    end
end

return {
    groupName = "GitTools.getClonedInfo",

    cases = {
        {
            name = "Reads a clone that has never been fetched",
            func = function()
                stub( file, "Read" ).with( readFrom( {
                    ["HEAD"] = "ref: refs/heads/main\n",
                    ["config"] = "[remote \"origin\"]\n\turl = https://github.com/CFC-Servers/GLuaTest\n\tfetch = +refs/heads/*:refs/remotes/origin/*\n",
                    ["refs/heads/main"] = MAIN_COMMIT .. "\n",
                } ) )

                expect( GitTools.getClonedInfo() ).to.equal( "github.com/CFC-Servers/GLuaTest@main#0baf4b8" )
            end
        },

        {
            name = "Reads the commit from packed-refs and cleans an SSH remote url",
            func = function()
                stub( file, "Read" ).with( readFrom( {
                    ["HEAD"] = "ref: refs/heads/feature/runner-improvement\n",
                    ["config"] = "[remote \"origin\"]\n\turl = git@github.com:CFC-Servers/GLuaTest.git\n",
                    ["packed-refs"] = "# pack-refs with: peeled fully-peeled sorted \n"
                        .. "30ffc8e3eb019948ebd71c4ccfba27616b0da056 refs/heads/main\n"
                        .. MAIN_COMMIT .. " refs/heads/feature/runner-improvement\n",
                } ) )

                expect( GitTools.getClonedInfo() ).to.equal( "github.com/CFC-Servers/GLuaTest@feature/runner-improvement#0baf4b8" )
            end
        },

        {
            name = "Reports only the commit when no branch is checked out",
            func = function()
                stub( file, "Read" ).with( readFrom( {
                    ["HEAD"] = MAIN_COMMIT .. "\n",
                    ["config"] = "[remote \"origin\"]\n\turl = https://github.com/CFC-Servers/GLuaTest\n",
                } ) )

                expect( GitTools.getClonedInfo() ).to.equal( "github.com/CFC-Servers/GLuaTest#0baf4b8" )
            end
        },

        {
            name = "Removes credentials from the remote url",
            func = function()
                stub( file, "Read" ).with( readFrom( {
                    ["HEAD"] = MAIN_COMMIT .. "\n",
                    ["config"] = "[remote \"origin\"]\n\turl = https://someone:secret-token@github.com/CFC-Servers/GLuaTest.git\n",
                } ) )

                expect( GitTools.getClonedInfo() ).to.equal( "github.com/CFC-Servers/GLuaTest#0baf4b8" )
            end
        },

        {
            name = "Labels the commit as unknown when the branch has no readable commit",
            func = function()
                stub( file, "Read" ).with( readFrom( {
                    ["HEAD"] = "ref: refs/heads/main\n",
                    ["config"] = "[remote \"origin\"]\n\turl = https://github.com/CFC-Servers/GLuaTest\n",
                } ) )

                expect( GitTools.getClonedInfo() ).to.equal( "github.com/CFC-Servers/GLuaTest@main#<unknown commit>" )
            end
        },

        {
            name = "Returns nil when GLuaTest is not a git clone",
            func = function()
                stub( file, "Read" ).with( readFrom( {} ) )

                expect( GitTools.getClonedInfo() ).to.beNil()
            end
        },
    }
}
