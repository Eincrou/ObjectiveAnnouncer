
ObjAnnouncer = LibStub("AceAddon-3.0"):NewAddon("Objective Announcer", "AceComm-3.0", "AceEvent-3.0", "AceConsole-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local version = GetAddOnMetadata("ObjectiveAnnouncer","Version") or ""

defaults = {
	profile = {
		--[[ General ]]--
			-- Announce to --
		selftell = true,
		selftellalways = false,
		selfColor = {r = 1.0, g = 1.0, b = 1.0, hex = "|cffFFFFFF"},
		saychat = false,
		partychat = true,
		instancechat = true,
		raidchat = false,
		guildchat = false,
		officerchat = false,
		channelchat = false,
		chanName = 1,
			-- Stuff --
		questlink = true,
		addinfo = false,
		questonly = false,
		progress = false,
		questlink = true,
			--Quest Givers --
		questAccept = false,
		questTurnin = false,
		questEscort = false,
			-- Sound --
		enableSound = true,
		enableCommSound = false,
		annSoundName = "PVPFlagCapturedHorde",
		annSoundFile = "Sound\\Interface\\PVPFlagCapturedHordeMono.wav",
		compSoundName = "PVPFlagCaptured",
		compSoundFile = "Sound\\Interface\\PVPFlagCapturedMono.wav",
		commSoundName = "GM ChatWarning",
		commSoundFile = "Sound\\Interface\\GM_ChatWarning.ogg",
	}
}

function ObjAnnouncer:OnInitialize()

	objCSaved = {}
	questCSaved = {}
	objDescSaved = {}

	self.db = LibStub("AceDB-3.0"):New("ObjectiveAnnouncerDB", defaults, true)
	for boardSaved = 1, 100 do
		objCSaved[boardSaved] = {}
		objDescSaved[boardSaved] = {}
	end
	
	myOptions = {
		name = "Objective Announcer".." "..version.." |cFF7431CAby bantou|r |cFF339900(Eincrou's Update)",
		type = "group",
		childGroups = "tab",
		args = {
			options = {
				name = "General",
				type="group",
				order = 1,
				args={
					limited = {
						name = "Completed Quests Only",
						desc = "Sets whether to announce only when quests are fully completed, rather than upon completion of each objective.|n|cFFF02121(Disables 'Announce Objectives Progress')",
						type = "toggle",
						set = function(info,val) self.db.profile.questonly = val end,
						get = function(info) return self.db.profile.questonly end,
						order = 0,
					},
					progress = {
						name = "Announce Objectives Progress",
						desc = "Sets whether to announce every time you advance an objective. |n|cFF9ffbff(Example: Bear Arses: 4/12)",
						type = "toggle",
						disabled = function() return self.db.profile.questonly end,						
						set = function(info,val) self.db.profile.progress = val end,
						get = function(info) return self.db.profile.progress end,
						order = 1,
						width = "double"
					},				
					announceChannels = {
						inline = true,
						name = "|TInterface\\Icons\\Warrior_disruptingshout:18|t Announce to:",
						type="group",
						order = 2,
						args={
							header1 = {
								name = "Private Announcements",
								type = "header",
								order = 0,
								width = "double"
							},						
							mememe = {
								name = "Self",
								desc = "Sets whether to announce to yourself when no public announcements have been made.",
								type = "toggle",
								set = function(info,val) self.db.profile.selftell = val end,
								get = function(info) return self.db.profile.selftell end,
								order = 1,
								disabled = function() return self.db.profile.selftellalways end,
								width = "half"
							},
							mememealways = {
								name = "Always Self Announce",
								desc = "Announce to self even while also announcing to a group.",
								type = "toggle",
								set = function(info,val) self.db.profile.selftellalways = val end,
								get = function(info) return self.db.profile.selftellalways end,
								order = 2,
								width = "normal"
							},
							selfTextColor = {
								name = "Color for self messages",
								desc = "Choose your color.",
								type = "color",
								get = function() return self.db.profile.selfColor.r, self.db.profile.selfColor.g, self.db.profile.selfColor.b, 1.0 end,
								set = function(info, r, g, b, a)
									self.db.profile.selfColor.r, self.db.profile.selfColor.g, self.db.profile.selfColor.b = r, g, b
									self.db.profile.selfColor.hex = "|cff"..string.format("%02x%02x%02x", self.db.profile.selfColor.r * 255, self.db.profile.selfColor.g * 255, self.db.profile.selfColor.b * 255) 
									end,								
								order = 3,
							},							
							header2 = {
								name = "Public Announcements",
								type = "header",
								order = 4,
								width = "double"
							},
							say = {
								name = "|cFFFFFFFFSay",
								desc = "Sets whether to announce to Say.",
								type = "toggle",
								set = function(info,val) self.db.profile.saychat = val end,
								get = function(info) return self.db.profile.saychat end,
								order = 5,							
								width = "half"
							},
							party = {
								name = "|cFFA8A8FFParty|r",	-- /dump ChatTypeInfo.PARTY
								desc = "Sets whether to announce to Party Chat.",
								type = "toggle",
								set = function(info,val) self.db.profile.partychat = val end,
								get = function(info) return self.db.profile.partychat end,
								order = 6,
								width = "half"
							},
							instance = {
								name = "|cFFFD8100Instance",
								desc = "Sets whether to announce to Instance Chat if in a Looking For Dungeon group.",
								type = "toggle",
								set = function(info,val) self.db.profile.instancechat = val end,
								get = function(info) return self.db.profile.instancechat end,
								order = 7,
								width = "half"
							},
							raid = {
								name = "|cFFFF7F00Raid",
								desc = "Sets whether to announce to Raid Chat.",
								type = "toggle",
								set = function(info,val) self.db.profile.raidchat = val end,
								get = function(info) return self.db.profile.raidchat end,
								order = 8,
								width = "half"
							},
							guild = {
								name = "|cFF40ff40Guild",
								desc = "Sets whether to announce to Guild Chat|n|cFFF02121(Disables Officer Chat announcements).",
								type = "toggle",
								set = function(info,val) self.db.profile.guildchat = val end,
								get = function(info) return self.db.profile.guildchat end,
								order = 9,
								width = "half"
							},
							officer = {
								name = "|cFF40c040Officer",
								desc = "Sets whether to announce to Officer Chat.|n|cFF9ffbff(Only if no announcement has already been sent to Guild)",
								type = "toggle",
								disabled = function() return self.db.profile.guildchat end,
								set = function(info,val) self.db.profile.officerchat = val end,
								get = function(info) return self.db.profile.officerchat end,
								order = 10,
								width = "half",
							},
							channel = {
								name = "|cFFffc0c0Channel",
								desc = "Sets whether to announce to a channel. Please don't be rude!",
								type = "toggle",
								set = function(info,val) self.db.profile.channelchat = val end,
								get = function(info) return self.db.profile.channelchat end,
								order = 11,
							},
							channelName = {
								name = "Select a Channel",
								desc = "|n|cFF9ffbffIf you join a channel while this options menu is open, close and reopen the Interface menu to update the channels list.",
								type = "select",
								values = function()
									local ChatChannelList = {}
									for i = 1, 10 do
										local channelID = select((i*2)-1, GetChannelList())
										if channelID then
											ChatChannelList[channelID] = "|cff2E9AFE"..channelID..".|r  "..select(i*2,GetChannelList())
										end
									end
									return ChatChannelList
								end,
								set = function(info,val) self.db.profile.chanName = val end,
								get = function(info) return self.db.profile.chanName end,
								order = 12,
							},
						},
					},
					extraInfo = {
						inline = true,
						name = "|TInterface\\Icons\\inv_jewelry_trinket_15:18|t Extra Information:",
						type="group",
						order = 3,
						args={
							link = {
								name = "Quest Link for Objectives",
								desc = "Adds a clickable link of the relevant quest to your objective announcements.|n|cFF9ffbff(Completed quest announcements always contain a link)",
								type = "toggle",
								set = function(info,val) self.db.profile.questlink = val end,
								get = function(info) return self.db.profile.questlink end,
								order = 1,
								width = "double",
							},
							info = {
								name = "Additional Information",
								desc = "Adds more information to your announcements: |n|cFF9ffbff(Quest type, level & if it is a daily)",
								type = "toggle",
								set = function(info,val) self.db.profile.addinfo = val end,
								get = function(info) return self.db.profile.addinfo end,
								order = 2,
							},
						},
					},
					questGivers = {
						inline = true,
						name = "|TInterface\\Icons\\Achievement_quests_completed_08:18|t Quest Givers:",
						type="group",
						order = 4,
						args={
							accept = {
								name = "Accept a Quest",
								desc = "Make an announcement when you accept a new quest.",
								type = "toggle",
								set = function(info,val) self.db.profile.questAccept = val
									if val then ObjAnnouncer:RegisterEvent("QUEST_ACCEPTED", oaQuestAccepted)
									else ObjAnnouncer:UnregisterEvent("QUEST_ACCEPTED", oaQuestAccepted) end
								end,
								get = function(info) return self.db.profile.questAccept end,
								order = 1,
								width = "normal",
							},
							turnIn = {
								name = "Turn In a Quest",
								desc = "Make an announcement when you turn in a quest.",
								type = "toggle",
								set = function(info,val) self.db.profile.questTurnin = val 
									if val then ObjAnnouncer:RegisterEvent("QUEST_COMPLETE", oaQuestTurnin)
									else ObjAnnouncer:UnregisterEvent("QUEST_COMPLETE", oaQuestTurnin) end
								end,
								get = function(info) return self.db.profile.questTurnin end,
								order = 2,
							},
							escort = {
								name = "Auto-accept escort/event quests",
								desc = "Automatically accepts event quests started by party members.",
								type = "toggle",
								set = function(info,val) self.db.profile.questEscort = val
									if val then ObjAnnouncer:RegisterEvent("QUEST_ACCEPT_CONFIRM",oaAcceptEscort)
									else ObjAnnouncer:UnregisterEvent("QUEST_ACCEPT_CONFIRM",oaAcceptEscort) end
								end,
								get = function(info) return self.db.profile.questEscort end,
								order = 3,
								width = "double",
							},
						},
					},					
					soundOptions = {
						inline = true,
						name = "|TInterface\\Icons\\Inv_misc_archaeology_trolldrum:18|t Sound:",
						type="group",
						order = 5,
						args={
							sound = {
								name = "Completion Sounds",
								desc = "Sets whether to play sounds when announcements are made.",
								type = "toggle",
								set = function(info,val) self.db.profile.enableSound = val end,
								get = function(info) return self.db.profile.enableSound end,
								order = 1,
							},
							soundFileObj = {
								type = 'select',
								dialogControl = 'LSM30_Sound',
								values = AceGUIWidgetLSMlists.sound,
								order = 2,
								name = "Objective Complete",
								desc = "Select a sound to play when you complete an objective",
								get = function() return self.db.profile.annSoundName end,
								set = function(info, value)
									self.db.profile.annSoundName = value
									self.db.profile.annSoundFile = LSM:Fetch("sound", self.db.profile.annSoundName)									
								end,
							},
							soundFileComp = {
								type = 'select',
								dialogControl = 'LSM30_Sound',
								values = AceGUIWidgetLSMlists.sound,
								order = 3,
								name = "Quest Complete",
								desc = "Select a sound to play when you complete a quest",
								get = function() return self.db.profile.compSoundName end,
								set = function(info, value)
									self.db.profile.compSoundName = value
									self.db.profile.compSoundFile = LSM:Fetch("sound", self.db.profile.compSoundName)
									
								end,
							},
							soundComm = {
								name = "OA Communication Sounds",
								desc = "Sets whether to play a sound when other players with Objective Announcer send announcements",
								type = "toggle",
								set = function(info,val) self.db.profile.enableCommSound = val end,
								get = function(info) return self.db.profile.enableCommSound end,
								order = 4,
								width = "double",
							},	
							soundFileComm = {
								type = 'select',
								dialogControl = 'LSM30_Sound',
								values = AceGUIWidgetLSMlists.sound,
								order = 5,
								name = "OA Communication",
								desc = "Select a sound to play when another player announces an objective",
								get = function() 
									return self.db.profile.commSoundName
								end,
								set = function(info, value)
									self.db.profile.commSoundName = value
									self.db.profile.commSoundFile = LSM:Fetch("sound", self.db.profile.commSoundName)
									
								end,
							},							
						},
					},
				},
			},
		},
	}
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Objective Announcer", myOptions)
	optionsGUI = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Objective Announcer")
	myOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	
	playerName, realmName = UnitName("player")
	
	LSM:Register("sound", "PVPFlagCapturedHorde","Sound\\Interface\\PVPFlagCapturedHordeMono.wav")
	LSM:Register("sound", "PVPFlagCaptured", "Sound\\Interface\\PVPFlagCapturedMono.wav")
	LSM:Register("sound", "GM ChatWarning", "Sound\\Interface\\GM_ChatWarning.ogg")
	LSM:Register("sound", "PetBattle Defeat01", "Sound\\Interface\\UI_PetBattle_Defeat01.OGG")
end


function ObjAnnouncer:OnEnable()

	function oaeventHandler(...)
		local numEntries, numQuests = GetNumQuestLogEntries()
		if numEntries ~= EntriesSaved or numQuests ~= QuestsSaved then
			EntriesSaved, QuestsSaved = GetNumQuestLogEntries()
			for questIndex = 1, EntriesSaved do
				local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)
				if isHeader ~= 1 then
					questCSaved[questIndex] = isComplete
					for boardIndex = 1, GetNumQuestLeaderBoards(questIndex) do
						local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questIndex)
						objCSaved[questIndex][boardIndex] = objComplete
						objDescSaved[questIndex][boardIndex] = objDesc
					end
				end
			end
		else
			for questIndex = 1, numEntries do
				local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)
				if isHeader ~= 1 then
			--[[ Announcements Logic ]]-- 
				--[[ Completed Quests Only ]]--
					if self.db.profile.questonly ==  true then
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
							local compMessage = strjoin("", "QUEST COMPLETE -- ", questLink, MessageInfo)
							oaMessageHandler(compMessage,true,true,true,true)
						end
				--[[ Completed Objectives ]]--
					else
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
								if isComplete == 1 then	-- Different message if the quest is now complete.
									local objMessage = strjoin("", objDesc, " -- ", questLink, " -- QUEST COMPLETE!")
									oaMessageHandler(objMessage,true,true,true,true)
								else
									local objMessage = strjoin("", objDesc, MessageLink,  MessageInfo)
									oaMessageHandler(objMessage,true,true,true,false)
								end
						--[[ Announces the progress of objectives ]]--
							elseif self.db.profile.progress == true and objDesc ~= objDescSaved[questIndex][boardIndex] and string.find(objDesc, ": 0/") == nil then
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
								local progMessage = strjoin("", objDesc, MessageLink, MessageInfo)
								oaMessageHandler(progMessage,true,false,false,false)
							end
						end
					end
				end
			end
			EntriesSaved, QuestsSaved = GetNumQuestLogEntries()
			for questIndex = 1, EntriesSaved do
				local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)
				if isHeader ~= 1 then
					questCSaved[questIndex] = isComplete
					for boardIndex = 1, GetNumQuestLeaderBoards(questIndex) do
						local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questIndex)
						objCSaved[questIndex][boardIndex] = objComplete
						objDescSaved[questIndex][boardIndex] = objDesc
					end
				end
			end
		end
	end

	function oaMessageHandler(announcement, enableSelf, enableSound, enableComm, isComplete)
		local selfTest = 0	-- Variable to see if any conditions have fired.
		if self.db.profile.raidchat == true and IsInRaid() then
			SendChatMessage(announcement, "RAID")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest raid", "RAID") end
			selfTest = selfTest + 1
		elseif self.db.profile.instancechat and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			SendChatMessage(announcement, "INSTANCE_CHAT")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest instance", "PARTY") end
			selfTest = selfTest + 1
		elseif self.db.profile.partychat and IsInGroup(LE_PARTY_CATEGORY_HOME) then
			SendChatMessage(announcement, "PARTY")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest party", "PARTY") end
			selfTest = selfTest + 1
		elseif self.db.profile.saychat and UnitIsDeadOrGhost("player") == nil then
			SendChatMessage(announcement, "SAY")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest say", "PARTY") end
			selfTest = selfTest + 1	
		end
		if self.db.profile.guildchat and IsInGuild() then
			SendChatMessage(announcement, "GUILD")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest guild", "GUILD") end
			selfTest = selfTest + 1
		elseif self.db.profile.officerchat and CanViewOfficerNote() then
			SendChatMessage(announcement, "OFFICER")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest officer", "GUILD") end
			selfTest = selfTest + 1
		end
		if self.db.profile.channelchat then
			SendChatMessage(announcement, "CHANNEL", nil, self.db.profile.chanName)
			selfTest = selfTest + 1
		end
		if enableSelf then
			if self.db.profile.selftellalways then
				local announcementSelf = string.gsub(announcement, "|r", "|r"..self.db.profile.selfColor.hex)
				DEFAULT_CHAT_FRAME:AddMessage(self.db.profile.selfColor.hex..announcementSelf)
			elseif self.db.profile.selftell and selfTest == 0 then
				local announcementSelf = string.gsub(announcement, "|r", "|r"..self.db.profile.selfColor.hex)
				DEFAULT_CHAT_FRAME:AddMessage(self.db.profile.selfColor.hex..announcementSelf)
			end
		end
		if enableSound and self.db.profile.enableSound then
			if isComplete then
				PlaySoundFile(self.db.profile.compSoundFile,"Master")
			else
				PlaySoundFile(self.db.profile.annSoundFile,"Master")
			end
		end
	end
	
	function oacommandHandler(str)
		InterfaceOptionsFrame_OpenToCategory(optionsGUI)
	end

	function oareceivedComm(prefix, commIn, dist, sender)
		local announceType, announceChannel = ObjAnnouncer:GetArgs(commIn, 2, 1)
		if (announceChannel == "party" or announceChannel == "raid") and self.db.profile.enableCommSound == true and sender ~= playerName then
			PlaySoundFile(self.db.profile.commSoundFile)
		end
	end

	function oaQuestAccepted(event, ...)
		local questLogIndex = ...
		local acceptedLink = GetQuestLink(questLogIndex)
		local Message = "Quest Accepted -- "..acceptedLink
		oaMessageHandler(Message)
	end

	function oaQuestTurnin(event, ...)
		if event == "QUEST_COMPLETE" then 
			qidComplete = GetQuestID()
			turnLink = GetQuestLink(GetQuestLogIndexByID(qidComplete))
			ObjAnnouncer:RegisterEvent("QUEST_LOG_UPDATE", oaQuestTurnin)	-- Temporarily send QLU events here.
		end
		if event == "QUEST_LOG_UPDATE" then
			local logIndex = GetQuestLogIndexByID(qidComplete)
			if  logIndex == 0 and turnLink ~= nil then -- Checks to see if the quest that fired the QUEST_COMPLETE event is no longer in the quest log.
				local Message = "Quest Turned In -- "..turnLink
				oaMessageHandler(Message)
			end
		ObjAnnouncer:RegisterEvent("QUEST_LOG_UPDATE", oaeventHandler)	-- Send QLU events back to the main handler.
		end
	end
	
	function oaAcceptEscort(event, ...)
		local starter, questTitle = ...
		ConfirmAcceptQuest()
		StaticPopup_Hide("QUEST_ACCEPT")
		local Message = "|cff33ff99Objective Announcer|r: Automatically accepted: |cffffef82"..questTitle.."|r -- Started by: "..starter
		DEFAULT_CHAT_FRAME:AddMessage(Message)
	end
	
	ObjAnnouncer:RegisterEvent("QUEST_LOG_UPDATE", oaeventHandler)
	if self.db.profile.questAccept then ObjAnnouncer:RegisterEvent("QUEST_ACCEPTED", oaQuestAccepted) end
	if self.db.profile.questTurnin then ObjAnnouncer:RegisterEvent("QUEST_COMPLETE", oaQuestTurnin)	end
	if self.db.profile.questEscort then ObjAnnouncer:RegisterEvent("QUEST_ACCEPT_CONFIRM", oaAcceptEscort) end
	ObjAnnouncer:RegisterChatCommand("oa", oacommandHandler)
	ObjAnnouncer:RegisterChatCommand("obja", oacommandHandler)
	ObjAnnouncer:RegisterComm("Obj Announcer", oareceivedComm)
	DEFAULT_CHAT_FRAME:AddMessage("|cffcc33ffObjective Announcer".." "..version.." Loaded.  Type /oa for Options.|r")
end