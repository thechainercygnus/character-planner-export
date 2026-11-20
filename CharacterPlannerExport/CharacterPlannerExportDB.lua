local ADDON = ...
local regions = { US = true, EU = true, KR = true, TW = true }
local bankOpen = false
local pendingBagItem, pendingBankItem

local function CollectCharacter()
    -- On Forever, UnitName's second return is the surname.
    local name, surname = UnitName("player")
    local level = UnitLevel("player")
    if not name or name == "" or level < 1 then return end

    local region = GetCurrentRegionName and GetCurrentRegionName()
    local realm = GetRealmName()
    return {
        name = name,
        surname = surname ~= "" and surname or nil,
        level = level,
        region = regions[region] and region or nil,
        realm = realm ~= "" and realm or nil,
    }
end

local function CollectItems(containers, isBank)
    local items = {}
    for _, container in ipairs(containers) do
        local slots = C_Container.GetContainerNumSlots(container)
        if not slots or (slots == 0 and (isBank or container == 0)) then return end
        for slot = 1, slots do
            local info = C_Container.GetContainerItemInfo(container, slot)
            if info then
                if not info.itemID or info.itemID < 1 or not info.stackCount
                    or info.stackCount < 1 or not info.quality or info.quality < 0 then
                    -- Keep the previous snapshot and retry when this item loads.
                    local itemID = info.itemID
                    if not itemID or itemID < 1 then
                        itemID = C_Container.GetContainerItemID(container, slot)
                    end
                    return nil, itemID
                end
                items[#items + 1] = {
                    container = container,
                    slot = slot,
                    itemId = info.itemID,
                    count = info.stackCount,
                    quality = info.quality,
                }
            end
        end
    end
    return { capturedAt = GetServerTime(), items = items }
end

local function CollectBags()
    local containers = {}
    local lastBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS
    for bag = 0, lastBag do
        containers[#containers + 1] = bag
    end
    return CollectItems(containers)
end

local function CollectBank()
    local bankType = Enum.BankType.Character
    if C_Bank.CanViewBank and not C_Bank.CanViewBank(bankType) then return end

    local containers = {}
    local tabs = C_Bank.FetchPurchasedBankTabData(bankType)
    if not tabs then return end
    for _, tab in ipairs(tabs) do
        containers[#containers + 1] = tab.ID
    end
    return CollectItems(containers, true)
end

local function CollectQuests()
    local log = {}
    local entries = C_QuestLog.GetNumQuestLogEntries()
    for index = 1, entries do
        local info = C_QuestLog.GetInfo(index)
        if not info then return end
        if not info.isHeader then
            local questId = info.questID
            if not questId or questId <= 0 or not info.title then return end

            local objectives = {}
            local source = C_QuestLog.GetQuestObjectives(questId)
            if not source and C_QuestLog.GetNumQuestObjectives(questId) ~= 0 then return end
            for _, objective in ipairs(source or {}) do
                objectives[#objectives + 1] = {
                    text = objective.text,
                    type = objective.type,
                    done = objective.numFulfilled,
                    needed = objective.numRequired,
                    finished = objective.finished,
                }
            end
            log[#log + 1] = {
                questId = questId,
                title = info.title,
                complete = C_QuestLog.ReadyForTurnIn(questId) == true,
                objectives = objectives,
            }
        end
    end

    local completed
    local ids = C_QuestLog.GetAllCompletedQuestIDs and C_QuestLog.GetAllCompletedQuestIDs()
    if ids then
        completed = {}
        for _, questId in ipairs(ids) do
            if questId > 0 then
                completed[#completed + 1] = questId
            end
        end
        table.sort(completed)
    end
    return { capturedAt = GetServerTime(), log = log, completed = completed }
end

local function SaveSection(key, snapshot)
    if not snapshot then return end
    local db = CharacterPlannerExportDB
    db[key] = snapshot
    db.capturedAt = math.max(
        db.bags and db.bags.capturedAt or 0,
        db.bank and db.bank.capturedAt or 0,
        db.quests and db.quests.capturedAt or 0
    )
end

local function SaveBags()
    local snapshot
    snapshot, pendingBagItem = CollectBags()
    SaveSection("bags", snapshot)
end

local function SaveBank()
    local snapshot
    snapshot, pendingBankItem = CollectBank()
    SaveSection("bank", snapshot)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("BANKFRAME_OPENED")
frame:RegisterEvent("BANKFRAME_CLOSED")
frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
frame:RegisterEvent("BANK_TABS_CHANGED")
frame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("QUEST_DATA_LOAD_RESULT")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON then return end
        if type(CharacterPlannerExportDB) ~= "table" or CharacterPlannerExportDB.schemaVersion ~= 1 then
            CharacterPlannerExportDB = {}
        end
        CharacterPlannerExportDB.schemaVersion = 1
        CharacterPlannerExportDB.addonVersion = C_AddOns.GetAddOnMetadata(ADDON, "Version")
        self:UnregisterEvent("ADDON_LOADED")
        return
    end

    local db = CharacterPlannerExportDB
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGOUT" then
        db.character = CollectCharacter() or db.character
        SaveBags()
        SaveSection("quests", CollectQuests())
        if bankOpen then SaveBank() end
        -- A character-only export still needs a timestamp if both reads are pending.
        db.capturedAt = db.capturedAt or GetServerTime()
    elseif event == "PLAYER_LEVEL_UP" then
        local level = ...
        if db.character then db.character.level = level end
    elseif event == "BANKFRAME_CLOSED" then
        bankOpen = false
        pendingBankItem = nil
    elseif event == "BANKFRAME_OPENED" then
        bankOpen = true
        SaveBank()
    elseif event == "BAG_UPDATE_DELAYED" then
        SaveBags()
        if bankOpen then SaveBank() end
    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local itemID, success = ...
        if not success or not itemID then return end
        if itemID == pendingBagItem then SaveBags() end
        if bankOpen and itemID == pendingBankItem then SaveBank() end
    elseif event == "PLAYERBANKSLOTS_CHANGED" or event == "BANK_TABS_CHANGED" then
        if bankOpen then SaveBank() end
    elseif event == "QUEST_LOG_UPDATE" or event == "QUEST_TURNED_IN" or event == "QUEST_DATA_LOAD_RESULT" then
        SaveSection("quests", CollectQuests())
    end
end)
