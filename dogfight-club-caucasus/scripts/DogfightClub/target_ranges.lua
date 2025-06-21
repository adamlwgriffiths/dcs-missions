local TargetRanges = {}

for _, zone in ipairs(ZONE:FindAllByMatching("^Target Range.+")) do
    local Range = RANGE:New(zone:GetName())

    -- lua patterns are trash and cannot match the literal "-" so just match anything like an idiot
    local strafe_pits       = STATIC:FindAllByMatching(zone:GetName() .. " Strafe Pit.+")
    local static_targets    = STATIC:FindAllByMatching(zone:GetName() .. " Static Target.+")
    local moving_targets    = UNIT:FindAllByMatching(zone:GetName() .. " Moving Target.+")

    Range:SetRangeZone(zone)

    Range:SetScoreBombDistance(200)
    Range:SetDefaultPlayerSmokeBomb(true)
    Range:SetRangeControl(260)
    Range:SetInstructorRadio(270)
    Range:SetMessagesON()

    if strafe_pits and #strafe_pits > 0 then
        for _, obj in ipairs(strafe_pits) do
            -- invert the strafe pit direction
            Range:AddStrafePit(obj:GetName(), nil, nil, nil, true)
        end
    end

    if static_targets and #static_targets > 0 then
        for _, obj in ipairs(static_targets) do
            Range:AddBombingTargets(obj:GetName())
        end
    end

    if moving_targets and #moving_targets > 0 then
        for _, obj in ipairs(moving_targets) do
            Range:AddBombingTargets(obj:GetName())
        end
    end

    Range:Start()

    table.insert(TargetRanges, Range)
end
