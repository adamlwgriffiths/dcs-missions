Fox = FOX:New()

--Fox:SetDefaultLaunchAlerts(false)
--Fox:SetDefaultLaunchMarks(false)
--Fox:SetDisableF10Menu(true)
Fox:SetExplosionDistance(100)
Fox:SetExplosionDistanceBigMissiles(200)

for _, zone in ipairs(ZONE:FindAllByMatching("FOX Zone.+")) do
    Fox:AddSafeZone(zone)
end

Fox:Start()
