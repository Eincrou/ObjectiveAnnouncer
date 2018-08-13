local NAME, S = ...
S.VERSION = GetAddOnMetadata(NAME, "Version")
S.NUMVERSION = 8010	-- 8.0.1
S.NAME = "Objective Announcer v"..S.VERSION

ObjAnnouncer = LibStub("AceAddon-3.0"):NewAddon("Objective Announcer", "AceComm-3.0", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0", "LibSink-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Objective Announcer")
	
	---------------------
	-- Local Variables --
	---------------------
local oorUpdated = false
	
local self = ObjAnnouncer
local pairs = pairs
local tostring = tostring
local floor = math.floor
local DAILY, GROUP, WEEKLY, QUEST_COMPLETE, ABANDON_QUEST = _G.DAILY, _G.GROUP, _G.CALENDAR_REPEAT_WEEKLY, _G.QUEST_WATCH_QUEST_COMPLETE, _G.ABANDON_QUEST

local playerName, realmName
local questLogStatus = {}
local oorGroupStorage = {}
local pbThresholds = {}

local questLogRewards = {}
local questInfoRewards = {}
local questLootRecieved = {
	questID = nil,
	itemLink = nil,
	quantity = nil,
}

local initialRewardsTimer
local initialRewardsTimersTable = {}
local checkRewardTimer

local defaults = {
	profile = {
		--[[ General ]]--
		annType = 3,
		progBarInterval = 25,
			-- Announce to --
		selftell = true, selftellalways = false,
		selfColor = {r = 1.0, g = 1.0, b = 1.0, hex = "|cffFFFFFF"},
		sink20OutputSink = "ChatFrame",
		sink20Sticky = true,
		saychat = false,
		partychat = true,
		instancechat = true,
		raidchat = false,
		guildchat = false,
		officerchat = false,
		channelchat = false,
		chanName = 1,
			-- Additional Info --
		questlink = true, infoSuggGroup = false, infoLevel = false, infoFrequency = false, infoTag = false,
			--Quest Start/End --
		questAccept = false, questTurnin = false, questEscort = false, infoAutoComp = false, questFail = false, 
		questAbandon = false, questTask = false, 
			-- Quest Rewards --
		questRewards = false, rewardSelf = false, rewardXP = true, rewardMoney = true, rewardItems = true, rewardCurrency = true, 
		rewardHonor = true, rewardSpell = true, rewardSkill = true, rewardTitle = true, rewardArtifact = true,
			-- Sound --
		enableCompletionSound = true, enableCommSound = false, enableAcceptFailSound = false,
		annSoundName = "PVPFlagCapturedHorde", annSoundFile = "Sound\\Interface\\PVPFlagCapturedHordeMono.ogg",
		compSoundName = "PVPFlagCaptured", compSoundFile = "Sound\\Interface\\PVPFlagCapturedMono.ogg",
		commSoundName = "GM ChatWarning", commSoundFile = "Sound\\Interface\\GM_ChatWarning.ogg",
		acceptSoundName = "Hearthstone-QuestAccepted", acceptSoundFile = "Interface\\Addons\\ObjectiveAnnouncer\\Sounds\\Hearthstone-QuestingAdventurer_QuestAccepted.ogg",		
		failSoundName = "Hearthstone-QuestFailed", failSoundFile = "Interface\\Addons\\ObjectiveAnnouncer\\Sounds\\Hearthstone-QuestingAdventurer_QuestFailed.ogg",
			-- Out of Range Alerts --
		enableOOR = false,
	},
	char = {taskStorage = {},},
	global = {oorNotifyVersion = 0,},
}

	-------------
	-- Popups --
	-------------

StaticPopupDialogs["ObjAnn_OORUPDATED"] = {
  text = L["popupoorupdate"],
  button1 = ACCEPT,
  OnAccept = function()
      self.db.global.oorNotifyVersion = S.NUMVERSION
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = false,
}

	---------------------
	-- Local Functions --
	---------------------
	
	-- [[ Helper Functions ]] --
	
local function oaStoreQuestLogRewards(questID)
	if questLogRewards[questID] then return end
	questLogRewards[questID] =	{
		item = {
			numRewards = GetNumQuestLogRewards(questID),
		}, 
		choice = {
			numChoices = GetNumQuestLogChoices(questID), 
		}, 
		currency = {
			numCurrencies = GetNumQuestLogRewardCurrencies(questID),
		}, 
		spell = {
			numSpellRewards = GetNumQuestLogRewardSpells(questID),
		},		
		xp = GetQuestLogRewardXP(questID),
		money = GetQuestLogRewardMoney(questID),
		honor = GetQuestLogRewardHonor(questID),
		playerTitle = GetQuestLogRewardTitle(questID),
		skill = {},
		artifact = {},								
	}
	questLogRewards[questID].skill.name, questLogRewards[questID].skill.icon, 
		questLogRewards[questID].skill.points = GetQuestLogRewardSkillPoints(questID);
	questLogRewards[questID].artifact.XP, questLogRewards[questID].artifact.category 
		= GetQuestLogRewardArtifactXP(questID);
	
	if questLogRewards[questID].item.numRewards > 0 then
		for i = 1, questLogRewards[questID].item.numRewards, 1 do
			local itemName, itemTexture, numItems, quality, isUsable, itemID = GetQuestLogRewardInfo(i, questID)
			questLogRewards[questID].item[i] = { 
				name = itemName,
				count = numItems,
				id = itemID,
				link = select(2, GetItemInfo(itemID)),
			}
		end
	end
	
	if questLogRewards[questID].currency.numCurrencies > 0 then
		for i = 1, questLogRewards[questID].currency.numCurrencies, 1 do
			local name, texture, numItems, currencyID, quality = GetQuestLogRewardCurrencyInfo(i, questID)
			questLogRewards[questID].currency[i] = { 
				name = name,
				count = numItems,
				cID = currencyID,
				link = GetCurrencyLink(currencyID, numItems),
			}		
		end
	end
	
	if  questLogRewards[questID].spell.numSpellRewards > 0 then
		for i = 1, questLogRewards[questID].spell.numSpellRewards, 1 do
			local texture, name, isTradeskillSpell, isSpellLearned, hideSpellLearnText, isBoostSpell,
				garrFollowerID, genericUnlock, spellID = GetQuestLogRewardSpell(i, questID);
			questLogRewards[questID].spell[i] = {
				name = name,
				sID = spellID,
				link = GetSpellLink(spellID) or "|cff71d5ff|Hspell:"..spellID.."|h["..name.."]|h|r"
			}
		end	
	end
end		

local function oaBuildInitialRewardsTable()
	local numEntries, numQuests = GetNumQuestLogEntries()
	for entryIndex = 1, numEntries do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent,
			displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(entryIndex);
		if not isHeader then
			oaStoreQuestLogRewards(questID)			
		end
	end		
end

function ObjAnnouncer:oaMakeRewardInfoAvailable(rewardQuestID, timerIndex)
	for i = 1, GetNumQuestLogRewards(rewardQuestID) do
		local itemName, itemTexture, numItems, quality, isUsable, itemID = GetQuestLogRewardInfo(i, rewardQuestID)
		if itemName and itemID then
			self:CancelTimer(initialRewardsTimersTable[timerIndex])
		end
	end
end

function ObjAnnouncer:oaCheckRewardTimers()
	local timeLeft = 0
	for i = 1, #initialRewardsTimersTable do
		timeLeft = timeLeft + self:TimeLeft(initialRewardsTimersTable[i])
	end
	
	if timeLeft == 0 then
		self:CancelTimer(checkRewardTimer)
		oaBuildInitialRewardsTable()
	end		
end

local function oaInitializeRewardsTable()
	local numEntries, numQuests = GetNumQuestLogEntries()
	local rewardQuestID, rewardQuestTitle
	local timerIndex = 0
	for entryIndex = 1, numEntries do
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent,
			displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(entryIndex);
		if not isHeader then
			if GetNumQuestLogRewards(questID) > 0 then
				rewardQuestID = questID
				rewardQuestTitle = title
				
				timerIndex = timerIndex + 1
				initialRewardsTimersTable[timerIndex] = self:ScheduleRepeatingTimer("oaMakeRewardInfoAvailable", 0.1, rewardQuestID, timerIndex)				
			end
		end
	end
	
	if timerIndex > 0 then
		checkRewardTimer = self:ScheduleRepeatingTimer("oaCheckRewardTimers", 0.33)
	else
		oaBuildInitialRewardsTable()
	end
end

-- Show money with icons
local function CopperToStringIcon(c)
	local str = ""
	if not c or c < 0 then
		return str
	end

	if c >= 10000 then
		local g = math.floor(c/10000)
		c = c - g*10000
		str = str.."|cFFFFD800"..g.."|r |TInterface\\MoneyFrame\\UI-GoldIcon.blp:0:0:0:0|t"
	end
	if c >= 100 then
		local s = math.floor(c/100)
		c = c - s*100
		str = str.."|cFFC7C7C7"..s.."|r |TInterface\\MoneyFrame\\UI-SilverIcon.blp:0:0:0:0|t"
	end
	if c >= 0 then
		str = str.."|cFFEEA55F"..c.."|r |TInterface\\MoneyFrame\\UI-CopperIcon.blp:0:0:0:0|t"
	end

	return str
end

-- Show money
local function CopperToString(c)
	local str = ""
	if not c or c < 0 then
		return str
	end

	if c >= 10000 then
		local g = math.floor(c/10000)
		c = c - g*10000
		str = str..g.."g"
	end
	if c >= 100 then
		local s = math.floor(c/100)
		c = c - s*100
		str = str..s.."s"
	end
	if c > 0 then
		str = str..c.."c"
	end

	return str
end

local function ClearQuestData(questID)
	questLogStatus[questID] = nil
	questLogRewards[questID] = nil
	questInfoRewards =	{ }
	questLootRecieved = {questID = nil, itemLink = nil,	quantity = nil, }	

end


	-- [[ Message Functions ]] --

local function oaMessageHandler(announcement, enableSelf, enableSound, enableComm, isComplete, money)
	local selfTest = true	-- Variable to see if any conditions have fired.
	
	
	
	
	if self.db.profile.raidchat == true and IsInRaid() then
		if self.db.profile.instancechat and IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then		
			SendChatMessage(announcement, "INSTANCE_CHAT")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest instance", "RAID") end
			selfTest = false
		elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
			SendChatMessage(announcement, "RAID")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest raid", "RAID") end
			selfTest = false			
		end		
	elseif self.db.profile.partychat and IsInGroup() then
		if self.db.profile.instancechat and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			SendChatMessage(announcement, "INSTANCE_CHAT")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest instance", "PARTY") end
			selfTest = false
		elseif self.db.profile.partychat and IsInGroup(LE_PARTY_CATEGORY_HOME) then
			SendChatMessage(announcement, "PARTY")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest party", "PARTY") end
			selfTest = false
		end
		
		
	elseif self.db.profile.saychat and UnitIsDeadOrGhost("player") == nil then
		SendChatMessage(announcement, "SAY")
	--	if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest say", "PARTY") end
		selfTest = false
	end
	if self.db.profile.guildchat and IsInGuild() then
		SendChatMessage(announcement, "GUILD")
	--	if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest guild", "GUILD") end
		selfTest = false
	elseif self.db.profile.officerchat and CanViewOfficerNote() then
		SendChatMessage(announcement, "OFFICER")
	--	if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest officer", "GUILD") end
		selfTest = false
	end
	if self.db.profile.channelchat then
		SendChatMessage(announcement, "CHANNEL", nil, self.db.profile.chanName)
		selfTest = false
	end
	if enableSelf then
		if self.db.profile.selftellalways then
			ObjAnnouncer:Pour(announcement, self.db.profile.selfColor.r, self.db.profile.selfColor.g, self.db.profile.selfColor.b)
		elseif self.db.profile.selftell and selfTest then
			ObjAnnouncer:Pour(announcement, self.db.profile.selfColor.r, self.db.profile.selfColor.g, self.db.profile.selfColor.b)
		end
	end
	if enableSound then
		if isComplete == 1 and self.db.profile.enableCompletionSound then
			PlaySoundFile(self.db.profile.compSoundFile,"Master")
		elseif self.db.profile.enableCompletionSound then
			PlaySoundFile(self.db.profile.annSoundFile,"Master")			
		elseif isComplete == -1 and self.db.profile.enableAcceptFailSound then	
			PlaySoundFile(self.db.profile.failSoundFile,"Master")
		end
	end
end

local function oaMessageCreator(questID, objDesc, objComplete, level, suggestedGroup, isComplete, frequency)

	local divider = false
	local infoDivider
	local questLink = GetQuestLink(questID)
	if self.db.profile.questlink then
		messageInfoLink = strjoin("", "  --  ", questLink)
	else
		messageInfoLink = ""
	end
	if (suggestedGroup > 0) and self.db.profile.infoSuggGroup then		
		messageInfoSuggGroup = strjoin("", " ["..GROUP..": ", suggestedGroup, "]")
		divider = true
	else
		messageInfoSuggGroup = ""
	end
	if (frequency > 1) and self.db.profile.infoFrequency then
		if frequency == 2 then messageInfoFrequency = " "..DAILY elseif frequency == 3 then messageInfoFrequency = " "..WEEKLY end
		divider = true
	else
		messageInfoFrequency = ""
	end
	if self.db.profile.infoTag then
		local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(questID)
		if tagID then 
			messageInfoTag = " "..tagName
			divider = true
		else
			messageInfoTag = ""	
		end		
	else
		messageInfoTag = ""			
	end
	if self.db.profile.infoLevel then
		local temp = tostring(level)
		messageInfoLevel = strjoin("", " [", temp, "]")
		divider = true
	else
		messageInfoLevel = ""
	end
	if divider then 
		infoDivider = " --" 
	else
		infoDivider = ""
	end
	
	if self.db.profile.annType == 1 then
		finalAnnouncement = string.upper(QUEST_COMPLETE).." -- "..questLink..infoDivider..messageInfoSuggGroup..messageInfoFrequency..messageInfoTag..messageInfoLevel	-- This announcement type ignores self.db.profile.questlink to ensure that a quest link is always displayed.
	else
		finalAnnouncement = objDesc..messageInfoLink..infoDivider..messageInfoSuggGroup..messageInfoFrequency..messageInfoLevel
		if (self.db.profile.annType == 3 or self.db.profile.annType == 5) and isComplete == 1 then
			finalAnnouncement = finalAnnouncement.." -- "..string.upper(QUEST_COMPLETE)
		end
	end
	oaMessageHandler(finalAnnouncement, true, objComplete, objComplete, isComplete)
end	

local function oaRewardMessageCreator( questID, xpReward, moneyReward )	
	local rewardMessage	= ""
	local sectionDivider = ""
	
	if self.db.profile.rewardXP then		
		if xpReward > 0 then
			rewardMessage = xpReward.." "..L["expgain"]
			sectionDivider = ", "
		end		
	end
	
	if self.db.profile.rewardMoney then 
		if moneyReward > 0 then
			rewardMessage = rewardMessage..sectionDivider..CopperToString(moneyReward)
			sectionDivider = ", "
		end
	end
	
	if self.db.profile.rewardItems then
		if questLootRecieved.itemLink then
			local itemQuantity
			if questLootRecieved.quantity > 0 then
				itemQuantity = " x"..questLootRecieved.quantity
			else	
				itemQuantity = ""
			end	
			rewardMessage = rewardMessage..sectionDivider..questLootRecieved.itemLink..itemQuantity
			sectionDivider = ", "
		elseif (questLogRewards[questID] and questLogRewards[questID].item.numRewards > 0) then
			rewardMessage = rewardMessage..sectionDivider
			for i = 1, questLogRewards[questID].item.numRewards, 1 do
				local itemQuantity
				if questLogRewards[questID].item[i].count > 0 then
					itemQuantity = " x"..questLogRewards[questID].item[i].count
				else	
					itemQuantity = ""
				end
				local comma = ""
				if (i > 1 and i < questLogRewards[questID].item.numRewards) then comma = ", " end						
				rewardMessage = rewardMessage..comma..questLogRewards[questID].item[i].link..itemQuantity			
			end		
			sectionDivider = ", "
		end
		if questInfoRewards.choice then
			rewardMessage = rewardMessage..sectionDivider..questInfoRewards.choice
			sectionDivider = ", "
		end
	end

	if self.db.profile.rewardCurrency then
		if (questInfoRewards.currency and questInfoRewards.currency.count and questInfoRewards.currency.count > 0) then
			rewardMessage = rewardMessage..sectionDivider
			for i = 1, questInfoRewards.currency.count, 1 do
				local currencyLink = questInfoRewards.currency[i].link
				local currencyQuantity = questInfoRewards.currency[i].count
				local comma = ""
				if (i > 1 and i < questInfoRewards.currency.count) then comma = ", " end
				rewardMessage = rewardMessage..comma..currencyLink.." x"..currencyQuantity
			end
			sectionDivider = ", "
		elseif (questLogRewards[questID] and questLogRewards[questID].currency.numCurrencies > 0) then
			rewardMessage = rewardMessage..sectionDivider
			for i = 1, questLogRewards[questID].currency.numCurrencies, 1 do
				local currencyLink = questLogRewards[questID].currency[i].link
				local currencyQuantity = questLogRewards[questID].currency[i].count
				local comma = ""
				if (i > 1 and i < questLogRewards[questID].currency.numCurrencies) then comma = ", " end
				rewardMessage = rewardMessage..comma..currencyLink.." x"..currencyQuantity
			end
			sectionDivider = ", "
		end
	end
		
	if self.db.profile.rewardSpell then
		if (questInfoRewards.spell and questInfoRewards.spell.count and questInfoRewards.spell.count > 0) then
			rewardMessage = rewardMessage..sectionDivider
			for i = 1, questInfoRewards.spell.count, 1 do
				local spellLink = questInfoRewards.spell[i].link
				local comma = ""
				if (i > 1 and i < questInfoRewards.spell.count) then comma = ", " end						
				rewardMessage = rewardMessage..comma..spellLink
			end
			sectionDivider = ", "
		elseif (questLogRewards[questID] and questLogRewards[questID].spell.numSpellRewards > 0) then
			rewardMessage = rewardMessage..sectionDivider
			for i = 1, questLogRewards[questID].spell.numSpellRewards, 1 do
				local spellLink = questLogRewards[questID].spell[i].link
				local comma = ""
				if (i > 1 and i < questLogRewards[questID].spell.numSpellRewards) then comma = ", " end
				rewardMessage = rewardMessage..comma..spellLink
			end
			sectionDivider = ", "
		end
	end
	
	if self.db.profile.rewardHonor then
		if (questInfoRewards.honor and questInfoRewards.honor > 0) then
			rewardMessage = rewardMessage..sectionDivider..questInfoRewards.honor.." "..HONOR
			sectionDivider = ", "
		elseif questLogRewards[questID] and questLogRewards[questID].honor > 0 then
			rewardMessage = rewardMessage..sectionDivider..questLogRewards[questID].honor.." "..HONOR
			sectionDivider = ", "
		end
	end
	
	if self.db.profile.rewardTitle then
		if questInfoRewards.title then
			rewardMessage = rewardMessage..sectionDivider..L["rewardtitle"]..": "..questInfoRewards.title
			sectionDivider = ", "
		elseif questLogRewards[questID] and questLogRewards[questID].title then
			rewardMessage = rewardMessage..sectionDivider..L["rewardtitle"]..": "..questLogRewards[questID].title
			sectionDivider = ", "
		end
	end
	
	if self.db.profile.rewardSkill then
		if (questInfoRewards.skill and questInfoRewards.skill.name) then
			rewardMessage = rewardMessage..sectionDivider.."+"..questInfoRewards.skill.points.." "..questInfoRewards.skill.name
			sectionDivider = ", "
		elseif questLogRewards[questID] and questLogRewards[questID].skill.name then
			rewardMessage = rewardMessage..sectionDivider.."+"..questLogRewards[questID].skill.points.." "..questLogRewards[questID].skill.name
			sectionDivider = ", "
		end
	end
	
	if self.db.profile.rewardArtifact then
		if (questInfoRewards.artifact and questInfoRewards.artifact.XP and questInfoRewards.artifact.XP > 0) then
			rewardMessage = rewardMessage..sectionDivider..questInfoRewards.artifact.XP.." "..L["rewardartifactxp"]
			sectionDivider = ", "
		elseif questLogRewards[questID] and questLogRewards[questID].artifact.XP > 0 then
			rewardMessage = rewardMessage..sectionDivider..questLogRewards[questID].artifact.XP.." "..L["rewardartifactxp"]
			sectionDivider = ", "
		end
	end
		
	if rewardMessage ~= "" then
		local finalRewardMessage = L["rewardreceived"]..": "..rewardMessage
		if rewardMessage and (not self.db.profile.questTurnin) then
			finalRewardMessage = ((questLogStatus[questID] and questLogStatus[questID].qLink) or QuestUtils_GetQuestName(questID)).." -- "..rewardMessage
		end
		oaMessageHandler(finalRewardMessage, self.db.profile.rewardSelf, false, nil, nil, moneyReward)		
	end
end

local function progressAnnCheck(percent, questID)	-- Check progress bar announcement interval to see if we should make an announcement.
	local makeAnnounce = false
	local interval = self.db.profile.progBarInterval
	if not pbThresholds[questID] then
		pbThresholds[questID] = interval
	end	
	if percent >= pbThresholds[questID] then
		local threshold = (floor(percent / interval) * interval) + interval
		if threshold > 100 then threshold = 100 end
		pbThresholds[questID] = threshold
		makeAnnounce = true
	end	
	return makeAnnounce
end


-- [[ Out-Of-Range Functions ]] 

local function oaOORHandler(prefix, text, dist, groupMember)
	if groupMember == playerName then return end
	local oorQuestID, oorBoardIndex, oorObjCurrent, oorObjTotal, oorObjText, isTask, _ = strsplit("\a", text, 7)
	oorQuestID = tonumber(oorQuestID)
	oorObjCurrent =  tonumber(oorObjCurrent)
	oorBoardIndex = tonumber(oorBoardIndex)
	if not oorGroupStorage[groupMember] then
		oorGroupStorage[groupMember] = {}
	end
	if not oorGroupStorage[groupMember][oorQuestID] then
		oorGroupStorage[groupMember][oorQuestID] = {}
	end
	local myLogIndex = GetQuestLogIndexByID(oorQuestID)	
	if self.db.profile.enableOOR and (myLogIndex > 0 or isTask == "true") then	-- Is quest in our log? Also handles tasks, even if not in the log right now.
		local myObjDesc, myObjType, myObjComplete = GetQuestObjectiveInfo(oorQuestID, oorBoardIndex)
		local myObjCurrent, myObjTotal, myObjText
		local validTaskInfo = false
		
		if (isTask == "false") then	-- Parse objective information and validate task info.	
			myObjCurrent, myObjTotal, myObjText = string.match(myObjDesc, "(%d+)/(%d+) ?(.*)")
			myObjCurrent = tonumber(myObjCurrent)
			myObjTotal = tonumber(myObjTotal)
		elseif self.db.char.taskStorage[oorQuestID] then
			if self.db.char.taskStorage[oorQuestID][oorBoardIndex] then
				if (myObjType == "progressbar") then
					myObjCurrent = GetQuestProgressBarPercent(oorQuestID)
					myObjTotal = 100
					myObjText = myObjDesc
				else
					myObjCurrent, myObjTotal, myObjText = string.match(myObjDesc, "(%d+)/(%d+) ?(.*)")
					myObjCurrent = tonumber(myObjCurrent)
					myObjTotal = tonumber(myObjTotal)
				end
				if myObjCurrent == self.db.char.taskStorage[oorQuestID][oorBoardIndex].taskObjCurrent then	-- Validate queried info against saved data.
					validTaskInfo = true
				else
					myObjCurrent = self.db.char.taskStorage[oorQuestID][oorBoardIndex].taskObjCurrent	-- Load saved objective info.
					validTaskInfo = true
				end
			end
		end
		
		if (myObjComplete == false) and ((isTask == "false") or validTaskInfo) then	-- Don't execute if we're already done with the objective. If no saved data about a task, do something else.				
			if not oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] then
				oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] = {savedDelta = oorObjCurrent - myObjCurrent}
			end
			local currentDelta = oorObjCurrent - myObjCurrent		
			if (currentDelta > oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta) then	-- If current delta increased over previous delta, we missed an objective. If delta decreased, do nothing.
				local qlink = GetQuestLink(oorQuestID) or self.db.char.taskStorage[oorQuestID].taskQuestLink
				local announcement = groupMember..L["oornotreceived"]..myObjText.."\" -- "..qlink
				oaMessageHandler(announcement, true, false, false, false, true)
			end	
			oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta = currentDelta
		elseif (not myObjComplete) then	-- Handles tasks the player has not encountered.
			if (not oorGroupStorage[groupMember][oorQuestID][oorBoardIndex]) then	-- Create new group storage entry
				oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] = {savedDelta = oorObjCurrent}
			else	-- Otherwise, we've either completed this task previously, or have not progressed it at all.  Update delta, assuming that our task progress is 0.
				oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta = oorObjCurrent
			end
		end
	else	-- If quest is not in questlog and not a task, still save the delta so we can use it when needed.
		if not oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] then
			oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] = {savedDelta = oorObjCurrent}
		else
			oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta = oorObjCurrent
		end
	end
end

local function oaOORSendComm(questID, boardIndex, objDesc, isTask, objType)
	local objCurrent, objTotal, objText
	local reserved = ""	-- Reserving function parameters so any future OOR additional functionality doesn't break players using previous versions.
	local chanType = "RAID"	-- "RAID" sends messages to party if not in raid, but check to be sure.
	if IsInGroup() and (not IsInRaid()) then chanType = "PARTY" end
	if (objType == "progressbar") then
		objCurrent = tostring(GetQuestProgressBarPercent(questID))
		objTotal = "100"
		objText = objDesc
	else
		objCurrent, objTotal, objText = string.match(objDesc, "(%d+)/(%d+) ?(.*)")
	end
	oorCommMessage = strjoin("\a", questID, boardIndex, objCurrent, objTotal, objText, tostring(isTask), reserved)								
	ObjAnnouncer:SendCommMessage("ObjA OOR", oorCommMessage, chanType)	
end


-- [[ Core Functionality ]] --

local function oaBuildInitialTable(event, ...)
	local numEntries, numQuests = GetNumQuestLogEntries()
	for entryIndex = 1, numEntries do
		questLogStatus["numEntries"] = numEntries
		questLogStatus["numQuests"] = numQuests
		local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(entryIndex)
		if not isHeader then
			questLogStatus[questID] = {complete = isComplete, qLink = GetQuestLink(questID), isTask = isTask}
			for boardIndex = 1, GetNumQuestLeaderBoards(entryIndex) do
				local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, entryIndex)
				questLogStatus[questID][boardIndex] = {complete = objComplete}
				if (objType == "progressbar") then
					questLogStatus[questID][boardIndex] = {description = GetQuestProgressBarPercent(questID), complete = objComplete}
				else						
					questLogStatus[questID][boardIndex] = {description = objDesc, complete = objComplete}
				end
			end				
		end		
	end
end	

local function oaUpdateQuestLog()
	local numEntries, numQuests = GetNumQuestLogEntries()
	
	if (numEntries ~= questLogStatus.numEntries) or (numQuests ~= questLogStatus.numQuests) then
		if numEntries > questLogStatus.numEntries then
			for entryIndex = 1,  numEntries do
			local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(entryIndex)				
				if (not isHeader) and (not questLogStatus[questID]) then
					oaStoreQuestLogRewards(questID)
					questLogStatus[questID] = {complete = isComplete, qLink = GetQuestLink(questID), isTask = isTask}
					for boardIndex = 1, GetNumQuestLeaderBoards(entryIndex) do
						local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, entryIndex)
						questLogStatus[questID][boardIndex] = {complete = objComplete}
						if (objType == "progressbar") then
							questLogStatus[questID][boardIndex] = {description = GetQuestProgressBarPercent(questID), complete = objComplete}
						else
							questLogStatus[questID][boardIndex] = {description = objDesc, complete = objComplete}
						end
						if isTask then
							if (not self.db.char.taskStorage[questID]) then
								self.db.char.taskStorage[questID] = {taskQuestLink = GetQuestLink(questID)}
							end
							if (IsInGroup() or IsInRaid()) and ((objType == "progressbar") or string.find(objDesc, L["slain"]) or string.find(objDesc, L["killed"])) then -- Send initial OOR when picking up a new task
								oaOORSendComm(questID, boardIndex, objDesc, isTask, objType)
							end
						end
					end
					if isTask and self.db.profile.questTask then
						local taskMessage = L["areaentered"].." -- "..GetQuestLink(questID)
						oaMessageHandler(taskMessage, true, false, false, isComplete)
					end										
				end
			end
		else
			-- Quest Removed
		end	
		questLogStatus.numEntries = numEntries
		questLogStatus.numQuests = numQuests
	else
		for entryIndex = 1, numEntries do
			local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory = GetQuestLogTitle(entryIndex)
			if (not questLogStatus[questID]) then	-- For when tasks appear immediately after turning in a quest
				questLogStatus[questID] = {complete = isComplete, qLink = GetQuestLink(questID), isTask = isTask}
				questLogStatus.numQuests = questLogStatus.numQuests + 1
			end
			if not isHeader then
				oaStoreQuestLogRewards(questID)
		--[[ Announcements Logic ]]--
			--[[ Failed Quests ]]--
				if isComplete == -1 and self.db.profile.questFail and isComplete ~= questLogStatus[questID].complete then
					questLogStatus[questID].complete = isComplete
					local questLink = GetQuestLink(questID)
					local failedMessage = questLink.." -- "..L["questfailed"]
					oaMessageHandler(failedMessage, true, false, false, isComplete)
				end
			--[[ Completed Quests Only ]]--
				if isComplete == 1 and isComplete ~= questLogStatus[questID].complete then
					questLogStatus[questID].complete = isComplete
					if self.db.profile.annType ==  1 then
						oaMessageCreator(questID, nil, true, level, suggestedGroup, isComplete, frequency)
					end
				end
			--[[ Completed Objectives (and Completed Quests, if Announce Type 3 is selected) ]]--
				for boardIndex = 1, GetNumQuestLeaderBoards(entryIndex) do
					local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, entryIndex)
					if (not questLogStatus[questID][boardIndex]) then	-- For quests where objectives are progressively added
						questLogStatus[questID][boardIndex] = {complete = objComplete, description = objDesc}						
					end
					local percent = nil
					if (objType == "progressbar") then percent = GetQuestProgressBarPercent(questID) end
					if (objComplete) and objComplete ~= questLogStatus[questID][boardIndex].complete then
						questLogStatus[questID][boardIndex].complete = objComplete
						if self.db.profile.annType == 2 or self.db.profile.annType == 3 then					
							oaMessageCreator(questID, objDesc, objComplete, level, suggestedGroup, isComplete, frequency)
						end
					end
					if isTask then	-- Use saved variables to keep track of tasks.
						local storeObjCurrent, storeObjTotal, storeObjText
						if (objType == "progressbar") then
							storeObjCurrent = percent
							storeObjTotal = 100
							storeObjText = objDesc
						else
							storeObjCurrent, storeObjTotal, storeObjText = string.match(objDesc, "(%d+)/(%d+) ?(.*)")
							storeObjCurrent = tonumber(storeObjCurrent)
							storeObjTotal = tonumber(storeObjTotal)								
						end	
						if self.db.char.taskStorage[questID] then
							if (not self.db.char.taskStorage[questID][boardIndex]) then
								self.db.char.taskStorage[questID][boardIndex] = {taskObjCurrent = storeObjCurrent, taskObjTotal = storeObjTotal, taskObjText = storeObjText}
							elseif (self.db.char.taskStorage[questID][boardIndex].taskObjCurrent ~= storeObjCurrent) then
								self.db.char.taskStorage[questID][boardIndex].taskObjCurrent = storeObjCurrent
							end
						end
					end
				--[[ Announces the progress of objectives (and Completed Quests, if Announce Type 5 is selected)]]--
					if (objType == "progressbar") then
						if percent ~= questLogStatus[questID][boardIndex].description then
							if percent > 0 then
								questLogStatus[questID][boardIndex].description = percent	
								if (progressAnnCheck(percent, questID) and self.db.profile.annType == 3) or (self.db.profile.annType == 4) or (self.db.profile.annType == 5) then	-- Run pAC() first to ensure that pbThresholds[qID] stays up to date.
									local percObjDesc = objDesc..": "..floor(percent).."%"
									if (isComplete == 1) then objComplete = true end
									oaMessageCreator(questID, percObjDesc, objComplete, level, suggestedGroup, isComplete, frequency)
								end
							--[[  Send progress to other OA users for OOR Alerts. ]]--	
								if IsInGroup() or IsInRaid() then
									oaOORSendComm(questID, boardIndex, objDesc, isTask, objType)
								end
							elseif percent == 0 then	-- Task quests report 0 when complete!
								questLogStatus[questID].complete = 1
							end
						end
					elseif objDesc ~= questLogStatus[questID][boardIndex].description then
						if objDesc then		-- objDesc sometimes returns nil
							if isTask and string.find(objDesc, "0/") then	-- Task quests report 0 when complete!
								questLogStatus[questID].complete = 1
							end							
							questLogStatus[questID][boardIndex].description = objDesc	
							if self.db.profile.annType == 4 or self.db.profile.annType == 5 then
								oaMessageCreator(questID, objDesc, objComplete, level, suggestedGroup, isComplete, frequency)
							end
						--[[  Send progress to other OA users for OOR Alerts. ]]--
							if (IsInGroup() or IsInRaid()) and (string.find(objDesc, L["slain"]) or string.find(objDesc, L["killed"])) then
								oaOORSendComm(questID, boardIndex, objDesc, isTask, objType)
							end							
						end
					end
				end
				if self.db.char.taskStorage[questID] and questLogStatus[questID].complete == 1 then	-- Prune database character task storage of unneeded data.
					self.db.char.taskStorage[questID] = nil
				end				
			end			
		end
	end
end

local function oaOnQuestLogChanged(event, ...)
	local unitID = ...
	if unitID ~= "player" then return end
	oaUpdateQuestLog()	
end

-- [[ Addon Communication Functions ]]--

local function oareceivedComm(prefix, commIn, dist, sender)
	local announceType, announceChannel = ObjAnnouncer:GetArgs(commIn, 2, 1)
	if  self.db.profile.enableCommSound and sender ~= playerName and (announceChannel == "party" or announceChannel == "raid") == true then
		PlaySoundFile(self.db.profile.commSoundFile)
	end
end

-- [[ Extra Announcements Functions ]] --

local function oaQuestAccepted(event, ...)
	local questLogIndex = ...
	oaUpdateQuestLog()
	if self.db.profile.questAccept and (not select(13,GetQuestLogTitle(questLogIndex))) then
		local qID = select(8, GetQuestLogTitle(questLogIndex))
		local acceptedLink = GetQuestLink(qID)
		local Message = L["questaccepted"].." -- "..acceptedLink
		if self.db.profile.enableAcceptFailSound then PlaySoundFile(self.db.profile.acceptSoundFile,"Master") end
		oaMessageHandler(Message, true)
	end
end

local function oaQuestTurnedIn(event, ...)
	local questID, xpReward, moneyReward = ...
		
	local questLink = (questLogStatus[questID] and questLogStatus[questID].qLink) or GetQuestLink(questID)
	--[[ Announce Quest Turn-in ]]--
	if self.db.profile.questTurnin then
		local turninMessage
		if questLogStatus[questID] and questLogStatus[questID].isTask then		
			local taskType
			if QuestUtils_IsQuestWorldQuest(questID) then
				taskType = L["worldquestcomplete"]
			else
				taskType = L["taskcomplete"]
			end			
			turninMessage = taskType.." -- "..questLink
		elseif questLink then
			turninMessage = L["questturnin"].." -- "..questLink
		else
			turninMessage = L["questturnin"].." -- "..QuestUtils_GetQuestName(questID)
		end
		if turninMessage then oaMessageHandler(turninMessage, true)	end
	end
	
	if self.db.profile.questRewards then
		if (questLogRewards[questID] and questLogRewards[questID].item.numRewards > 0) then
			if (questLogRewards[questID] and questLogRewards[questID].item.numRewards > 0) and (not questLootRecieved.questID) then
				--If QTI fires before QLR, delay sending message until QLR
				questLogRewards[questID].turnedIn = { xpReward = xpReward, moneyReward = moneyReward }
			else
				oaRewardMessageCreator( questID, xpReward, moneyReward )				
			end
		else
			oaRewardMessageCreator( questID, xpReward, moneyReward )
		end
	end
	
	if questLogStatus[questID] then
		questLogStatus[questID].complete = 1
		if not questLogStatus[questID].removed then
			questLogStatus[questID].turnedIn = true			
		else
			ClearQuestData(questID)
		end
	end
end

local function oaAutoComplete(event, ...)
	if self.db.profile.infoAutoComp then
		local qID = ...
		local qLink = GetQuestLink(qID)
		local message = L["autocompletealert"].." -- "..qLink
		oaMessageHandler(message, true)
		ShowQuestComplete(GetQuestLogIndexByID(qID))
	end
end

local function oaAcceptEscort(event, ...)
	if self.db.profile.questEscort then
		local starter, questTitle = ...
		ConfirmAcceptQuest()
		StaticPopup_Hide("QUEST_ACCEPT")
		local starterClass = select(2, UnitClass(starter))
		local classColor = RAID_CLASS_COLORS[starterClass]
		local colorStarter = "|cff"..string.format("%02X%02X%02X",classColor.r*255, classColor.g*255, classColor.b*255)..starter.."|r"
		local message = L["autoaccept1"]..": |cffffef82"..questTitle.."|r -- "..L["autoaccept2"]..": "..colorStarter
		ObjAnnouncer:Print(message)
	end
end	

local function oaQuestInfo()
	questInfoRewards =	{ questLink = GetQuestLink(GetQuestID()), item = {}, currency = {}, spell = {}, skill = {}, artifact = {} }

	questInfoRewards.item.count = GetNumQuestRewards()
	questInfoRewards.currency.count = GetNumRewardCurrencies()
	questInfoRewards.spell.count = GetNumRewardSpells()
	
	questInfoRewards.title = GetRewardTitle()
	questInfoRewards.honor = GetRewardHonor()
	
	questInfoRewards.skill.name, questInfoRewards.skill.icon, questInfoRewards.skill.points = GetRewardSkillPoints();
	questInfoRewards.artifact.XP, questInfoRewards.artifact.category = GetRewardArtifactXP();
		
	for i = 1, questInfoRewards.item.count, 1 do
		questInfoRewards.item[i] = { name = GetQuestItemInfo("reward", i) }
		questInfoRewards.item[i].link = GetQuestItemLink("reward", i) or questInfoRewards.item[i].name
		questInfoRewards.item[i].count = select(3, GetQuestItemInfo("reward", i))
	end
	
	for i = 1, questInfoRewards.currency.count, 1 do		
		local rewardcurrencyID = GetQuestCurrencyID("reward", i)
		questInfoRewards.currency[i] = { id = rewardCurrencyID }
		questInfoRewards.currency[i].count = select(3, GetQuestCurrencyInfo("reward", i))
		questInfoRewards.currency[i].link = GetCurrencyLink(rewardcurrencyID, questInfoRewards.currency[i].count)					
	end
	
	for i = 1, questInfoRewards.spell.count, 1 do
		local rewardSpellID = select(9, GetRewardSpell(i))
		questInfoRewards.spell[i] = { id = rewardSpellID }
		questInfoRewards.spell[i].link = GetSpellLink(rewardSpellID) or 
			"|cff71d5ff|Hspell:"..rewardSpellID.."|h["..select(2, GetRewardSpell(i)).."]|h|r"
	end	
end

local function oaQuestRemoved(event, ...)
	local questID =  ...
	--[[ Clear oorGroupStorage of unneeded data. ]]--
	local qIDstring = tostring(questID)			
	for k, _ in pairs(oorGroupStorage) do				
		if oorGroupStorage[k][qIDstring] then
			oorGroupStorage[k][qIDstring] = nil
		end
	end	
	--[[ Determine why quest removed. ]]--
	if questLogStatus[questID].complete == 1 then
		if questLogStatus[questID].turnedIn then	-- Completed quest, QUEST_TURNED_IN fired first			
			ClearQuestData(questID)
		else
			questLogStatus[questID].removed = true
		end
	elseif questLogStatus[questID].isTask and questLogStatus[questID].complete == nil then	-- Leaving Task area
		if self.db.profile.questTask then
			local message = L["arealeft"].." -- "..questLogStatus[questID].qLink
			oaMessageHandler(message)
		end
		questLogStatus[questID] = nil
	else--if not questLogStatus[questID].complete == 1 then
		if self.db.profile.questAbandon then
			local message = ABANDON_QUEST.." -- "..questLogStatus[questID].qLink
			oaMessageHandler(message)			
		end
		ClearQuestData(questID)
	end
	
	oaUpdateQuestLog()
end

local function oaQuestLootReceived(event, ...)
	questLootRecieved.questID, questLootRecieved.itemLink, questLootRecieved.quantity = ...	
	if questLogRewards[questLootRecieved.questID] and questLogRewards[questLootRecieved.questID].turnedIn then	-- Report rewards from here, in case QTI fired first
		oaRewardMessageCreator(questLootRecieved.questID, 
			questLogRewards[questLootRecieved.questID].turnedIn.xpReward, 
			questLogRewards[questLootRecieved.questID].turnedIn.moneyReward);
	end
	
end

	--------------------
	-- Initialization --
	--------------------

function ObjAnnouncer:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ObjectiveAnnouncerDB", defaults, true)
	self.myOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)	
		--[[ LibSink ]]--
	self.myOptions.args.libsink = self:GetSinkAce3OptionsDataTable()
	local libsink = self.myOptions.args.libsink
	libsink.name = L["selfoutput"]
	libsink.desc = L["selfoutputdesc"]
	libsink.order = 2
		--[[ Hide LibSink outputs that would conflict with public announcements ]]--
	libsink.args.Channel.hidden = true	-- If someone selected a channel here, ObjAnn messages would report to a public channel if all public channels were disabled in OA.  Best to disable this.
	libsink.args.None.hidden = true		-- We already have a way to disable ObjAnn announcements
	libsink.args.Default.hidden = true	--  Could cause ObjAnn announcements to announce to public channels...maybe.  In any case, unnecessary.
	
	self:SetSinkStorage(self.db.profile)
		
	playerName, realmName = UnitName("player")	
	
	if oorUpdated and (S.NUMVERSION > self.db.global.oorNotifyVersion) then
		StaticPopup_Show("ObjAnn_OORUPDATED")
	end	
end

function ObjAnnouncer:OnEnable()	
	oaBuildInitialTable()
	oaInitializeRewardsTable()
	
	-- [[ Hook: Get Reward Item Choice ]]--
	local origQuestRewardCompleteButton_OnClick = QuestFrameCompleteQuestButton:GetScript("OnClick")
	QuestFrameCompleteQuestButton:SetScript("OnClick", function(...)
		if QuestInfoFrame.itemChoice then
			if QuestInfoFrame.itemChoice > 0 then
				questInfoRewards.choiceLink = GetQuestItemLink("choice", QuestInfoFrame.itemChoice)
			 end
		end
		return origQuestRewardCompleteButton_OnClick(...)
	end)

	ObjAnnouncer:RegisterEvent("UNIT_QUEST_LOG_CHANGED", oaOnQuestLogChanged)
	ObjAnnouncer:RegisterEvent("QUEST_ACCEPTED", oaQuestAccepted)
	ObjAnnouncer:RegisterEvent("QUEST_COMPLETE", oaQuestInfo)
	-- QUEST_LOG_CRITERIA_UPDATE,
	ObjAnnouncer:RegisterEvent("QUEST_LOOT_RECEIVED", oaQuestLootReceived)
	ObjAnnouncer:RegisterEvent("QUEST_ACCEPT_CONFIRM", oaAcceptEscort)
	ObjAnnouncer:RegisterEvent("QUEST_AUTOCOMPLETE", oaAutoComplete)
	ObjAnnouncer:RegisterEvent("QUEST_REMOVED", oaQuestRemoved)
	ObjAnnouncer:RegisterEvent("QUEST_TURNED_IN", oaQuestTurnedIn)
	ObjAnnouncer:RegisterComm("Obj Announcer", oareceivedComm)
	ObjAnnouncer:RegisterComm("ObjA OOR", oaOORHandler)
end