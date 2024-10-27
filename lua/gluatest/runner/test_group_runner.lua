-- case.when should evaluate to `true` if the test should run
-- case.skip should evaluate to `true` if the test should be skipped
-- (case.skip takes precedence over case.when)
local function checkShouldSkip( case )
    -- skip
    local skip = case.skip
    if skip == true then return true end
    if isfunction( skip ) then
        return skip() == true
    end

    -- when
    local condition = case.when
    if condition == nil then return false end
    if condition == false then return true end

    if isfunction( condition ) then
        return condition() ~= true
    end

    return condition ~= true
end

function GLuatest.TestGroupRunner( TestRunner )
    local TGR = {}

    TGR.state = {}
    TGR.asyncCases = {}

    function TGR:CanRunCase( case )
        local shouldSkip = checkShouldSkip( case )
        if shouldSkip then
            TestRunner:SetSkipped( case )
            return false
        end

        local canRun = hook.Run( "GLuaTest_CanRunTestCase", self.group, case )
        if canRun == nil then canRun = true end
        if not canRun then return false end

        -- Tests in the wrong realm will be hidden from output
        local shared = case.shared
        local clientside = case.clientside
        local serverside = not case.clientside
        local correctRealm = shared or ( clientside and CLIENT ) or ( serverside and SERVER )
        if not correctRealm then return false end

        return true
    end

    function TGR:ProcessCase( case )
        if not self:CanRunCase( case ) then return end

    end

    function TGR:RunGroup( group )
        self.group = group
        testGroup.beforeAll( self.state )
    end

    return TGR
end
