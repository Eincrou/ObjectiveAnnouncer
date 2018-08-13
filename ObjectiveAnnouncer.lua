local NAME, S = ...
S.VERSION = GetAddOnMetadata(NAME, "Version")
S.NUMVERSION = 6031	-- 6.0.3a
S.NAME = "Objective Announcer v"..S.VERSION
ObjAnnouncer = LibStub("AceAddon-3.0"):NewAddon("Objective Announcer", "AceComm-3.0", "AceEvent-3.0", "AceConsole-3.0", "LibSink-2.0")
	
	---------------------
	-- Local Variables --
	---------------------
local oorUpdated = true
	
local self = ObjAnnouncer
local pairs = pairs
local tostring = tostring
local floor = math.floor

local playerName, realmName
local objCSaved = {}
local questCSaved = {}
local objDescSaved = {}
local oorGroupStorage = {}
local qidComplete = 0
local turnLink = nil
local pbThresholds = {}

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
		questAccept = false, questTurnin = false, questEscort = false, infoAutoComp = false, questFail = false,	questTask = false,
			-- Sound --
		enableCompletionSound = true, enableCommSound = false, enableAcceptFailSound = false,
		annSoundName = "PVPFlagCapturedHorde", annSoundFile = "Sound\\Interface\\PVPFlagCapturedHordeMono.wav",
		compSoundName = "PVPFlagCaptured", compSoundFile = "Sound\\Interface\\PVPFlagCapturedMono.wav",
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
  text = "Objective Announcer's Out-of-range feature has been updated. Please have your group members update to "..S.NAME.." to prevent errors.",
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

	-- [[ Message Functions ]] --

local function oaMessageHandler(announcement, enableSelf, enableSound, enableComm, isComplete, oorAlert)
	local selfTest = true	-- Variable to see if any conditions have fired.
	if self.db.profile.raidchat == true and IsInRaid() then
		SendChatMessage(announcement, "RAID")
		if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest raid", "RAID") end
		selfTest = false
	elseif self.db.profile.instancechat and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
		SendChatMessage(announcement, "INSTANCE_CHAT")
		if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest instance", "PARTY") end
		selfTest = false
	elseif self.db.profile.partychat and IsInGroup(LE_PARTY_CATEGORY_HOME) then
		SendChatMessage(announcement, "PARTY")
		if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest party", "PARTY") end
		selfTest = false
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
--	if enableSelf then	-- Every announcement message is currently enabled for self reporting, so this test is unnecessary.  It might be useful in the future though, so I'll just comment it out.
		if self.db.profile.selftellalways then
			ObjAnnouncer:Pour(announcement, self.db.profile.selfColor.r, self.db.profile.selfColor.g, self.db.profile.selfColor.b)
		elseif self.db.profile.selftell and selfTest then
			ObjAnnouncer:Pour(announcement, self.db.profile.selfColor.r, self.db.profile.selfColor.g, self.db.profile.selfColor.b)
		end
--	end
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

local function oaMessageCreator(questIndex, questID, objDesc, objComplete, level, suggestedGroup, isComplete, frequency)

	local divider = false
	local questLink = GetQuestLink(questIndex)
	if self.db.profile.questlink then
		messageInfoLink = strjoin("", "  --  ", questLink)
	else
		messageInfoLink = ""
	end
	if (suggestedGroup > 0) and self.db.profile.infoSuggGroup then		
		messageInfoSuggGroup = strjoin("", " [Group: ", suggestedGroup, "]")
		divider = true
	else
		messageInfoSuggGroup = ""
	end
	if (frequency > 1) and self.db.profile.infoFrequency then
		if frequency == 2 then messageInfoFrequency = " Daily" elseif frequency == 3 then messageInfoFrequency = " Weekly" end
		divider = true
	else
		messageInfoFrequency = ""
	end
	if self.db.profile.infoTag then
		local tagID, tagName = GetQuestTagInfo(questID)
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
		finalAnnouncement = "QUEST COMPLETE -- "..questLink..infoDivider..messageInfoSuggGroup..messageInfoFrequency..messageInfoTag..messageInfoLevel	-- This announcement type ignores self.db.profile.questlink to ensure that a quest link is always displayed.
	else
		finalAnnouncement = objDesc..messageInfoLink..infoDivider..messageInfoSuggGroup..messageInfoFrequency..messageInfoLevel
		if (self.db.profile.annType == 3 or self.db.profile.annType == 5) and isComplete == 1 then
			finalAnnouncement = finalAnnouncement.." -- QUEST COMPLETE"
		end
	end
	oaMessageHandler(finalAnnouncement, true, objComplete, objComplete, isComplete)
end	

local function progressAnnCheck(percent, questID)	-- Check progress bar announcement interval to see if we should make an announcement.
	local makeAnnounce = false
	local interval = self.db.profile.progBarInterval
	if not pbThresholds[questID] then
		pbThresholds[questID] = interval
	end
	if percent >= pbThresholds[questID] then
		pbThresholds[questID] = (floor(percent / interval) * interval) + interval
		makeAnnounce = true
	end	
	return makeAnnounce
end

-- [[ Addon Communication Functions ]]--

local function oareceivedComm(prefix, commIn, dist, sender)
	local announceType, announceChannel = ObjAnnouncer:GetArgs(commIn, 2, 1)
	if  self.db.profile.enableCommSound and sender ~= playerName and (announceChannel == "party" or announceChannel == "raid") == true then
		PlaySoundFile(self.db.profile.commSoundFile)
	end
end

-- [[ Out-Of-Range Functions ]] 

local function oaOORHandler(prefix, text, dist, groupMember)
	if groupMember ~= playerName then
		local oorQuestID, oorObjCurrent, oorObjTotal, oorObjText, oorBoardIndex, isTask, _ = strsplit("\a", text, 7)
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
			
			if (myObjComplete == false) and ((isTask == "false") or validTaskInfo) then	-- Don't execute if we're already done with the objective. If no saved data about a task, do something else.				
				if not oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] then
					oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] = {savedDelta = oorObjCurrent - myObjCurrent}
				end
				local currentDelta = oorObjCurrent - myObjCurrent		
				if (currentDelta > oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta) then	-- If current delta increased over previous delta, we missed an objective. If delta decreased, do nothing.
					local qlink = GetQuestLink(myLogIndex) or self.db.char.taskStorage[questID].taskQuestLink
					local announcement = groupMember.."'s Objective Credit Not Received: \""..myObjText.."\" -- "..qlink
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
end

local function oaOORSendComm(questLogIndex, questID, boardIndex, objDesc, isTask, objType)
	local objCurrent, objTotal, objText
	local reserved = ""	-- Reserving function parameters so any future OOR additional functionality doesn't break players using previous versions.
	local chanType = "RAID"	-- "RAID" sends messages to party if not in raid, but check to be sure.									
	if IsInGroup() and (not IsInRaid()) then chanType = "PARTY" end
--	chanType = "GUILD"	--debug
	if (objType == "progressbar") then
		objCurrent = tostring(GetQuestProgressBarPercent(questID))
		objTotal = "100"
		objText = objDesc
	else
		objCurrent, objTotal, objText = string.match(objDesc, "(%d+)/(%d+) ?(.*)")
	end
	oorCommMessage = strjoin("\a", questID, objCurrent, objTotal, objText, boardIndex, tostring(isTask), reserved)								
	ObjAnnouncer:SendCommMessage("ObjA OOR", oorCommMessage, chanType)	
end

-- [[ Extra Announcements Functions ]] --

local function oaQuestAccepted(event, ...)
	local questLogIndex = ...
	if self.db.profile.questAccept then		
		local acceptedLink = GetQuestLink(questLogIndex)
		local Message = "Quest Accepted -- "..acceptedLink
		if self.db.profile.enableAcceptFailSound then PlaySoundFile(self.db.profile.acceptSoundFile,"Master") end
		oaMessageHandler(Message, true)
	end
end

local function oaQuestTurnin(event, ...)
	if self.db.profile.questTurnin then
		qidComplete = GetQuestID()
		turnLink = GetQuestLink(GetQuestLogIndexByID(qidComplete))
	end
end

local function oaAutoComplete(event, ...)
	if self.db.profile.infoAutoComp then
		local acID = ...
		local qIndex = GetQuestLogIndexByID(acID)
		local qLink = GetQuestLink(qIndex)
		local message = "AUTO-COMPLETE ALERT -- "..qLink
		oaMessageHandler(message, true)
		ShowQuestComplete(qIndex)	-- Automatically brings up the quest turn-in dialog window.
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
		local Message = "Automatically accepted: |cffffef82"..questTitle.."|r -- Started by: "..colorStarter
		ObjAnnouncer:Print(Message)
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
	libsink.name = "Self Outputs"
	libsink.desc = "Select where to send your ObjAnn messages."
	libsink.order = 2
		--[[ Hide LibSink outputs that would conflict with public announcements ]]--
	libsink.args.Channel.hidden = true	-- If someone selected a channel here, ObjAnn messages would report to a public channel if all public channels were disabled in OA.  Best to disable this.
	libsink.args.None.hidden = true		-- We already have a way to disable ObjAnn announcements
	libsink.args.Default.hidden = true	--  Could cause ObjAnn announcements to announce to public channels...maybe.  In any case, unnecessary.
	
	self:SetSinkStorage(self.db.profile)

	for boardSaved = 1, 100 do
		objCSaved[boardSaved] = {}
		objDescSaved[boardSaved] = {}
	end
		
	playerName, realmName = UnitName("player")	
	
	if oorUpdated and (S.NUMVERSION > self.db.global.oorNotifyVersion) then
		StaticPopup_Show("ObjAnn_OORUPDATED")
	end
end

function ObjAnnouncer:OnEnable()
	function oaeventHandler(event, ...)
		local logIndex = GetQuestLogIndexByID(qidComplete)
		if  logIndex == 0 then -- Checks to see if the quest that fired the QUEST_COMPLETE event is no longer in the quest log.
			local qIDstring = tostring(qidComplete)		
			--[[ Clear oorGroupStorage of unneeded data. ]]--
			for k, _ in pairs(oorGroupStorage) do				
				if oorGroupStorage[k][qIDstring] then
					oorGroupStorage[k][qIDstring] = nil
				end
			end
			--[[ Announce Quest Turn-in ]]--
			if self.db.profile.questTurnin and turnLink ~= nil then
				local Message = "Quest Turned In -- "..turnLink
				oaMessageHandler(Message, true)
				turnLink = nil
			end
		end
		local numEntries, numQuests = GetNumQuestLogEntries()
		if numEntries ~= EntriesSaved or numQuests ~= QuestsSaved then
			EntriesSaved, QuestsSaved = GetNumQuestLogEntries()
			for questIndex = 1, EntriesSaved do
				local questTitle, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle(questIndex)
				if isHeader ~= 1 then
					questCSaved[questIndex] = isComplete
					for boardIndex = 1, GetNumQuestLeaderBoards(questIndex) do
						local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questIndex)
						objCSaved[questIndex][boardIndex] = objComplete
						if (objType == "progressbar") then
							objDescSaved[questIndex][boardIndex] = GetQuestProgressBarPercent(questID)
						else						
							objDescSaved[questIndex][boardIndex] = objDesc
						end
						if isTask then
							local questLink = GetQuestLink(questIndex)
							if (not self.db.char.taskStorage[questID]) then
								self.db.char.taskStorage[questID] = {taskQuestLink = questLink}
							end											
							if (IsInGroup() or IsInRaid()) and ((objType == "progressbar") or string.find(objDesc, "slain") or string.find(objDesc, "killed")) then -- Send initial OOR when picking up a new task
								oaOORSendComm(questIndex, questID, boardIndex, objDesc, isTask, objType)
							end
						end						
					end
					if isTask and self.db.profile.questTask then
						local questLink = GetQuestLink(questIndex)
						local taskMessage = questLink.." -- AREA ENTERED"
						oaMessageHandler(taskMessage, true, false, false, isComplete)
					end					
				end
			end
		--	flagQuestTurnin = false
		else
			for questIndex = 1, numEntries do
				local questTitle, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle(questIndex)
				if isHeader ~= 1 then
			--[[ Announcements Logic ]]-- 
				--[[ Failed Quests ]]--
					if isComplete == -1 and self.db.profile.questFail and isComplete ~= questCSaved[questIndex] then
						questCSaved[questIndex] = isComplete
						local questLink = GetQuestLink(questIndex)
						local failedMessage = questLink.." -- QUEST FAILED"
						oaMessageHandler(failedMessage, true, false, false, isComplete)
					end
				--[[ Completed Quests Only ]]--
					if isComplete == 1 and isComplete ~= questCSaved[questIndex] then						
						questCSaved[questIndex] = isComplete
						if self.db.profile.annType ==  1 then
							oaMessageCreator(questIndex, questID, nil, true, level, suggestedGroup, isComplete, frequency)
						end
					end
				--[[ Completed Objectives (and Completed Quests, if Announce Type 3 is selected) ]]--
					for boardIndex = 1, GetNumQuestLeaderBoards(questIndex) do
						local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questIndex)
						local percent = nil
						if (objType == "progressbar") then percent = GetQuestProgressBarPercent(questID) end
						if (objComplete) and objComplete ~= objCSaved[questIndex][boardIndex] then
							objCSaved[questIndex][boardIndex] = objComplete
							if self.db.profile.annType == 2 or self.db.profile.annType == 3 then					
								oaMessageCreator(questIndex, questID, objDesc, objComplete, level, suggestedGroup, isComplete, frequency)
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
							if (not self.db.char.taskStorage[questID][boardIndex]) then
								self.db.char.taskStorage[questID][boardIndex] = {taskObjCurrent = storeObjCurrent, taskObjTotal = storeObjTotal, taskObjText = storeObjText}
							elseif (self.db.char.taskStorage[questID][boardIndex].taskObjCurrent ~= storeObjCurrent) then
								self.db.char.taskStorage[questID][boardIndex].taskObjCurrent = storeObjCurrent
							end							
						end
					--[[ Announces the progress of objectives (and Completed Quests, if Announce Type 5 is selected)]]--
						if (objType == "progressbar") then
							if percent ~= objDescSaved[questIndex][boardIndex] then
								if percent > 0 then
									objDescSaved[questIndex][boardIndex] = percent	
									if (progressAnnCheck(percent, questID) and (self.db.profile.annType == 3) or (self.db.profile.annType == 4) or (self.db.profile.annType == 5)) then	-- Run pAC() first to ensure that pbThresholds[qID] stays up to date.
										local percObjDesc = objDesc..": "..floor(percent).."%"
										oaMessageCreator(questIndex, questID, percObjDesc, objComplete, level, suggestedGroup, isComplete, frequency)
									end
								--[[  Send progress to other OA users for OOR Alerts. ]]--	
									if IsInGroup() or IsInRaid() then
										oaOORSendComm(questIndex, questID, boardIndex, objDesc, isTask, objType)
									end
								end
							end
						elseif objDesc ~= objDescSaved[questIndex][boardIndex] then
							if not string.find(objDesc, ": 0/") then
								objDescSaved[questIndex][boardIndex] = objDesc	
								if self.db.profile.annType == 4 or self.db.profile.annType == 5 then
									oaMessageCreator(questIndex, questID, objDesc, objComplete, level, suggestedGroup, isComplete, frequency)
								end
							end
						--[[  Send progress to other OA users for OOR Alerts. ]]--
							if (IsInGroup() or IsInRaid()) and (string.find(objDesc, "slain") or string.find(objDesc, "killed")) then
								oaOORSendComm(questIndex, questID, boardIndex, objDesc, isTask, objType)
							end
						end
					end
					if self.db.char.taskStorage[questID] and (isComplete == 1) then	-- Prune database character task storage of unneeded data.
						self.db.char.taskStorage[questID] = nil
					end
				end
			end
		end		
	end
	--ObjAnnouncer:RegisterEvent("QUESTTASK_UPDATE", oqTaskUpdateHandler)
	ObjAnnouncer:RegisterEvent("QUEST_LOG_UPDATE", oaeventHandler)
	ObjAnnouncer:RegisterEvent("QUEST_ACCEPTED", oaQuestAccepted)
	ObjAnnouncer:RegisterEvent("QUEST_COMPLETE", oaQuestTurnin)
	ObjAnnouncer:RegisterEvent("QUEST_ACCEPT_CONFIRM", oaAcceptEscort)
	ObjAnnouncer:RegisterEvent("QUEST_AUTOCOMPLETE", oaAutoComplete)
	ObjAnnouncer:RegisterComm("Obj Announcer", oareceivedComm)
	ObjAnnouncer:RegisterComm("ObjA OOR", oaOORHandler)	-- Always enabled so group objective progress can be recorded. This allows OOR alerts to work immediately upon being enabled.
end