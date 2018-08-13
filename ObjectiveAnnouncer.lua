
ObjAnnouncer = LibStub("AceAddon-3.0"):NewAddon("Objective Announcer", "AceComm-3.0", "AceEvent-3.0", "AceConsole-3.0")

defaults = {
	profile = {
		questlink = true,
		partychat = true,
		raidchat = false,
		guildchat = false,
		officerchat = false,
		addinfo = true,
		questonly = false,
		enableSound = true,
		selftell = false
	}
}


function ObjAnnouncer:OnInitialize()

	objCSaved = {}
	questCSaved = {}

	self.db = LibStub("AceDB-3.0"):New("ObjectiveAnnouncerDB", defaults, true)
	for boardSaved = 1, 100 do
		objCSaved[boardSaved] = {}
	end
	myOptions = {
		type = "group",
		args = {
			mememe = {
				name = "Announce to Self",
				desc = "Sets whether to announce to yourself",
				type = "toggle",
				set = function(info,val) self.db.profile.selftell = val end,
				get = function(info) return self.db.profile.selftell end,
				order = 0,
				width = "double"
			},
			party = {
				name = "Announce to Party",
				desc = "Sets whether to announce to Party Chat",
				type = "toggle",
				set = function(info,val) self.db.profile.partychat = val end,
				get = function(info) return self.db.profile.partychat end,
				order = 1,
				width = "double"
			},
			raid = {
				name = "Announce to Raid",
				desc = "Sets whether to announce to Raid Chat",
				type = "toggle",
				set = function(info,val) self.db.profile.raidchat = val end,
				get = function(info) return self.db.profile.raidchat end,
				order = 2,
				width = "double"
			},
			guild = {
				name = "Announce to Guild",
				desc = "Sets whether to announce to Guild Chat",
				type = "toggle",
				set = function(info,val) self.db.profile.guildchat = val end,
				get = function(info) return self.db.profile.guildchat end,
				order = 3,
				width = "double"
			},
			officer = {
				name = "Announce to Officers",
				desc = "Sets whether to announce to Officer Chat",
				type = "toggle",
				set = function(info,val) self.db.profile.officerchat = val end,
				get = function(info) return self.db.profile.officerchat end,
				order = 4,
				width = "double"
			},
			link = {
				name = "Quest Link",
				desc = "Sets whether to include a quest link in objective announcements",
				type = "toggle",
				set = function(info,val) self.db.profile.questlink = val end,
				get = function(info) return self.db.profile.questlink end,
				order = 5,
				width = "double"
			},
			info = {
				name = "Additional Information",
				desc = "Sets whether to include additional quest information in announcements",
				type = "toggle",
				set = function(info,val) self.db.profile.addinfo = val end,
				get = function(info) return self.db.profile.addinfo end,
				order = 6,
				width = "double"
			},
			limited = {
				name = "Announce Completed Quests Only",
				desc = "Sets whether to announce only completed quests, rather than completed objectives",
				type = "toggle",
				set = function(info,val) self.db.profile.questonly = val end,
				get = function(info) return self.db.profile.questonly end,
				order = 7,
				width = "double"
			},
			sound = {
				name = "Enable Sounds",
				desc = "Sets whether to play sounds when announcements are made and received (Self, Party and Raid only)",
				type = "toggle",
				set = function(info,val) self.db.profile.enableSound = val end,
				get = function(info) return self.db.profile.enableSound end,
				order = 8,
				width = "double"
			}
		}
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Objective Announcer", myOptions)
	optionsGUI = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Objective Announcer")
	local Faction, localizedFaction = UnitFactionGroup("player")
	if Faction == "Horde" then
		soundIn = "Sound\\Interface\\PVPFlagTakenHordeMono.wav"
		soundOut = "Sound\\Interface\\PVPFlagCapturedHordeMono.wav"
	else
		soundIn = "Sound\\Interface\\PVPFlagTakenMono.wav"
		soundOut = "Sound\\Interface\\PVPFlagCapturedMono.wav"
	end
	playerName, realmName = UnitName("player")
end


function ObjAnnouncer:OnEnable()

function oaeventHandler(...)
	local numEntries, numQuests = GetNumQuestLogEntries()
	if numEntries ~= EntriesSaved or numQuests ~= QuestsSaved then
		EntriesSaved, QuestsSaved = GetNumQuestLogEntries()
		for questIndex = 1, EntriesSaved do
			local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(questIndex)
			if isHeader ~= 1 then
				questCSaved[questIndex] = isComplete
				for boardIndex = 1, GetNumQuestLeaderBoards(questIndex) do
					local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questIndex)
					objCSaved[questIndex][boardIndex] = objComplete
				end
			end
		end
	else
		for questIndex = 1, numEntries do
			local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(questIndex)
			if isHeader ~= 1 then
				if self.db.profile.questonly ==  true then
					soundAnnounce = false
					if (isComplete) and isComplete ~= questCSaved[questIndex] then
						if self.db.profile.addinfo == true then
							if (isDaily) then
								InfoDaily = " Daily"
							else
								InfoDaily = ""
							end
							questLevel = tostring(level)
							InfoLevel = strjoin("", " [", questLevel, "]")
							if (questTag) then
								InfoType = strjoin("", " ", questTag)
							else
								InfoType = ""
							end
							MessageInfo = strjoin("", "  -- ", InfoType, InfoDaily, InfoLevel)
						else
							MessageInfo = ""
						end
						questLink = GetQuestLink(questIndex)
						Message = strjoin("", "Completed quest: ", questLink, MessageInfo)
						if self.db.profile.selftell == true then
							DEFAULT_CHAT_FRAME:AddMessage(Message)
							soundAnnounce = true
						end
						if self.db.profile.raidchat == true and (IsInRaid()) then
							SendChatMessage(Message, "RAID", nil, nil)
							soundAnnounce = true
							ObjAnnouncer:SendCommMessage("Obj Announcer", "quest raid", "RAID")
						elseif self.db.profile.partychat == true and (IsInGroup()) and IsInRaid() == false then
							SendChatMessage(Message, "PARTY", nil, nil)
							soundAnnounce = true
							ObjAnnouncer:SendCommMessage("Obj Announcer", "quest party", "PARTY")
						end
						if self.db.profile.guildchat == true and (IsInGuild()) then
							SendChatMessage(Message, "GUILD", nil, nil)
							ObjAnnouncer:SendCommMessage("Obj Announcer", "quest guild", "GUILD")
						elseif self.db.profile.officerchat == true and (CanViewOfficerNote()) then
							SendChatMessage(Message, "OFFICER", nil, nil)
							ObjAnnouncer:SendCommMessage("Obj Announcer", "quest officer", "GUILD")
						end
					end
					if soundAnnounce == true and self.db.profile.enableSound == true then
						PlaySoundFile(soundOut)
					end
				else
					soundAnnounce = false
					for boardIndex = 1, GetNumQuestLeaderBoards(questIndex) do
						local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questIndex)
						if (objComplete) and objComplete ~= objCSaved[questIndex][boardIndex] then
							if self.db.profile.questlink == true then
								questLink = GetQuestLink(questIndex)
								MessageLink = strjoin("", "  --  ", questLink)
							else
								MessageLink = ""
							end
							if self.db.profile.addinfo == true then
								if (isDaily) then
									InfoDaily = " Daily"
								else
									InfoDaily = ""
								end
								local temp = tostring(level)
								InfoLevel = strjoin("", " [", temp, "]")
								if (questTag) then
									InfoType = strjoin("", " ", questTag)
								else
									InfoType = ""
								end
								MessageInfo = strjoin("", "  -- ", InfoType, InfoDaily, InfoLevel)
							else
								MessageInfo = ""
							end
							Message = strjoin("", objDesc, MessageLink, MessageInfo)
							if self.db.profile.selftell == true then
								DEFAULT_CHAT_FRAME:AddMessage(Message)
								soundAnnounce = true
							end
							if self.db.profile.raidchat == true and (IsInRaid()) then
								SendChatMessage(Message, "RAID", nil, nil)
								soundAnnounce = true
								ObjAnnouncer:SendCommMessage("Obj Announcer", "objective raid", "RAID")
							elseif self.db.profile.partychat == true and (IsInGroup()) and IsInRaid() == false then
								SendChatMessage(Message, "PARTY", nil, nil)
								soundAnnounce = true
								ObjAnnouncer:SendCommMessage("Obj Announcer", "objective party", "PARTY")
							end
							if self.db.profile.guildchat == true and (IsInGuild()) then
								SendChatMessage(Message, "GUILD", nil, nil)
								ObjAnnouncer:SendCommMessage("Obj Announcer", "objective guild", "GUILD")
							elseif self.db.profile.officerchat == true and (CanViewOfficerNote()) then
								SendChatMessage(Message, "OFFICER", nil, nil)
								ObjAnnouncer:SendCommMessage("Obj Announcer", "objective officer", "GUILD")
							end
						end
					end
					if soundAnnounce == true and self.db.profile.enableSound == true then
						PlaySoundFile(soundOut)
					end
				end
			end
		end
		EntriesSaved, QuestsSaved = GetNumQuestLogEntries()
		for questIndex = 1, EntriesSaved do
			local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(questIndex)
			if isHeader ~= 1 then
				questCSaved[questIndex] = isComplete
				for boardIndex = 1, GetNumQuestLeaderBoards(questIndex) do
					local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questIndex)
					objCSaved[questIndex][boardIndex] = objComplete
				end
			end
		end
	end
end

function oacommandHandler(str)
	InterfaceOptionsFrame_OpenToCategory(optionsGUI)
end

function oareceivedComm(prefix, commIn, dist, sender)
	local announceType, announceChannel = ObjAnnouncer:GetArgs(commIn, 2, 1)
	if (announceChannel == "party" or announceChannel == "raid") and self.db.profile.enableSound == true and sender ~= playerName then
		PlaySoundFile(soundIn)
	end
end


	ObjAnnouncer:RegisterEvent("QUEST_LOG_UPDATE", oaeventHandler);
	ObjAnnouncer:RegisterChatCommand("oa", oacommandHandler);
	ObjAnnouncer:RegisterChatCommand("obja", oacommandHandler);
	ObjAnnouncer:RegisterComm("Obj Announcer", oareceivedComm)
	DEFAULT_CHAT_FRAME:AddMessage("|cffcc33ffObjective Announcer 5.1.0 Loaded.  Type /oa for Options.|r")
end

