local ADDON = ...

local function CollectCharacterData()
    local name, surname = UnitName("player")

    local level = UnitLevel("player")

    local realm = nil
    if GetRealmID then
        realm = tostring(GetRealmID())
    end

    return {
        name = name,
        surname = surname,
        level = level,
        region = "US",
        realm = realm,
    }
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= ADDON then return end
        CharacterPlannerExportDB.schemaVersion =
            CharacterPlannerExportDB.schemaVersion or 1

        CharacterPlannerExportDB.addonVersion = "0.1.0"
        CharacterPlannerExportDB.character =
            CharacterPlannerExportDB.character or {}

        print("CharacterPlannerExport Loaded")
    elseif event == "PLAYER_LOGOUT" then
        CharacterPlannerExportDB.character = CollectCharacterData()
    end
end)
