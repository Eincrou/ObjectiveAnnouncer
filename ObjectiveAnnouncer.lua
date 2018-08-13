
ObjAnnouncer = LibStub("AceAddon-3.0"):NewAddon("Objective Announcer", "AceComm-3.0", "AceEvent-3.0", "AceConsole-3.0","LibSink-2.0")
local LSM = LibStub("LibSharedMedia-3.0")
local version = GetAddOnMetadata("ObjectiveAnnouncer","Version") or ""

defaults = {
	profile = {
		--[[ General ]]--
		annType = 2,
			-- Announce to --
		selftell = true,
		selftellalways = false,
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
		questlink = true,
		infoType = false,
		infoLevel = false,
		infoDaily = false,
		infoAutoComp = false,
		infoFail = false,
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

	qidComplete = 0
	turnLink = nil

	helpText = [[Usage:
   |cff55ffff/oa or /obja|r Open options interface
   |cff55ff55/oa quest|r Quests Only
   |cff55ff55/oa obj|r Objectives Only
   |cff55ff55/oa both|r Both Quests & Objectives
   |cff55ff55/oa prog|r Objectives Progress
   |cff55ff55/oa progq|r Progress and Completed Quests
   |cff55ff55/oa self|r Toggle Self Messages
   |cff55ff55/oa pub |r<|cff55ff55channel|r> Toggle Public Channels
   |cff55ff55/oa accept|r Toggle "Accept A Quest"
   |cff55ff55/oa turnin|r Toggle "Turn In A Quest"
   |cff55ff55/oa escort|r Toggle "Auto-Accept Escort/Event Quests"
   |cff55ff55/oa fail|r Toggle "Quest Failure"
   |cff55ff55/oa soundcomp|r Toggle Completion Sounds
   |cff55ff55/oa soundcomm|r Toggle Communication Sounds]]
	
	slashCommands = {
		["quest"] = function(v)
			self.db.profile.annType = 1
			ObjAnnouncer:Print("Now Announcing Completed Quests Only")
		end,
		["obj"] = function(v)
			self.db.profile.annType = 2
			ObjAnnouncer:Print("Now Announcing Completed Objectives Only")
		end,
		["both"] = function(v)
			self.db.profile.annType = 3
			ObjAnnouncer:Print("Now Announcing Both Completed Quests & Objectives")
		end,
		["prog"] = function(v)
			self.db.profile.annType = 4
			ObjAnnouncer:Print("Now Announcing Objective Progress")
		end,
		["progq"] = function(v)
			self.db.profile.annType = 5
			ObjAnnouncer:Print("Now Announcing Objective Progress & Completed Quests")		
		end,
		["self"] = function(v)
			if self.db.profile.selftell then
				self.db.profile.selftell = false
				self.db.profile.selftellalways = false
				ObjAnnouncer:Print("Self Messages |cFFFF0000Disabled|r (Always Self Announce also disabled)")
			else
				self.db.profile.selftell = true
				ObjAnnouncer:Print("Self Messages |cFF00FF00Enabled|r")
			end
		end,
		["pub"] = function(v)
			if v == "say" then	-- There's probably a more efficient way to do this, but it works...
				if self.db.profile.saychat then
					self.db.profile.saychat = false
					ObjAnnouncer:Print("Say Chat |cFFFF0000Disabled|r")
				else
					self.db.profile.saychat = true
					ObjAnnouncer:Print("Say Chat |cFF00FF00Enabled|r")
				end
			elseif	v == "party" then
				if self.db.profile.partychat then
					self.db.profile.partychat = false
					ObjAnnouncer:Print("|cFFA8A8FFParty Chat|r |cFFFF0000Disabled|r")
				else
					self.db.profile.partychat = true
					ObjAnnouncer:Print("|cFFA8A8FFParty Chat|r |cFF00FF00Enabled|r")
				end
			elseif v == "instance" then
				if self.db.profile.instancechat then
					self.db.profile.instancechat = false
					ObjAnnouncer:Print("|cFFFD8100Instance Chat|r |cFFFF0000Disabled|r")
				else
					self.db.profile.instancechat = true
					ObjAnnouncer:Print("|cFFFD8100Instance Chat|r |cFF00FF00Enabled|r")
				end
			elseif v == "raid" then
				if self.db.profile.raidchat then
					self.db.profile.raidchat = false
					ObjAnnouncer:Print("|cFFFF7F00Raid Chat|r |cFFFF0000Disabled|r")
				else
					self.db.profile.raidchat = true
					ObjAnnouncer:Print("|cFFFF7F00Raid Chat|r |cFF00FF00Enabled|r")
				end		
			elseif v == "guild" then
				if self.db.profile.guildchat then
					self.db.profile.guildchat = false
					ObjAnnouncer:Print("|cFF40ff40Guild Chat|r |cFFFF0000Disabled|r")
				else
					self.db.profile.guildchat = true
					ObjAnnouncer:Print("|cFF40ff40Guild Chat|r |cFF00FF00Enabled|r")
				end
			elseif v == "officer" then
				if self.db.profile.officerchat then
					self.db.profile.officerchat = false
					ObjAnnouncer:Print("|cFF40c040Officer Chat|r |cFFFF0000Disabled|r")
				else
					self.db.profile.officerchat = true
					self.db.profile.guildchat = false
					ObjAnnouncer:Print("|cFF40c040Officer Chat|r |cFF00FF00Enabled|r (|cFF40ff40Guild Chat|r |cFFFFFF0000Disabled|r)")
				end
			elseif v == "channel" then
				if self.db.profile.channelchat then
					self.db.profile.channelchat = false
					ObjAnnouncer:Print("|cFFffc0c0Channel Chat|r |cFFFF0000Disabled|r")
				else
					self.db.profile.channelchat = true
					ObjAnnouncer:Print("|cFFffc0c0Channel Chat|r |cFF00FF00Enabled|r")
				end
			else
				ObjAnnouncer:Print("Valid public chat names are: say, party, instance, raid, guild, officer & channel.")
			end
		end,
		["accept"] = function(v)
			if self.db.profile.questAccept then
				self.db.profile.questAccept = false
				ObjAnnouncer:Print("Announce Quest Accepted |cFFFF0000Disabled|r")
			else
				self.db.profile.questAccept = true
				ObjAnnouncer:Print("Announce Quest Accepted |cFF00FF00Enabled|r")
			end
		end,		
		["turnin"] = function(v)
			if self.db.profile.questTurnin then
				self.db.profile.questTurnin = false
				ObjAnnouncer:UnregisterEvent("QUEST_COMPLETE", oaQuestTurnin)
				ObjAnnouncer:Print("Announce Quest Turn-in |cFFFF0000Disabled|r")
			else
				self.db.profile.questTurnin = true
				ObjAnnouncer:RegisterEvent("QUEST_COMPLETE", oaQuestTurnin)
				ObjAnnouncer:Print("Announce Quest Turn-in |cFF00FF00Enabled|r")
			end
		end,
		["fail"] = function(v)
			if self.db.profile.infoFail then
				self.db.profile.infoFail = false
				ObjAnnouncer:Print("Announce Failed Quests |cFFFF0000Disabled|r")
			else
				self.db.profile.infoFail = true
				ObjAnnouncer:Print("Announce Failed Quests |cFF00FF00Enabled|r")
			end
		end,		
		["soundcomp"] = function(v)
			if self.db.profile.enableSound then
				self.db.profile.enableSound = false
				ObjAnnouncer:Print("Quest/Objective Complete Sounds |cFFFF0000Disabled|r")
			else
				self.db.profile.enableSound = true
				ObjAnnouncer:Print("Quest/Objective Complete Sounds |cFF00FF00Enabled|r")
			end
		end,
		["soundcomm"] = function(v)
			if self.db.profile.enableCommSound then
				self.db.profile.enableCommSound = false
				ObjAnnouncer:Print("Communication Sounds |cFFFF0000Disabled|r")
			else
				self.db.profile.enableCommSound = true
				ObjAnnouncer:Print("Communication Sounds |cFF00FF00Enabled|r")
			end
		end,		
	}	
	
	self.db = LibStub("AceDB-3.0"):New("ObjectiveAnnouncerDB", defaults, true)
	for boardSaved = 1, 100 do
		objCSaved[boardSaved] = {}
		objDescSaved[boardSaved] = {}
	end
	
	myOptions = {
		name = "Objective Announcer".." "..version.." |cFFFF7F00by Bantou|r |cFF339900and Eincrou",
		type = "group",
		childGroups = "tab",
		args = {
			options = {
				name = "General",
				type="group",
				order = 1,
				args={
					announce = {
						name = "|TInterface\\Icons\\Ability_Warrior_RallyingCry:18|t Announcement Mode:",
						desc = "Select which type of announcements are made.|n|cFF9ffbffCompleted Quests:|r Announce only when quests are finished.|n|cFF9ffbffCompleted Objectives:|r Announce only finished objectives.|n|cFF9ffbffBoth Quests & Objectives:|r Announces finished objectives and when the quest is fully complete.|n|cFF9ffbffObjective Progress:|r Announce each time an objective is advanced.|n|cFF9ffbffProgress & Completed Quests:|r Announce each time an objective is advanced and when the quest is fully completed.",
						type = "select",
						style = "radio",
						values = {
							"Completed Quests",
							"Completed Objectives",
							"Both Quests & Objectives",
							"Objective Progress",
							"Progress & Comp. Quests"
							},
						set = function(info,val) self.db.profile.annType = val end,
						get = function(info) return self.db.profile.annType end,
						order = 0
					},
					announceChannels = {
						inline = true,
						name = "|TInterface\\Icons\\Warrior_disruptingshout:18|t Announce to:",
						type="group",
						order = 2,
						args={
						--[[ Private ]]--
							header1 = {
								name = "Private Announcements",
								type = "header",
								order = 0,
								width = "double"
							},						
							mememe = {
								name = "Self",
								desc = "Sets whether to announce to yourself when no public announcements have been made.|n|cFF9ffbffChoose where to output your self messages in the Self Output tab above.",
								type = "toggle",
								set = function(info,val) self.db.profile.selftell = val end,
								get = function(info) return self.db.profile.selftell end,
								order = 1,
								disabled = function() return self.db.profile.selftellalways end,
								width = "half"
							},
							mememealways = {
								name = "Always Self Announce",
								desc = "Announce to self even when a public message has been sent.",
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
						--[[ Public ]]--				
							header2 = {
								name = "Public Announcements",
								type = "header",
								order = 10,
								width = "double"
							},
							say = {
								name = "|cFFFFFFFFSay",
								desc = "Sets whether to announce to Say.",
								type = "toggle",
								set = function(info,val) self.db.profile.saychat = val end,
								get = function(info) return self.db.profile.saychat end,
								order = 12,							
								width = "half"
							},
							party = {
								name = "|cFFA8A8FFParty|r",	-- /dump ChatTypeInfo.PARTY
								desc = "Sets whether to announce to Party Chat.",
								type = "toggle",
								set = function(info,val) self.db.profile.partychat = val end,
								get = function(info) return self.db.profile.partychat end,
								order = 14,
								width = "half"
							},
							instance = {
								name = "|cFFFD8100Instance",
								desc = "Sets whether to announce to Instance Chat if in a Looking For Dungeon group.",
								type = "toggle",
								set = function(info,val) self.db.profile.instancechat = val end,
								get = function(info) return self.db.profile.instancechat end,
								order = 16,
								width = "half"
							},
							raid = {
								name = "|cFFFF7F00Raid",
								desc = "Sets whether to announce to Raid Chat.",
								type = "toggle",
								set = function(info,val) self.db.profile.raidchat = val end,
								get = function(info) return self.db.profile.raidchat end,
								order = 18,
								width = "half"
							},
							guild = {
								name = "|cFF40ff40Guild",
								desc = "Sets whether to announce to Guild Chat|n|cFFF02121(Disables Officer Chat announcements).",
								type = "toggle",
								set = function(info,val) self.db.profile.guildchat = val end,
								get = function(info) return self.db.profile.guildchat end,
								order = 20,
								width = "half"
							},
							officer = {
								name = "|cFF40c040Officer",
								desc = "Sets whether to announce to Officer Chat.|n|cFF9ffbff(Only if no announcement has already been sent to Guild)",
								type = "toggle",
								disabled = function() return self.db.profile.guildchat end,
								set = function(info,val) self.db.profile.officerchat = val end,
								get = function(info) return self.db.profile.officerchat end,
								order = 22,
								width = "half",
							},
							channel = {
								name = "|cFFffc0c0Channel",
								desc = "Sets whether to announce to a channel. Please don't be rude!",
								type = "toggle",
								set = function(info,val) self.db.profile.channelchat = val end,
								get = function(info) return self.db.profile.channelchat end,
								order = 24,
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
								order = 26,
							},
						},
					},
					extraInfo = {
						inline = true,
						name = "|TInterface\\Icons\\inv_jewelry_trinket_15:18|t Extra Information:",
						type="group",
						order = 3,
						args={
							qlink = {
								name = "Quest Link",
								desc = "Adds a clickable link of the relevant quest to your objective and progress announcements.",
								type = "toggle",
								set = function(info,val) self.db.profile.questlink = val end,
								get = function(info) return self.db.profile.questlink end,
								order = 1,
							},
							qtype = {
								name = "Quest Type",
								desc = "Adds the quest's type to your announcements.|n|cFF9ffbff(e.g. Dungeon, Raid, PVP, etc.)",
								type = "toggle",
								set = function(info,val) self.db.profile.infoType = val end,
								get = function(info) return self.db.profile.infoType end,
								order = 2,
							},
							qlevel = {
								name = "Quest Level",
								desc = "Adds the intended level of the quest to announcements.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoLevel = val end,
								get = function(info) return self.db.profile.infoLevel end,
								order = 3,
							},
							qdaily = {
								name = "Is A Daily",
								desc = "Adds whether it's a daily quest to your announcements.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoDaily = val end,
								get = function(info) return self.db.profile.infoDaily end,
								order = 4,
							},
							qautocomp = {
								name = "Auto-Complete|n|cFF9ffbffAlso causes the remote turn-in dialogue window to appear.",
								desc = "Send an extra announcement when you complete a quest that can be completed remotely.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoAutoComp = val 
									if val then ObjAnnouncer:RegisterEvent("QUEST_AUTOCOMPLETE", oaAutoComplete)
									else ObjAnnouncer:UnregisterEvent("QUEST_AUTOCOMPLETE", oaAutoComplete) end								
								end,
								get = function(info) return self.db.profile.infoAutoComp end,
								order = 5,								
							},
							qfailed = {
								name = "Quest Failure",
								desc = "Send an extra announcement when you fail a quest.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoFail = val end,
								get = function(info) return self.db.profile.infoFail end,
								order = 6,
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
								set = function(info,val) self.db.profile.questAccept = val end,
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
								set = function(info,val) self.db.profile.questEscort = val end,
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
			LibSink = ObjAnnouncer:GetSinkAce3OptionsDataTable(),
		},
	}
	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Objective Announcer", myOptions)
	optionsGUI = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Objective Announcer")
	myOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	
	playerName, realmName = UnitName("player")
	
	--[[ LibSharedMedia ]]--
	LSM:Register("sound", "PVPFlagCapturedHorde","Sound\\Interface\\PVPFlagCapturedHordeMono.wav")
	LSM:Register("sound", "PVPFlagCaptured", "Sound\\Interface\\PVPFlagCapturedMono.wav")
	LSM:Register("sound", "GM ChatWarning", "Sound\\Interface\\GM_ChatWarning.ogg")
	LSM:Register("sound", "PetBattle Defeat01", "Sound\\Interface\\UI_PetBattle_Defeat01.OGG")	-- For an NYI feature...
	
	--[[ LibSink ]]--
	ObjAnnouncer:SetSinkStorage(self.db.profile)
	local libsink = myOptions.args.LibSink
	libsink.name = "Self Outputs"
	libsink.desc = "Select where to send your self messages."
	libsink.order = 2
		--[[ Hide LibSink outputs that would conflict with public announcements ]]--
	libsink.args.Channel.hidden = true	-- If someone selected a channel here, self messages would report to a public channel if all public channels were disabled in OA.  Best to disable this.
	libsink.args.None.hidden = true	-- We already have a way to disable self announcements
	libsink.args.Default.hidden = true	--  Could cause self announcements to announce to public channels...maybe.  In any case, unnecessary.
	
end


function ObjAnnouncer:OnEnable()

	function oaeventHandler(event, ...)
		local logIndex = GetQuestLogIndexByID(qidComplete)
		if  logIndex == 0 and turnLink ~= nil then -- Checks to see if the quest that fired the QUEST_COMPLETE event is no longer in the quest log.
			local Message = "Quest Turned In -- "..turnLink
			oaMessageHandler(Message, true)
			turnLink = nil
		end
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
			flagQuestTurnin = false
		else
			for questIndex = 1, numEntries do
				local questTitle, level, questTag, suggestedGroup, isHeader, isCollapsed, isComplete, isDaily, questID = GetQuestLogTitle(questIndex)
				if isHeader ~= 1 then
			--[[ Announcements Logic ]]-- 
				--[[ Failed Quests ]]--
					if isComplete == -1 and self.db.profile.infoFail and isComplete ~= questCSaved[questIndex] then
						questCSaved[questIndex] = isComplete
						questLink = GetQuestLink(questIndex)
						failedMessage = questLink.." -- QUEST FAILED"
						oaMessageHandler(failedMessage, true, false, false, isComplete)
					end			
				--[[ Completed Quests Only ]]--
					if isComplete == 1 and isComplete ~= questCSaved[questIndex] then
						questCSaved[questIndex] = isComplete
						if self.db.profile.annType ==  1 then
							oaMessageCreator(questIndex, nil, true, level, questTag, isComplete, isDaily)
						end
					end
				--[[ Completed Objectives (and Completed Quests, if Announce Type 3 is selected) ]]--
					for boardIndex = 1, GetNumQuestLeaderBoards(questIndex) do
						local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questIndex)
						if (objComplete) and objComplete ~= objCSaved[questIndex][boardIndex] then
							objCSaved[questIndex][boardIndex] = objComplete
							if self.db.profile.annType == 2 or self.db.profile.annType == 3 then					
								oaMessageCreator(questIndex, objDesc, objComplete, level, questTag, isComplete, isDaily)
							end
						end
					--[[ Announces the progress of objectives (and Completed Quests, if Announce Type 5 is selected)]]--
						if objDesc ~= objDescSaved[questIndex][boardIndex] and string.find(objDesc, ": 0/") == nil then
							objDescSaved[questIndex][boardIndex] = objDesc	
							if self.db.profile.annType == 4 or self.db.profile.annType == 5 then
								oaMessageCreator(questIndex, objDesc, objComplete, level, questTag, isComplete, isDaily)
							end
						end
					end
				end
			end
		end
	end

	function oaMessageCreator(questIndex, objDesc, objComplete, level, questTag, isComplete, isDaily)
	
		local divider = false
	
		if self.db.profile.questlink then 
			questLink = GetQuestLink(questIndex)
			messageInfoLink = strjoin("", "  --  ", questLink)
		else
			messageInfoLink = ""
		end
		if self.db.profile.infoType then
			if (questTag) then
				messageInfoType = strjoin("", " ", questTag)
				divider = true
			else
				messageInfoType = ""
			end
		else
			messageInfoType = ""
		end
		if isDaily and self.db.profile.infoDaily then
			messageInfoDaily = " Daily"
			divider = true
		else
			messageInfoDaily = ""
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
			finalAnnouncement = "QUEST COMPLETE -- "..questLink..infoDivider..messageInfoType..messageInfoDaily..messageInfoLevel	-- This announcement type ignores self.db.profile.questlink to ensure that a quest link is always displayed.
		else
			finalAnnouncement = objDesc..messageInfoLink..infoDivider..messageInfoType..messageInfoDaily..messageInfoLevel
			if (self.db.profile.annType == 3 or self.db.profile.annType == 5) and isComplete == 1 then
				finalAnnouncement = finalAnnouncement.." -- QUEST COMPLETE"
			end
		end
		oaMessageHandler(finalAnnouncement, true, objComplete, objComplete, isComplete)
	end	
	
	function oaMessageHandler(announcement, enableSelf, enableSound, enableComm, isComplete)
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
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest say", "PARTY") end
			selfTest = false
		end
		if self.db.profile.guildchat and IsInGuild() then
			SendChatMessage(announcement, "GUILD")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest guild", "GUILD") end
			selfTest = false
		elseif self.db.profile.officerchat and CanViewOfficerNote() then
			SendChatMessage(announcement, "OFFICER")
			if enableComm then ObjAnnouncer:SendCommMessage("Obj Announcer", "quest officer", "GUILD") end
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
		if enableSound and self.db.profile.enableSound then
			if isComplete == 1 then
				PlaySoundFile(self.db.profile.compSoundFile,"Master")
			--elseif isComplete == -1 then	
				--	PlaySoundFile(self.db.profile.failSoundFile,"Master")
			else
				PlaySoundFile(self.db.profile.annSoundFile,"Master")
			end
		end
	end
	
	function oacommandHandler(input)
		local linput = string.lower(input)
		local k,v = string.match(linput, "([%w%+%-%=]+) ?(.*)")
		if input == "help" then
           ObjAnnouncer:Print(helpText)
		end
		if slashCommands[k] then	-- If valid...
			slashCommands[k](v)
		elseif k then	-- If user typed something invalid, show help.
           ObjAnnouncer:Print(helpText)		
		else
			InterfaceOptionsFrame_OpenToCategory(optionsGUI)
		end
	end

	function oareceivedComm(prefix, commIn, dist, sender)
		local announceType, announceChannel = ObjAnnouncer:GetArgs(commIn, 2, 1)
		if (announceChannel == "party" or announceChannel == "raid") and self.db.profile.enableCommSound == true and sender ~= playerName then
			PlaySoundFile(self.db.profile.commSoundFile)
		end
	end

	function oaQuestAccepted(event, ...)
		if self.db.profile.questAccept then
			local questLogIndex = ...
			local acceptedLink = GetQuestLink(questLogIndex)
			local Message = "Quest Accepted -- "..acceptedLink
			oaMessageHandler(Message, true)
		end
	end

	function oaQuestTurnin(event, ...)
		qidComplete = GetQuestID()
		turnLink = GetQuestLink(GetQuestLogIndexByID(qidComplete))
	end
	
	function oaAutoComplete(event, ...)
		local acID = ...
		local qIndex = GetQuestLogIndexByID(acID)
		local qLink = GetQuestLink(qIndex)
		local message = "AUTO-COMPLETE ALERT -- "..qLink
		oaMessageHandler(message, true)
		ShowQuestComplete(qIndex)	-- Automatically brings up the quest turn-in dialog window.
	end
	
	function oaAcceptEscort(event, ...)
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
	
	ObjAnnouncer:RegisterEvent("QUEST_LOG_UPDATE", oaeventHandler)
	ObjAnnouncer:RegisterEvent("QUEST_ACCEPTED", oaQuestAccepted)
	if self.db.profile.questTurnin then ObjAnnouncer:RegisterEvent("QUEST_COMPLETE", oaQuestTurnin)	end
	ObjAnnouncer:RegisterEvent("QUEST_ACCEPT_CONFIRM", oaAcceptEscort)
	if self.db.profile.infoAutoComp then ObjAnnouncer:RegisterEvent("QUEST_AUTOCOMPLETE", oaAutoComplete) end
	ObjAnnouncer:RegisterChatCommand("oa", oacommandHandler)
	ObjAnnouncer:RegisterChatCommand("obja", oacommandHandler)
	ObjAnnouncer:RegisterComm("Obj Announcer", oareceivedComm)
	DEFAULT_CHAT_FRAME:AddMessage("|cffcc33ffObjective Announcer".." "..version.." Loaded.  Type|r /oa help |cffcc33fffor list of commands.|r")
end