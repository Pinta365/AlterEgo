AlterEgo = {}

-- local function getTableSize(t)
--     local count = 0
--     for _, __ in pairs(t) do
--         count = count + 1
--     end
--     return count
-- end

local function dumpTable(table, depth)
    if depth == nil then
        depth = 5
    end
    if (depth > 200) then
      print("Error: Depth > 200 in dumpTable()")
      return
    end
    for k,v in pairs(table) do
      if (type(v) == "table") then
        print(string.rep("  ", depth)..k..":")
        dumpTable(v, depth+1)
      else
        print(string.rep("  ", depth)..k..": ",v)
      end
    end
  end

local Maps = {
    [206] = "NL",
    [245] = "FH",
    [251] = "UR",
    [403] = "UL",
    [404] = "NE",
    [405] = "BH",
    [406] = "HOI",
    [438] = "VP",
}

local rowHeight = 20
local colWidth = 120
local cellPadding = 4

local f = CreateFrame("Frame", "AlterEgoFrame", UIParent, "BackdropTemplate")
local backdropinfo = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
 	-- edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
 	tile = true,
 	tileEdge = true,
 	tileSize = 8,
 	edgeSize = 0,
 	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

f:SetPoint("CENTER")
f:SetSize(600, 600)
f:SetBackdrop(backdropinfo)
f:SetBackdropColor(0, 0, 0, 1)
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, ...)
    self[event](self, event, ...)
end
)

function f:ADDON_LOADED(event, addon)
    if addon == "AlterEgo" then

        C_MythicPlus.RequestMapInfo()

        local playerName, playerRealm = UnitName("player")
        local playerGUID = UnitGUID("player")
        local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
        local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
        local keyStoneLevel = C_MythicPlus.GetOwnedKeystoneLevel()
        -- local currentWeekBestLevel, weeklyRewardLevel, nextDifficultyWeeklyRewardLevel, nextBestLevel = C_MythicPlus.GetWeeklyChestRewardLevel()
        -- local rewardLevel = C_MythicPlus.GetRewardLevelFromKeystoneLevel(keyStoneLevel)
        -- local weeklyRewardAvailable = C_MythicPlus.IsWeeklyRewardAvailable()
        -- local history = C_MythicPlus.GetRunHistory(true)
        -- C_ChallengeMode.GetMapUIInfo(mapid)

        if keyStoneLevel == nil then
            keyStoneLevel = 0
        end

        if AlterEgoDB == nil then
            AlterEgoDB = {
                characters = {},
                settings = {}
            }
        end

        -- if AlterEgoDB.characters[playerGUID] == nil then
            AlterEgoDB.characters[playerGUID] = {
                name = playerName,
                realm = playerRealm,
                rating = ratingSummary.currentSeasonScore,
                ilvl = avgItemLevel,
                vault = {},
                key = {
                    map = mapID or "",
                    level = keyStoneLevel or 0
                },
                dungeons = {}
            }
        -- end

        for mid,_ in pairs(Maps) do
            local affixScores = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(mid)
            if affixScores ~= nil then
                dumpTable(affixScores)

                local fortified = 0
                local tyrannical = 0
                for i,affixScore in pairs(affixScores) do
                    if affixScore.name == "Fortified" then
                        fortified = affixScore.level
                    end
                    if affixScore.name == "Tyrannical" then
                        tyrannical = affixScore.level
                    end
                end

                AlterEgoDB.characters[playerGUID].dungeons[mid] = {
                    [1] = tyrannical,
                    [2] = fortified,
                }
            else
                AlterEgoDB.characters[playerGUID].dungeons[mid] = {
                    [1] = 0,
                    [2] = 0,
                }
            end
        end

        local activities = C_WeeklyRewards.GetActivities(1)
        for _, activity in pairs(activities) do
            AlterEgoDB.characters[playerGUID].vault[activity.index] = activity.level
        end

        AlterEgo:CreateFrames()
    end
end

function AlterEgo:GetCharacters()
    local characters = AlterEgoDB.characters

    -- Filters
    -- Sorting

    return characters
end

function AlterEgo:CreateFrames()
    local characters = AlterEgo:GetCharacters()

    local rowCharacterName = CreateFrame("Frame", f:GetName() .. "HeaderRow", f, "BackdropTemplate")
    rowCharacterName:SetSize(f:GetWidth(), rowHeight)
    rowCharacterName:SetPoint("TOPLEFT", f, "TOPLEFT")

    rowCharacterName.columns = {}
    rowCharacterName.columns[0] = CreateFrame("Frame", rowCharacterName:GetName() .. "COL0", rowCharacterName, "BackdropTemplate")
    rowCharacterName.columns[0]:SetSize(colWidth, rowHeight)
    rowCharacterName.columns[0]:SetPoint("TOPLEFT", rowCharacterName, "TOPLEFT")
    rowCharacterName.columns[0]:SetBackdrop(backdropinfo)
    rowCharacterName.columns[0]:SetBackdropColor(1, 0, 0, 1)
    rowCharacterName.columns[0].fontString = rowCharacterName.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rowCharacterName.columns[0].fontString:SetPoint("LEFT", rowCharacterName.columns[0], "LEFT", cellPadding, 0)
    rowCharacterName.columns[0].fontString:SetText("Characters:")
    rowCharacterName.columns[0].fontString:SetJustifyH("LEFT")

    local previousFrame = 0
    for playerGUID,character in pairs(characters) do
        rowCharacterName.columns[playerGUID] = CreateFrame("Frame", rowCharacterName:GetName() .. "COL" .. playerGUID, rowCharacterName, "BackdropTemplate")
        rowCharacterName.columns[playerGUID]:SetSize(colWidth, rowHeight)
        rowCharacterName.columns[playerGUID]:SetPoint("TOPLEFT", rowCharacterName.columns[previousFrame], "TOPRIGHT")
        rowCharacterName.columns[playerGUID]:SetBackdrop(backdropinfo)
        rowCharacterName.columns[playerGUID]:SetBackdropColor(1, 0, 0, 1)
        rowCharacterName.columns[playerGUID].fontString = rowCharacterName.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowCharacterName.columns[playerGUID].fontString:SetPoint("CENTER", rowCharacterName.columns[playerGUID], "CENTER", cellPadding, 0)
        rowCharacterName.columns[playerGUID].fontString:SetJustifyH("CENTER")
        rowCharacterName.columns[playerGUID].fontString:SetText(character.name)
        previousFrame = playerGUID
    end

    local rowRating = CreateFrame("Frame", f:GetName() .. "Rating", f, "BackdropTemplate")
    rowRating:SetSize(f:GetWidth(), rowHeight)
    rowRating:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -rowHeight)
    rowRating.columns = {}
    rowRating.columns[0] = CreateFrame("Frame", rowRating:GetName() .. "COL0", rowRating, "BackdropTemplate")
    rowRating.columns[0]:SetSize(colWidth, rowHeight)
    rowRating.columns[0]:SetPoint("TOPLEFT", rowRating, "TOPLEFT")
    rowRating.columns[0]:SetBackdrop(backdropinfo)
    rowRating.columns[0]:SetBackdropColor(1, 0, 0, 1)
    rowRating.columns[0].fontString = rowRating.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rowRating.columns[0].fontString:SetPoint("LEFT", rowRating.columns[0], "LEFT", cellPadding, 0)
    rowRating.columns[0].fontString:SetJustifyH("LEFT")
    rowRating.columns[0].fontString:SetText("Rating:")

    local previousFrame = 0
    for playerGUID,character in pairs(characters) do
        rowRating.columns[playerGUID] = CreateFrame("Frame", rowRating:GetName() .. "COL" .. playerGUID, rowRating, "BackdropTemplate")
        rowRating.columns[playerGUID]:SetSize(colWidth, rowHeight)
        rowRating.columns[playerGUID]:SetPoint("TOPLEFT", rowRating.columns[previousFrame], "TOPRIGHT")
        rowRating.columns[playerGUID]:SetBackdrop(backdropinfo)
        rowRating.columns[playerGUID]:SetBackdropColor(1, 0, 0, 1)
        rowRating.columns[playerGUID].fontString = rowRating.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowRating.columns[playerGUID].fontString:SetPoint("CENTER", rowRating.columns[playerGUID], "CENTER", cellPadding, 0)
        rowRating.columns[playerGUID].fontString:SetJustifyH("CENTER")
        rowRating.columns[playerGUID].fontString:SetText(character.rating)
        previousFrame = playerGUID
    end

    local rowItemLevel = CreateFrame("Frame", f:GetName() .. "ItemLevel", f, "BackdropTemplate")
    rowItemLevel:SetSize(f:GetWidth(), rowHeight)
    rowItemLevel:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -rowHeight * 2)
    rowItemLevel.columns = {}
    rowItemLevel.columns[0] = CreateFrame("Frame", rowItemLevel:GetName() .. "COL0", rowItemLevel, "BackdropTemplate")
    rowItemLevel.columns[0]:SetSize(colWidth, rowHeight)
    rowItemLevel.columns[0]:SetPoint("TOPLEFT", rowItemLevel, "TOPLEFT")
    rowItemLevel.columns[0]:SetBackdrop(backdropinfo)
    rowItemLevel.columns[0]:SetBackdropColor(1, 0, 0, 1)
    rowItemLevel.columns[0].fontString = rowItemLevel.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rowItemLevel.columns[0].fontString:SetPoint("LEFT", rowItemLevel.columns[0], "LEFT", cellPadding, 0)
    rowItemLevel.columns[0].fontString:SetJustifyH("LEFT")
    rowItemLevel.columns[0].fontString:SetText("Item Level:")

    local previousFrame = 0
    for playerGUID,character in pairs(characters) do
        rowItemLevel.columns[playerGUID] = CreateFrame("Frame", rowItemLevel:GetName() .. "COL" .. playerGUID, rowItemLevel, "BackdropTemplate")
        rowItemLevel.columns[playerGUID]:SetSize(colWidth, rowHeight)
        rowItemLevel.columns[playerGUID]:SetPoint("TOPLEFT", rowItemLevel.columns[previousFrame], "TOPRIGHT")
        rowItemLevel.columns[playerGUID]:SetBackdrop(backdropinfo)
        rowItemLevel.columns[playerGUID]:SetBackdropColor(1, 0, 0, 1)
        rowItemLevel.columns[playerGUID].fontString = rowItemLevel.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowItemLevel.columns[playerGUID].fontString:SetPoint("CENTER", rowItemLevel.columns[playerGUID], "CENTER", cellPadding, 0)
        rowItemLevel.columns[playerGUID].fontString:SetJustifyH("CENTER")
        rowItemLevel.columns[playerGUID].fontString:SetText(character.ilvl)
        previousFrame = playerGUID
    end

    for i = 1, 3 do
        local rowVault = CreateFrame("Frame", f:GetName() .. "Vault" .. i, f, "BackdropTemplate")
        rowVault:SetSize(f:GetWidth(), rowHeight)
        rowVault:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -rowHeight * (2 + i))
        rowVault.columns = {}
        rowVault.columns[0] = CreateFrame("Frame", rowVault:GetName() .. "COL0", rowVault, "BackdropTemplate")
        rowVault.columns[0]:SetSize(colWidth, rowHeight)
        rowVault.columns[0]:SetPoint("TOPLEFT", rowVault, "TOPLEFT")
        rowVault.columns[0]:SetBackdrop(backdropinfo)
        rowVault.columns[0]:SetBackdropColor(1, 0, 0, 1)
        rowVault.columns[0].fontString = rowVault.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowVault.columns[0].fontString:SetPoint("LEFT", rowVault.columns[0], "LEFT", cellPadding, 0)
        rowVault.columns[0].fontString:SetJustifyH("LEFT")
        rowVault.columns[0].fontString:SetText("Vault " .. i .. ":")
    
        local previousFrame = 0
        for playerGUID,character in pairs(characters) do
            rowVault.columns[playerGUID] = CreateFrame("Frame", rowVault:GetName() .. "COL" .. playerGUID, rowVault, "BackdropTemplate")
            rowVault.columns[playerGUID]:SetSize(colWidth, rowHeight)
            rowVault.columns[playerGUID]:SetPoint("TOPLEFT", rowVault.columns[previousFrame], "TOPRIGHT")
            rowVault.columns[playerGUID]:SetBackdrop(backdropinfo)
            rowVault.columns[playerGUID]:SetBackdropColor(1, 0, 0, 1)
            rowVault.columns[playerGUID].fontString = rowVault.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rowVault.columns[playerGUID].fontString:SetPoint("CENTER", rowVault.columns[playerGUID], "CENTER", cellPadding, 0)
            rowVault.columns[playerGUID].fontString:SetJustifyH("CENTER")
            rowVault.columns[playerGUID].fontString:SetText(character.vault[i])
            previousFrame = playerGUID
        end
    end

    
    local rowCurrentKey = CreateFrame("Frame", f:GetName() .. "CurrentKey", f, "BackdropTemplate")
    rowCurrentKey:SetSize(f:GetWidth(), rowHeight)
    rowCurrentKey:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -rowHeight * 6)
    rowCurrentKey.columns = {}
    rowCurrentKey.columns[0] = CreateFrame("Frame", rowCurrentKey:GetName() .. "COL0", rowCurrentKey, "BackdropTemplate")
    rowCurrentKey.columns[0]:SetSize(colWidth, rowHeight)
    rowCurrentKey.columns[0]:SetPoint("TOPLEFT", rowCurrentKey, "TOPLEFT")
    rowCurrentKey.columns[0]:SetBackdrop(backdropinfo)
    rowCurrentKey.columns[0]:SetBackdropColor(1, 0, 0, 1)
    rowCurrentKey.columns[0].fontString = rowCurrentKey.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rowCurrentKey.columns[0].fontString:SetPoint("LEFT", rowCurrentKey.columns[0], "LEFT", cellPadding, 0)
    rowCurrentKey.columns[0].fontString:SetJustifyH("LEFT")
    rowCurrentKey.columns[0].fontString:SetText("Current Key:")

    local previousFrame = 0
    for playerGUID,character in pairs(characters) do
        rowCurrentKey.columns[playerGUID] = CreateFrame("Frame", rowCurrentKey:GetName() .. "COL" .. playerGUID, rowCurrentKey, "BackdropTemplate")
        rowCurrentKey.columns[playerGUID]:SetSize(colWidth, rowHeight)
        rowCurrentKey.columns[playerGUID]:SetPoint("TOPLEFT", rowCurrentKey.columns[previousFrame], "TOPRIGHT")
        rowCurrentKey.columns[playerGUID]:SetBackdrop(backdropinfo)
        rowCurrentKey.columns[playerGUID]:SetBackdropColor(1, 0, 0, 1)
        rowCurrentKey.columns[playerGUID].fontString = rowCurrentKey.columns[playerGUID]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowCurrentKey.columns[playerGUID].fontString:SetPoint("CENTER", rowCurrentKey.columns[playerGUID], "CENTER", cellPadding, 0)
        rowCurrentKey.columns[playerGUID].fontString:SetJustifyH("CENTER")
        rowCurrentKey.columns[playerGUID].fontString:SetText(character.key.map .. " " .. character.key.level)
        previousFrame = playerGUID
    end
    
    local rowDungeonHeader = CreateFrame("Frame", f:GetName() .. "DungeonHeader", f, "BackdropTemplate")
    rowDungeonHeader:SetSize(f:GetWidth(), rowHeight)
    rowDungeonHeader:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -rowHeight * 7)
    rowDungeonHeader.columns = {}
    rowDungeonHeader.columns[0] = CreateFrame("Frame", rowDungeonHeader:GetName() .. "COL0", rowDungeonHeader, "BackdropTemplate")
    rowDungeonHeader.columns[0]:SetSize(colWidth, rowHeight)
    rowDungeonHeader.columns[0]:SetPoint("TOPLEFT", rowDungeonHeader, "TOPLEFT")
    rowDungeonHeader.columns[0]:SetBackdrop(backdropinfo)
    rowDungeonHeader.columns[0]:SetBackdropColor(1, 0, 0, 1)
    rowDungeonHeader.columns[0].fontString = rowDungeonHeader.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    rowDungeonHeader.columns[0].fontString:SetPoint("LEFT", rowDungeonHeader.columns[0], "LEFT", cellPadding, 0)
    rowDungeonHeader.columns[0].fontString:SetJustifyH("LEFT")
    rowDungeonHeader.columns[0].fontString:SetText("Dungeons:")

    local previousFrame = 0
    for playerGUID,character in pairs(characters) do
        rowDungeonHeader.columns[playerGUID .. "F"] = CreateFrame("Frame", rowDungeonHeader:GetName() .. "COL" .. playerGUID .. "F", rowDungeonHeader, "BackdropTemplate")
        rowDungeonHeader.columns[playerGUID .. "F"]:SetSize(colWidth / 2, rowHeight)
        rowDungeonHeader.columns[playerGUID .. "F"]:SetPoint("TOPLEFT", rowDungeonHeader.columns[previousFrame], "TOPRIGHT")
        rowDungeonHeader.columns[playerGUID .. "F"]:SetBackdrop(backdropinfo)
        rowDungeonHeader.columns[playerGUID .. "F"]:SetBackdropColor(1, 1, 0, 1)
        rowDungeonHeader.columns[playerGUID .. "F"].fontString = rowDungeonHeader.columns[playerGUID .. "F"]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowDungeonHeader.columns[playerGUID .. "F"].fontString:SetPoint("CENTER", rowDungeonHeader.columns[playerGUID .. "F"], "CENTER", cellPadding, 0)
        rowDungeonHeader.columns[playerGUID .. "F"].fontString:SetJustifyH("CENTER")
        rowDungeonHeader.columns[playerGUID .. "F"].fontString:SetText("F")
        rowDungeonHeader.columns[playerGUID .. "T"] = CreateFrame("Frame", rowDungeonHeader:GetName() .. "COL" .. playerGUID .. "T", rowDungeonHeader, "BackdropTemplate")
        rowDungeonHeader.columns[playerGUID .. "T"]:SetSize(colWidth / 2, rowHeight)
        rowDungeonHeader.columns[playerGUID .. "T"]:SetPoint("TOPLEFT", rowDungeonHeader.columns[playerGUID .. "F"], "TOPRIGHT")
        rowDungeonHeader.columns[playerGUID .. "T"]:SetBackdrop(backdropinfo)
        rowDungeonHeader.columns[playerGUID .. "T"]:SetBackdropColor(1, 1, 0, 1)
        rowDungeonHeader.columns[playerGUID .. "T"].fontString = rowDungeonHeader.columns[playerGUID .. "T"]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowDungeonHeader.columns[playerGUID .. "T"].fontString:SetPoint("CENTER", rowDungeonHeader.columns[playerGUID .. "T"], "CENTER", cellPadding, 0)
        rowDungeonHeader.columns[playerGUID .. "T"].fontString:SetJustifyH("CENTER")
        rowDungeonHeader.columns[playerGUID .. "T"].fontString:SetText("T")
        previousFrame = playerGUID .. "T"
    end

    local i = 1
    for mapId,shortName in pairs(Maps) do
        local rowDungeon = CreateFrame("Frame", f:GetName() .. "Dungeon" .. i, f, "BackdropTemplate")
        rowDungeon:SetSize(f:GetWidth(), rowHeight)
        rowDungeon:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -rowHeight * (7 + i))
        rowDungeon.columns = {}
        rowDungeon.columns[0] = CreateFrame("Frame", rowDungeon:GetName() .. "COL0", rowDungeon, "BackdropTemplate")
        rowDungeon.columns[0]:SetSize(colWidth, rowHeight)
        rowDungeon.columns[0]:SetPoint("TOPLEFT", rowDungeon, "TOPLEFT")
        rowDungeon.columns[0]:SetBackdrop(backdropinfo)
        rowDungeon.columns[0]:SetBackdropColor(1, 0, 0, 1)
        rowDungeon.columns[0].fontString = rowDungeon.columns[0]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        rowDungeon.columns[0].fontString:SetPoint("LEFT", rowDungeon.columns[0], "LEFT", cellPadding, 0)
        rowDungeon.columns[0].fontString:SetJustifyH("LEFT")
        rowDungeon.columns[0].fontString:SetText(shortName)

        local previousFrame = 0
        for playerGUID,character in pairs(characters) do
            rowDungeon.columns[playerGUID .. "F"] = CreateFrame("Frame", rowDungeon:GetName() .. "COL" .. playerGUID .. "F", rowDungeon, "BackdropTemplate")
            rowDungeon.columns[playerGUID .. "F"]:SetSize(colWidth / 2, rowHeight)
            rowDungeon.columns[playerGUID .. "F"]:SetPoint("TOPLEFT", rowDungeon.columns[previousFrame], "TOPRIGHT")
            rowDungeon.columns[playerGUID .. "F"]:SetBackdrop(backdropinfo)
            rowDungeon.columns[playerGUID .. "F"]:SetBackdropColor(1, 1, 0, 1)
            rowDungeon.columns[playerGUID .. "F"].fontString = rowDungeon.columns[playerGUID .. "F"]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rowDungeon.columns[playerGUID .. "F"].fontString:SetPoint("CENTER", rowDungeon.columns[playerGUID .. "F"], "CENTER", cellPadding, 0)
            rowDungeon.columns[playerGUID .. "F"].fontString:SetJustifyH("CENTER")
            rowDungeon.columns[playerGUID .. "F"].fontString:SetText(character.dungeons[mapId][2])
            rowDungeon.columns[playerGUID .. "T"] = CreateFrame("Frame", rowDungeon:GetName() .. "COL" .. playerGUID .. "T", rowDungeon, "BackdropTemplate")
            rowDungeon.columns[playerGUID .. "T"]:SetSize(colWidth / 2, rowHeight)
            rowDungeon.columns[playerGUID .. "T"]:SetPoint("TOPLEFT", rowDungeon.columns[playerGUID .. "F"], "TOPRIGHT")
            rowDungeon.columns[playerGUID .. "T"]:SetBackdrop(backdropinfo)
            rowDungeon.columns[playerGUID .. "T"]:SetBackdropColor(1, 1, 0, 1)
            rowDungeon.columns[playerGUID .. "T"].fontString = rowDungeon.columns[playerGUID .. "T"]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            rowDungeon.columns[playerGUID .. "T"].fontString:SetPoint("CENTER", rowDungeon.columns[playerGUID .. "T"], "CENTER", cellPadding, 0)
            rowDungeon.columns[playerGUID .. "T"].fontString:SetJustifyH("CENTER")
            rowDungeon.columns[playerGUID .. "T"].fontString:SetText(character.dungeons[mapId][1])
            previousFrame = playerGUID .. "T"
        end

        i = i + 1
    end
    

    AlterEgo:UpdateFrames()
end

function AlterEgo:UpdateFrames()
    local characters = AlterEgo:GetCharacters()

    local frameWidth = colWidth
    
    for playerGUID, character in pairs(characters) do
        frameWidth = frameWidth + colWidth
    end

    f:SetSize(frameWidth, rowHeight * 16)

    -- for playerGUID, character in pairs(characters) do
    --     print(character.name)
    -- end
    
end
