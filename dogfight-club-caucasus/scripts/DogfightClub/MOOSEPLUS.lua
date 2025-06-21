-- shit thats missing in moose
function ZONE:FindAllByMatching(Pattern)
    local Matches = {}

    for name, obj in pairs(_DATABASE.ZONES) do
        if string.match(name, Pattern) then
            Matches[#Matches+1] = obj
        end
    end

    return Matches
end