
ObjAnnouncer = LibStub("AceAddon-3.0"):NewAddon("Objective Announcer", "AceComm-3.0", "AceEvent-3.0", "AceConsole-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local version = GetAddOnMetadata("ObjectiveAnnouncer","Version") or ""

defaults = {
	profile = {
		questlink = true,
		saychat = false,
		partychat = true,
		instancechat = true,
		raidchat = false,
		guildchat = false,
		officerchat = false,
		channelchat = false,
		chanName = 1,
		addinfo = false,
		questonly = false,
		progress = false,
		questlink = true,
		enableSound = true,
		enableCommSound = false,
		selftell = true,
		selftellalways = false,
		annSoundName = "PVPFlagCapturedHordeMono",
		compSoundName = "PVPFlagCapturedMono",
		commSoundName = "GM_ChatWarning"
	}
}

function ObjAnnouncer:OnInitialize()

	objCSaved = {}
	questCSaved = {}
	objDescSaved = {}

	self.db = LibStub("AceDB-3.0"):New("ObjectiveAnnouncerDB", defaults, true)
	for boardSaved = 1, 100 do
		objCSaved[boardSaved] = {}
	end
	for boardSaved = 1, 100 do
		objDescSaved[boardSaved] = {}
	end
	
	
	myOptions = {
		name = "Objective Announcer".." "..version.." |cFF7431CAby bantou|r |cFF339900(Eincrou's Update)",
		type = "group",
		childGroups = "tab",
		args = {
			options = {
				name = "Options",
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
						--width = "double"
					},
					progress = {
						name = "Announce Objectives Progress |cFFF02121¡SPAM WARNING!",
						desc = "Sets whether to announce every time you advance an objective. |n|cFF2AF2F5(Example: Bear Arses: 4/12)",
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
							mememe = {
								name = "Self",
								desc = "Sets whether to announce to yourself when no public announcements have been made.",
								type = "toggle",
								set = function(info,val) self.db.profile.selftell = val end,
								get = function(info) return self.db.profile.selftell end,
								order = 0,
								disabled = function() return self.db.profile.selftellalways end,
								width = "half"
							},
							mememealways = {
								name = "Always Self Announce",
								desc = "Announce to self even while also announcing to a group.",
								type = "toggle",
								set = function(info,val) self.db.profile.selftellalways = val end,
								get = function(info) return self.db.profile.selftellalways end,
								order = 1,
								width = "normal"
							},
							header1 = {
								name = "Public Announcements",
								type = "header",
								order = 2,
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
								name = "|cFFA8A8FFParty|r",
								desc = "Sets whether to announce to Party Chat.",
								type = "toggle",
								set = function(info,val) self.db.profile.partychat = val end,
								get = function(info) return self.db.profile.partychat end,
								order = 6,
								width = "half"
							},
							instance = {
								name = "|cFFFD8100Instance|r",
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
								name = "|cFF38DF39Guild",
								desc = "Sets whether to announce to Guild Chat|n|cFFF02121(Disables Officer Chat announcements).",
								type = "toggle",
								set = function(info,val) self.db.profile.guildchat = val end,
								get = function(info) return self.db.profile.guildchat end,
								order = 9,
								width = "half"
							},
							officer = {
								name = "|cFF40c040Officer",
								desc = "Sets whether to announce to Officer Chat.|n(Only if no announcement has already been sent to Guild)",
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
								desc = "Choose a channel. |nIf you join a channel while this options menu is open, close and reopen this menu to update the channels list.",
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
						name = "|TInterface\\Icons\\INV_Misc_Note_01:18|t Extra Information:",
						type="group",
						order = 3,
						args={
							link = {
								name = "Quest Link for Objectives",
								desc = "Adds a clickable link of the relevant quest to your objective announcements.|n(Completed quest announcements always contain a link)",
								type = "toggle",
								set = function(info,val) self.db.profile.questlink = val end,
								get = function(info) return self.db.profile.questlink end,
								order = 1,
								width = "double",
							},
							info = {
								name = "Additional Information",
								desc = "Adds more information to your announcements: |n(Quest type, level & if it is a daily)",
								type = "toggle",
								set = function(info,val) self.db.profile.addinfo = val end,
								get = function(info) return self.db.profile.addinfo end,
								order = 2,
							},
						},
					},
					soundOptions = {
						inline = true,
						name = "|TInterface\\Icons\\Inv_misc_archaeology_trolldrum:18|t Sound:",
						type="group",
						order = 4,
						args={
							sound = {
								name = "Completion Sounds",
								desc = "Sets whether to play sounds when announcements are made and received.|n(Self, Say, |cFFA8A8FFParty, |cFFFD8100Instance|r and |cFFFF7F00Raid only)",
								type = "toggle",
								set = function(info,val) self.db.profile.enableSound = val end,
								get = function(info) return self.db.profile.enableSound end,
								order = 1,
								--width = "double"
							},
							soundFileObj = {
								type = 'select',
								dialogControl = 'LSM30_Sound',
								values = AceGUIWidgetLSMlists.sound,
								order = 2,
								name = "Objective Complete",
								desc = "Select a sound to play when you complete an objective",
								get = function() 
									return self.db.profile.annSoundName
								end,
								set = function(info, value)
									self.db.profile.annSoundFile = LSM:Fetch("sound", value)
									self.db.profile.annSoundName = value
								end,
							},
							soundFileComp = {
								type = 'select',
								dialogControl = 'LSM30_Sound',
								values = AceGUIWidgetLSMlists.sound,
								order = 3,
								name = "Quest Complete",
								desc = "Select a sound to play when you complete a quest",
								get = function() 
									return self.db.profile.compSoundName
								end,
								set = function(info, value)
									self.db.profile.compSoundFile = LSM:Fetch("sound", value)
									self.db.profile.compSoundName = value
								end,
							},
							soundComm = {
								name = "OA Communication Sounds",
								desc = "Sets whether to play a sound when other players with Objective Announcer send announcements",
								type = "toggle",
								set = function(info,val) self.db.profile.enableCommSound = val end,
								get = function(info) return self.db.profile.enableCommSound end,
								order = 4,
								width = "double"
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
									self.db.profile.commSoundFile = LSM:Fetch("sound", value)
									self.db.profile.commSoundName = value
								end,
							},							
						},
					},
				},
			}
		}
	}
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Objective Announcer", myOptions)
	optionsGUI = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Objective Announcer")
	myOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	
	playerName, realmName = UnitName("player")
	
	LSM:Register("sound", "PVPFlagCapturedHordeMono","Sound\\Interface\\PVPFlagCapturedHordeMono.wav")
	LSM:Register("sound", "PVPFlagCapturedMono", "Sound\\Interface\\PVPFlagCapturedMono.wav")
	LSM:Register("sound", "GM_ChatWarning", "Sound\\Interface\\GM_ChatWarning.ogg")
	
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
				local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily = GetQuestLogTitle(questIndex)
				if isHeader ~= 1 then
				--[[ Completed Quests Only ]]--
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
							Message = strjoin("", "QUEST COMPLETE -- ", questLink, MessageInfo)
							local selfTest = 0
							if self.db.profile.raidchat == true and (IsInRaid()) then
								SendChatMessage(Message, "RAID", nil, nil)
								soundAnnounce = true
								ObjAnnouncer:SendCommMessage("Obj Announcer", "quest raid", "RAID")
								selfTest = selfTest + 1
							elseif self.db.profile.instancechat == true and (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
								SendChatMessage(Message, "INSTANCE_CHAT", nil, nil)
								ObjAnnouncer:SendCommMessage("Obj Announcer", "quest instance", "PARTY")
								soundAnnounce = true
								selfTest = selfTest + 1
							elseif self.db.profile.partychat == true and (IsInGroup()) then
								SendChatMessage(Message, "PARTY", nil, nil)
								soundAnnounce = true
								ObjAnnouncer:SendCommMessage("Obj Announcer", "quest party", "PARTY")
								selfTest = selfTest + 1
							elseif self.db.profile.saychat == true and UnitIsDeadOrGhost("player") == false then
								SendChatMessage(Message, "SAY", nil, nil)
								soundAnnounce = true
								ObjAnnouncer:SendCommMessage("Obj Announcer", "quest say", "PARTY")
								selfTest = selfTest + 1								
							end
							if self.db.profile.guildchat == true and (IsInGuild()) then
								SendChatMessage(Message, "GUILD", nil, nil)
								ObjAnnouncer:SendCommMessage("Obj Announcer", "quest guild", "GUILD")
								selfTest = selfTest + 1
							elseif self.db.profile.officerchat == true and (CanViewOfficerNote()) then
								SendChatMessage(Message, "OFFICER", nil, nil)
								ObjAnnouncer:SendCommMessage("Obj Announcer", "quest officer", "GUILD")
								selfTest = selfTest + 1
							end
							if self.db.profile.channelchat == true then
								SendChatMessage(Message, "CHANNEL", nil, self.db.profile.chanName)
								selfTest = selfTest + 1
							end
							if self.db.profile.selftellalways == true then
								DEFAULT_CHAT_FRAME:AddMessage(Message)
								soundAnnounce = true
							-- If selfTest is still zero, then nothing has been written to chat.  Print a self message.
							elseif self.db.profile.selftell == true and selfTest == 0 then
								DEFAULT_CHAT_FRAME:AddMessage(Message)
								soundAnnounce = true
							end
						end
						if soundAnnounce == true and self.db.profile.enableSound == true then
							PlaySoundFile(self.db.profile.compSoundFile,"Master")
						end
				--[[ Completed Objectives ]]--
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
								if isComplete == 1 then	-- Different message if the quest is completed.
									Message = strjoin("", "QUEST COMPLETE -- ", questLink, MessageInfo)
								else
									Message = strjoin("", objDesc, MessageLink, MessageInfo)
								end
								local selfTest = 0	-- Variable to see if any conditions have fired.
								if self.db.profile.raidchat == true and (IsInRaid()) then
									SendChatMessage(Message, "RAID", nil, nil)
									soundAnnounce = true
									ObjAnnouncer:SendCommMessage("Obj Announcer", "objective raid", "RAID")
									selfTest = selfTest + 1
								elseif self.db.profile.instancechat == true and (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
									SendChatMessage(Message, "INSTANCE_CHAT", nil, nil)
									soundAnnounce = true
									ObjAnnouncer:SendCommMessage("Obj Announcer", "objective instance", "PARTY")
									selfTest = selfTest + 1
								elseif self.db.profile.partychat == true and (IsInGroup()) then
									SendChatMessage(Message, "PARTY", nil, nil)
									soundAnnounce = true
									ObjAnnouncer:SendCommMessage("Obj Announcer", "objective party", "PARTY")
									selfTest = selfTest + 1
								elseif self.db.profile.saychat == true and UnitIsDeadOrGhost("player") == false then
									SendChatMessage(Message, "SAY", nil, nil)
									soundAnnounce = true
									ObjAnnouncer:SendCommMessage("Obj Announcer", "objective say", "PARTY")
									selfTest = selfTest + 1											
								end
								if self.db.profile.guildchat == true and (IsInGuild()) then
									SendChatMessage(Message, "GUILD", nil, nil)
									ObjAnnouncer:SendCommMessage("Obj Announcer", "objective guild", "GUILD")
									selfTest = selfTest + 1
								elseif self.db.profile.officerchat == true and (CanViewOfficerNote()) then
									SendChatMessage(Message, "OFFICER", nil, nil)
									ObjAnnouncer:SendCommMessage("Obj Announcer", "objective officer", "GUILD")
									selfTest = selfTest + 1
								end
								if self.db.profile.channelchat == true then
									SendChatMessage(Message, "CHANNEL", nil, self.db.profile.chanName)
									selfTest = selfTest + 1
								end
								if self.db.profile.selftellalways == true then
									DEFAULT_CHAT_FRAME:AddMessage(Message)
									soundAnnounce = true
								elseif self.db.profile.selftell == true and selfTest == 0 then	-- If selfTest is still zero, then nothing has been written to chat.  Print a self message.
									DEFAULT_CHAT_FRAME:AddMessage(Message)
									soundAnnounce = true
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
								Message = strjoin("", objDesc, MessageLink, MessageInfo)
								local selfTest = 0	-- Variable to see if any conditions have fired.
								if self.db.profile.raidchat == true and (IsInRaid()) then
									SendChatMessage(Message, "RAID", nil, nil)
									selfTest = selfTest + 1
								elseif self.db.profile.instancechat == true and (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
									SendChatMessage(Message, "INSTANCE_CHAT", nil, nil)
									selfTest = selfTest + 1
								elseif self.db.profile.partychat == true and (IsInGroup()) then
									SendChatMessage(Message, "PARTY", nil, nil)
									selfTest = selfTest + 1
								elseif self.db.profile.saychat == true and UnitIsDeadOrGhost("player") == false then
									SendChatMessage(Message, "SAY", nil, nil)
									selfTest = selfTest + 1	
								end
								if self.db.profile.guildchat == true and (IsInGuild()) then
									SendChatMessage(Message, "GUILD", nil, nil)
									selfTest = selfTest + 1
								elseif self.db.profile.officerchat == true and (CanViewOfficerNote()) then
									SendChatMessage(Message, "OFFICER", nil, nil)
									selfTest = selfTest + 1
								end
								if self.db.profile.channelchat == true then
									SendChatMessage(Message, "CHANNEL", nil, self.db.profile.chanName)
									selfTest = selfTest + 1
								end
								if self.db.profile.selftellalways == true then
									DEFAULT_CHAT_FRAME:AddMessage(Message)
								elseif self.db.profile.selftell == true and selfTest == 0 then	-- If selfTest is still zero, then nothing has been written to chat.  Print a self message.
									DEFAULT_CHAT_FRAME:AddMessage(Message)
								end
							end
						end
						if soundAnnounce == true and self.db.profile.enableSound == true then
							if isComplete == 1 then
								PlaySoundFile(self.db.profile.compSoundFile,"Master")
							else
								PlaySoundFile(self.db.profile.annSoundFile,"Master")
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

	function oacommandHandler(str)
		InterfaceOptionsFrame_OpenToCategory(optionsGUI)
	end

	function oareceivedComm(prefix, commIn, dist, sender)
		local announceType, announceChannel = ObjAnnouncer:GetArgs(commIn, 2, 1)
		if (announceChannel == "party" or announceChannel == "raid" or announceChannel == "instance") and self.db.profile.enableCommSound == true and sender ~= playerName then
			PlaySoundFile(self.db.profile.commSoundFile)
		end
	end


	ObjAnnouncer:RegisterEvent("QUEST_LOG_UPDATE", oaeventHandler);
	ObjAnnouncer:RegisterChatCommand("oa", oacommandHandler);
	ObjAnnouncer:RegisterChatCommand("obja", oacommandHandler);
	ObjAnnouncer:RegisterComm("Obj Announcer", oareceivedComm)
	DEFAULT_CHAT_FRAME:AddMessage("|cffcc33ffObjective Announcer".." "..version.." Loaded.  Type /oa for Options.|r")
end