# Foothold

PvE persistent dynamic sandbox

Source:
* [https://www.digitalcombatsimulator.com/en/files/3319499/](Download)
* [https://forum.dcs.world/topic/289074-spcoop-pve-foothold-persistent-dynamic-sandbox/](Forum thread)

## Readme contents

Note for running this on dedicated servers:

For the slot blocking to work, you will need to copy the slotblock.lua file into the savegames folder on the server under Scripts/Hooks and restart.

---------------------------------------------------------------------------------------------------

Note on Persistance:

Persistance is also available in case you want to stop and resume the mission at a later time. The state is saved every minute, but only the color and number of upgrades of a zone are saved, meaning partially destroyed groups will respawn fully restored once the mission starts up again.

In order for persistance to work you will need to edit the following file in your DCS install directory: \Scripts\MissionScripting.lua

Edit the following section:
do
    sanitizeModule('os')
    sanitizeModule('io')
    sanitizeModule('lfs')
    _G['require'] = nil
    _G['loadlib'] = nil
    _G['package'] = nil
end
to look like this:
do
    sanitizeModule('os')
    --sanitizeModule('io')
    --sanitizeModule('lfs')
    _G['require'] = nil
    _G['loadlib'] = nil
    _G['package'] = nil
end

To reset the persistance and play the mission again from the start, delete the foothold_1.3.1.lua found in the DCS install directory.

