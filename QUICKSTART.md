# Quickstart

Okay, okay, I get it. You're a big strong engineer and you don't need a README.

Here's the bare minimum you need to get started


## Setup

### 1. Create a new branch on your project
### 2. Create a new directory in your project, `lua/tests/project_name/`
### 3. Open your first test file, `lua/tests/project_name/main.lua`

Create the basic test structure:
```lua
-- lua/tests/project_name/main.lua

return {
    groupName = "MyProject",
    cases = {
        {
            name = "Should create project tables",
            func = function()
                expect( MyProject ).to.exist()
            end
        },
        {
            name = "Should not load modules automatically",
            func = function()
                expect( MyProject.Modules ).to.beNil()
            end
        }
    }
}
```
 - **[Here's a list](https://github.com/CFC-Servers/GLuaTest/blob/main/README.md#the-test-group) of the keys the outermost table (the "Test Group") accepts**
 - **[Here's a list](https://github.com/CFC-Servers/GLuaTest/blob/main/README.md#the-test-case) of the keys the items inside of the `cases` table (the "Test Cases") accept**
 - **There are a number of different [expectations](https://github.com/CFC-Servers/GLuaTest/blob/main/README.md#expectations) you can use inside of your test functions**

_Sidenote: There are a lot of ways to structure the test file. Play around with some different methods to see what works for you!_

### 4. Add the GitHub Workflow to `.github/workflows/gluatest.yml`:
```yml
name: GLuaTest Runner

on:
  pull_request:

jobs:
  run-tests:
    uses: CFC-Servers/GLuaTest/.github/workflows/run_tests.yml@main

    # The entire 'with' block and every item in it are optional
    with:
        # Relative path to a supplemental startup config file for the test server
        server-cfg: lua/tests/my_project/test.cfg

        # Relative path to a text file with your dependencies
        #  Example contents:
        #   CFC-Servers/logger@lua
        #   FPtje/DarkRP
        requirements: lua/tests/my_project/deps.txt

        # The gamemode for the test server to run (defaults to sandbox)
        gamemode: darkrp

        # Workshop collection ID
        collection: 1234

        # Passwordless Private key with access to your private requirements
        ssh-private-key: "${{ secrets.GLUATEST_PRIVATE_KEY }}"

        # A GitHub Personal Access Token with access to your private requirements
        github-token: "${{ secrets.GLUATEST_TOKEN }}"
```

### 5. Commit your changes, push your branch, and open a new PR



That's it! You have a working automated test runner for your project.

Check out the README for more details about [before/after functions](https://github.com/CFC-Servers/GLuaTest/blob/main/README.md#before--after-functions) and [how to make async tests](https://github.com/CFC-Servers/GLuaTest/blob/main/README.md#async-tests-and-the-done-function).
