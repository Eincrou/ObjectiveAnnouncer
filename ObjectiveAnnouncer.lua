
ObjAnnouncer = LibStub("AceAddon-3.0"):NewAddon("Objective Announcer", "AceComm-3.0", "AceEvent-3.0", "AceConsole-3.0","LibSink-2.0")
local self = ObjAnnouncer
local LSM = LibStub("LibSharedMedia-3.0")
local version = GetAddOnMetadata("ObjectiveAnnouncer","Version") or ""

--[[ Local Variables ]]--

local playerName, realmName
local objCSaved = {}
local questCSaved = {}
local objDescSaved = {}
local oorGroupStorage = {}
--local oorCompletedQIDs = {}
local qidComplete = 0
local turnLink = nil

local defaults = {
	profile = {
		--[[ General ]]--
		annType = 2,
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
		questAccept = false, questTurnin = false, questEscort = false, infoAutoComp = false, infoFail = false,		
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
	char = {
	taskStorage = {},
	},
}

local helpText = [[Usage:
   |cff55ffff/oa or /obja|r Open options interface
   |cff55ff55/oa quest|r Quests Only
   |cff55ff55/oa obj|r Objectives Only
   |cff55ff55/oa both|r Both Quests & Objectives
   |cff55ff55/oa prog|r Objectives Progress
   |cff55ff55/oa progq|r Progress and Completed Quests
   |cff55ff55/oa self|r Toggle Self Messages
   |cff55ff55/oa pub |r<|cff55ff55channel|r> Toggle Public Channels
   |cff55ff55/oa oor|r Toggle Out-of-range Alerts
   |cff55ff55/oa accept|r Toggle "Accept A Quest"
   |cff55ff55/oa turnin|r Toggle "Turn In A Quest"
   |cff55ff55/oa escort|r Toggle "Auto-Accept Escort/Event Quests"
   |cff55ff55/oa fail|r Toggle "Quest Failure"
   |cff55ff55/oa soundcomp|r Toggle Completion Sounds
   |cff55ff55/oa soundaf|r Toggle Accept/Fail Sounds   
   |cff55ff55/oa soundcomm|r Toggle Communication Sounds]]

function ObjAnnouncer:OnInitialize()




	
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
					ObjAnnouncer:Print("|cFF40c040Officer Chat|r |cFF00FF00Enabled|r (|cFF40ff40Guild Chat|r |cFFFF0000Disabled|r)")
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
		["oor"] = function(v)
			if self.db.profile.enableOOR then
				self.db.profile.enableOOR = false
				ObjAnnouncer:Print("Out-of-range Alerts |cFFFF0000Disabled|r")
			else
				self.db.profile.enableOOR = true
				ObjAnnouncer:Print("Out-of-range Alerts |cFF00FF00Enabled|r")
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
		["escort"] = function(v)
			if self.db.profile.questEscort then
				self.db.profile.questEscort = false
				ObjAnnouncer:Print("Announce Failed Quests |cFFFF0000Disabled|r")
			else
				self.db.profile.questEscort = true
				ObjAnnouncer:Print("Announce Failed Quests |cFF00FF00Enabled|r")
			end
		end,			
		["fail"] = function(v)
			if self.db.profile.questEscort then
				self.db.profile.questEscort = false
				ObjAnnouncer:Print("Announce Failed Quests |cFFFF0000Disabled|r")
			else
				self.db.profile.questEscort = true
				ObjAnnouncer:Print("Announce Failed Quests |cFF00FF00Enabled|r")
			end
		end,		
		["soundcomp"] = function(v)
			if self.db.profile.enableCompletionSound then
				self.db.profile.enableCompletionSound = false
				ObjAnnouncer:Print("Quest/Objective Complete Sounds |cFFFF0000Disabled|r")
			else
				self.db.profile.enableCompletionSound = true
				ObjAnnouncer:Print("Quest/Objective Complete Sounds |cFF00FF00Enabled|r")
			end
		end,
		["soundaf"] = function(v)
			if self.db.profile.enableAcceptFailSound then
				self.db.profile.enableAcceptFailSound = false
				ObjAnnouncer:Print("Quest Accept/Fail Sounds |cFFFF0000Disabled|r")
			else
				self.db.profile.enableAcceptFailSound = true
				ObjAnnouncer:Print("Quest Accept/Fail Sounds |cFF00FF00Enabled|r")
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
								name = "|cFF40FF40Guild",
								desc = "Sets whether to announce to Guild Chat|n|cFFF02121(Disables Officer Chat announcements).",
								type = "toggle",
								set = function(info,val) self.db.profile.guildchat = val end,
								get = function(info) return self.db.profile.guildchat end,
								order = 20,
								width = "half"
							},
							officer = {
								name = "|cFF40C040Officer",
								desc = "Sets whether to announce to Officer Chat.|n|cFF9ffbff(Only if no announcement has already been sent to Guild)",
								type = "toggle",
								disabled = function() return self.db.profile.guildchat end,
								set = function(info,val) self.db.profile.officerchat = val end,
								get = function(info) return self.db.profile.officerchat end,
								order = 22,
								width = "half",
							},
							channel = {
								name = "|cFFFFC0C0Channel",
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
					oorAlerts = {
						inline = true,
						name = "|TInterface\\Icons\\ability_rogue_combatexpertise:18|t Out-Of-Range Alerts:",
						type="group",
						order = 4,
						args={
							qlink = {
								name = "Enable OOR Alerts",
								desc = "Send announcements if you do not receive credit when party members using Objective Announcer advance kill quests.|n|cFF9ffbffRequires party members to have Objective Announcer v6.0.3a+.",
								type = "toggle",
								set = function(info,val) self.db.profile.enableOOR = val end,
								get = function(info) return self.db.profile.enableOOR end,
								order = 1,
							},							
						},
					},					
					extraInfo = {
						inline = true,
						name = "|TInterface\\Icons\\inv_jewelry_trinket_15:18|t Extra Information:",
						type="group",
						order = 4,
						args={
							qlink = {
								name = "Quest Link",
								desc = "Adds a clickable link of the relevant quest to your objective and progress announcements.",
								type = "toggle",
								set = function(info,val) self.db.profile.questlink = val end,
								get = function(info) return self.db.profile.questlink end,
								order = 1,
							},
							qgroupsize = {
								name = "Suggested Group",
								desc = "Adds the quest's suggested group size to your announcements.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoSuggGroup = val end,
								get = function(info) return self.db.profile.infoSuggGroup end,
								order = 2,
							},
							qtag = {
								name = "Quest Tag",
								desc = "Adds special tagging of quest to announcements.|n|cFF9ffbffGroup, Raid, Account, etc.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoTag = val end,
								get = function(info) return self.db.profile.infoTag end,
								order = 3,
							},
							qfreq = {
								name = "Frequency",
								desc = "Adds whether it's a daily or weekly quest to your announcements.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoFrequency = val end,
								get = function(info) return self.db.profile.infoFrequency end,
								order = 4,
							},									
							qlevel = {
								name = "Quest Level",
								desc = "Adds the intended level of the quest to announcements.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoLevel = val end,
								get = function(info) return self.db.profile.infoLevel end,
								order = 5,
							},
				
						},
					},
					questStartEnd = {
						inline = true,
						name = "|TInterface\\Icons\\Achievement_quests_completed_08:18|t Quest Start/End:",
						type="group",
						order = 5,
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
								name = "Turn in a Quest",
								desc = "Make an announcement when you turn in a quest.",
								type = "toggle",
								set = function(info,val) self.db.profile.questTurnin = val 
									if val then ObjAnnouncer:RegisterEvent("QUEST_COMPLETE", oaQuestTurnin)
									else ObjAnnouncer:UnregisterEvent("QUEST_COMPLETE", oaQuestTurnin) end
								end,
								get = function(info) return self.db.profile.questTurnin end,
								order = 2,
							},
							qfailed = {
								name = "Fail a Quest",
								desc = "Make an announcement when you fail a quest.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoFail = val end,
								get = function(info) return self.db.profile.infoFail end,
								order = 3,
							},										
							escort = {
								name = "Auto-accept escort/event quests",
								desc = "Automatically accepts event quests started by party members.",
								type = "toggle",
								set = function(info,val) self.db.profile.questEscort = val end,
								get = function(info) return self.db.profile.questEscort end,
								order = 4,
								width = "double",
							},
							qautocomp = {
								name = "Auto-Complete",
								desc = "Send an extra announcement when you complete a quest that can be completed remotely.|n|cFF9ffbffAlso causes the remote turn-in dialogue window to appear.",
								type = "toggle",
								set = function(info,val) self.db.profile.infoAutoComp = val 
									if val then ObjAnnouncer:RegisterEvent("QUEST_AUTOCOMPLETE", oaAutoComplete)
									else ObjAnnouncer:UnregisterEvent("QUEST_AUTOCOMPLETE", oaAutoComplete) end								
								end,
								get = function(info) return self.db.profile.infoAutoComp end,
								order = 5,								
							},
						},
					},					
					soundOptions = {
						inline = true,
						name = "|TInterface\\Icons\\Inv_misc_archaeology_trolldrum:18|t Sound:",
						type="group",
						order = 6,
						args={
							soundCompletion = {
								name = "Completion Sounds",
								desc = "Sets whether to play sounds when announcements are made.|n|cFF9ffbffOnly plays if an announcement is sent",
								type = "toggle",
								set = function(info,val) self.db.profile.enableCompletionSound = val end,
								get = function(info) return self.db.profile.enableCompletionSound end,
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
							soundAcceptFail = {
								name = "Accept/Fail Sounds",
								desc = "Sets whether to play sounds when accepting or failing a quest.|n|cFF9ffbffOnly plays if an announcement is sent",
								type = "toggle",
								set = function(info,val) self.db.profile.enableAcceptFailSound = val end,
								get = function(info) return self.db.profile.enableAcceptFailSound end,
								order = 4,
							},
							soundFileAccept = {
								type = 'select',
								dialogControl = 'LSM30_Sound',
								values = AceGUIWidgetLSMlists.sound,
								order = 5,
								name = "Quest Accept",
								desc = "Select a sound to play when you accept a new quest",
								get = function() return self.db.profile.acceptSoundName end,
								set = function(info, value)
									self.db.profile.acceptSoundName = value
									self.db.profile.acceptSoundFile = LSM:Fetch("sound", self.db.profile.acceptSoundName)									
								end,
							},
							soundFileFail = {
								type = 'select',
								dialogControl = 'LSM30_Sound',
								values = AceGUIWidgetLSMlists.sound,
								order = 6,
								name = "Quest Fail",
								desc = "Select a sound to play when you fail a quest",
								get = function() return self.db.profile.failSoundName end,
								set = function(info, value)
									self.db.profile.failSoundName = value
									self.db.profile.failSoundFile = LSM:Fetch("sound", self.db.profile.failSoundName)
									
								end,
							},							
							soundComm = {
								name = "OA Communication Sounds",
								desc = "Sets whether to play a sound when other players with Objective Announcer send announcements",
								type = "toggle",
								set = function(info,val) self.db.profile.enableCommSound = val end,
								get = function(info) return self.db.profile.enableCommSound end,
								order = 7,
								width = "double",
							},	
							soundFileComm = {
								type = 'select',
								dialogControl = 'LSM30_Sound',
								values = AceGUIWidgetLSMlists.sound,
								order = 8,
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
	LSM:Register("sound", "Hearthstone-QuestAccepted", "Interface\\Addons\\ObjectiveAnnouncer\\Sounds\\Hearthstone-QuestingAdventurer_QuestAccepted.ogg")
	LSM:Register("sound", "Hearthstone-QuestFailed", "Interface\\Addons\\ObjectiveAnnouncer\\Sounds\\Hearthstone-QuestingAdventurer_QuestFailed.ogg")
	
	--[[ LibSink ]]--
	ObjAnnouncer:SetSinkStorage(self.db.profile)
	local libsink = myOptions.args.LibSink
	libsink.name = "Self Outputs"
	libsink.desc = "Select where to send your self messages."
	libsink.order = 2
		--[[ Hide LibSink outputs that would conflict with public announcements ]]--
	libsink.args.Channel.hidden = true	-- If someone selected a channel here, self messages would report to a public channel if all public channels were disabled in OA.  Best to disable this.
	libsink.args.None.hidden = true		-- We already have a way to disable self announcements
	libsink.args.Default.hidden = true	--  Could cause self announcements to announce to public channels...maybe.  In any case, unnecessary.
	
end


function ObjAnnouncer:OnEnable()
	function oaeventHandler(event, ...)
		local logIndex = GetQuestLogIndexByID(qidComplete)
		if  logIndex == 0 then -- Checks to see if the quest that fired the QUEST_COMPLETE event is no longer in the quest log.
			local qIDstring = tostring(qidComplete)
		--	table.insert(oorCompletedQIDs,qIDstring)			
			--[[ Clear oorGroupStorage of unneeded data. ]]--
			for groupMemb = 1, #oorGroupStorage do				
				if oorGroupStorage[groupMemb][qIDstring] then
					table.remove(oorGroupStorage[groupMemb][qIDstring])
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
				local questTitle, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(questIndex)
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
				local questTitle, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isStory = GetQuestLogTitle(questIndex)
				if isHeader ~= 1 then
					if isTask and (not self.db.char.taskStorage[questID]) then
						self.db.char.taskStorage[questID] = {}
					end
			--[[ Announcements Logic ]]-- 
				--[[ Failed Quests ]]--
					if isComplete == -1 and self.db.profile.infoFail and isComplete ~= questCSaved[questIndex] then
						questCSaved[questIndex] = isComplete
						questLink = GetQuestLink(questIndex)
						failedMessage = questLink.." -- QUEST FAILED"
						oaMessageHandler(failedMessage, true, false, false, isComplete)
					end
				--[[ Completed Quests Only ]]--
					if isComplete == 1 then
						--[[ Prune database character task storage of unneeded data.]]--
						if isTask and self.db.char.taskStorage[questID] then
							table.remove(self.db.char.taskStorage[questID])
						end					
						if isComplete ~= questCSaved[questIndex] then
							questCSaved[questIndex] = isComplete
							if self.db.profile.annType ==  1 then
								oaMessageCreator(questIndex, questID, nil, true, level, suggestedGroup, isComplete, frequency)
							end
						end
					end
				--[[ Completed Objectives (and Completed Quests, if Announce Type 3 is selected) ]]--
					for boardIndex = 1, GetNumQuestLeaderBoards(questIndex) do
						local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questIndex)
						if (objComplete) and objComplete ~= objCSaved[questIndex][boardIndex] then
							objCSaved[questIndex][boardIndex] = objComplete
							if self.db.profile.annType == 2 or self.db.profile.annType == 3 then					
								oaMessageCreator(questIndex, questID, objDesc, objComplete, level, suggestedGroup, isComplete, frequency)
							end
						end
						if isTask and (not IsComplete) and (not self.db.char.taskStorage[questID][boardIndex]) then
							self.db.char.taskStorage[questID][boardIndex] = { taskObjDesc = objDesc }
						elseif isTask and (not IsComplete) and (self.db.char.taskStorage[questID][boardIndex].taskObjDesc ~= objDesc) then
							self.db.char.taskStorage[questID][boardIndex].taskObjDesc = objDesc
						end						
					--[[ Announces the progress of objectives (and Completed Quests, if Announce Type 5 is selected)]]--
						if objDesc ~= objDescSaved[questIndex][boardIndex] then
							if not string.find(objDesc, ": 0/") then
								objDescSaved[questIndex][boardIndex] = objDesc	
								if self.db.profile.annType == 4 or self.db.profile.annType == 5 then
									oaMessageCreator(questIndex, questID, objDesc, objComplete, level, suggestedGroup, isComplete, frequency)
								end
							end
						--[[  Send progress to other OA users for OOR Alerts. ]]--
							if (IsInGroup() or IsInRaid()) and (string.find(objDesc, "killed") or string.find(objDesc, "slain")) then
								local chanType = "RAID"	-- "RAID" sends messages to party if not in raid, but check to be sure.									
								if IsInGroup() and not IsInRaid() then chanType = "PARTY" end
							--	chanType = "GUILD"	-- Debug
								oorCommMessage = strjoin("\a", questID, objDesc, boardIndex, tostring(isTask))
								ObjAnnouncer:SendCommMessage("ObjA OOR", oorCommMessage, chanType)
							end
						end
					end
				end
			end
		end		
	end

	ObjAnnouncer:RegisterEvent("QUEST_LOG_UPDATE", oaeventHandler)
	ObjAnnouncer:RegisterEvent("QUEST_ACCEPTED", oaQuestAccepted)
	ObjAnnouncer:RegisterEvent("QUEST_COMPLETE", oaQuestTurnin)
	ObjAnnouncer:RegisterEvent("QUEST_ACCEPT_CONFIRM", oaAcceptEscort)
	if self.db.profile.infoAutoComp then ObjAnnouncer:RegisterEvent("QUEST_AUTOCOMPLETE", oaAutoComplete) end
	ObjAnnouncer:RegisterChatCommand("oa", oacommandHandler)
	ObjAnnouncer:RegisterChatCommand("obja", oacommandHandler)
	ObjAnnouncer:RegisterComm("Obj Announcer", oareceivedComm)
	ObjAnnouncer:RegisterComm("ObjA OOR", oaOORHandler)	-- Always enabled so group objective progress can be recorded. This allows OOR alerts to work immediately upon being enabled.
	DEFAULT_CHAT_FRAME:AddMessage("|cffcc33ffObjective Announcer".." "..version.." Loaded.  Type|r /oa help |cffcc33fffor list of commands.|r")	
end
	
function oaMessageCreator(questIndex, questID, objDesc, objComplete, level, suggestedGroup, isComplete, frequency)

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

function oaMessageHandler(announcement, enableSelf, enableSound, enableComm, isComplete, oorAlert)
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

--[[ Slash Commands Handler ]]--

function oacommandHandler(input)
	local k,v = string.match(string.lower(input), "([%w%+%-%=]+) ?(.*)")
	if slashCommands[k] then	-- If valid...
		slashCommands[k](v)
	elseif k then	-- If user typed something invalid, show help.
	   ObjAnnouncer:Print(helpText)		
	else
		InterfaceOptionsFrame_OpenToCategory(optionsGUI)
	end
end

-- [[ Addon Communication Functions ]]--

function oareceivedComm(prefix, commIn, dist, sender)
	local announceType, announceChannel = ObjAnnouncer:GetArgs(commIn, 2, 1)
	if  self.db.profile.enableCommSound and sender ~= playerName and (announceChannel == "party" or announceChannel == "raid") == true then
		PlaySoundFile(self.db.profile.commSoundFile)
	end
end

function oaOORHandler(prefix, text, dist, groupMember)
	if groupMember ~= playerName then
		local oorQuestID, oorObjDesc, oorBoardIndex, isTask = strsplit("\a", text, 4)
	--	if not oorCompletedQIDs[oorQuestID] then	-- Don't execute for quests that we have completed and turned in this session. (Is this even necessary?)
			if not oorGroupStorage[groupMember] then
				oorGroupStorage[groupMember] = {}
			end
			if not oorGroupStorage[groupMember][oorQuestID] then
				oorGroupStorage[groupMember][oorQuestID] = {}
			end
			local _, _, oorObjCurrent, oorObjTotal, oorObjText = string.find(oorObjDesc, "(%d+)/(%d+) ?(.*)")
			local myLogIndex = GetQuestLogIndexByID(oorQuestID)	
			if self.db.profile.enableOOR and (myLogIndex > 0 or isTask == "true") then	-- Is quest in our log? Also handles tasks that the player has encountered.
				local myObjDesc, myObjType, myObjComplete = GetQuestObjectiveInfo(oorQuestID, oorBoardIndex)
				if ((myObjComplete == false) and (isTask == "false")) or ((myObjComplete == false) and (isTask == "true") and (myObjDesc == self.db.char.taskStorage[oorQuestID][oorBoardIndex].taskObjDesc)) then	-- Don't execute if we're already done with the objective. Also ensure that the return from GQOI() is valid.
					local _, _, myObjCurrent, myObjTotal, myObjText = string.find(myObjDesc, "(%d+)/(%d+) ?(.*)")
					if not oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] then
						oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] = {savedDelta = oorObjCurrent - myObjCurrent}
					end
					local currentDelta = oorObjCurrent - myObjCurrent		
					if tonumber(currentDelta) > tonumber(oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta) then	-- If current delta increased over previous delta, we missed an objective. If delta decreased, do nothing. Using tonumber() because of a strange "comparing number to string" error that sometimes happens.
						local qlink = GetQuestLink(myLogIndex)
						local announcement = groupMember.."'s Objective Credit Not Received: \""..myObjText.."\" -- "..qlink
						oaMessageHandler(announcement, true, false, false, false, true)					
					end	
					oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta = currentDelta
				elseif (not myObjComplete) then	-- Handles tasks the player has not encountered this session. GetQuestObjectiveInfo() for tasks not encountered this login session always returns incorrect values.
					if not oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] then	
						oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] = {savedDelta = oorObjCurrent}
					elseif self.db.char.taskStorage[oorQuestID][oorBoardIndex].taskObjDesc then	-- If task objective was ever advanced, calculate delta based on our saved data.
						local _, _, myTaskCurrent, myTaskTotal, myTaskText = string.find(self.db.char.taskStorage[oorQuestID][oorBoardIndex].taskObjDesc, "(%d+)/(%d+) ?(.*)")
						oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta = oorObjCurrent - myTaskCurrent
					else	-- Otherwise, we've either completed this task previously, or have no progress at all.  Update delta, assuming that our task progress is 0.
						oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta = oorObjCurrent
					end					
				end
			else	-- If quest is not in questlog and is not a task, still save the delta so we can use it when needed.
				if not oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] then
					oorGroupStorage[groupMember][oorQuestID][oorBoardIndex] = {savedDelta = oorObjCurrent}
				else
					oorGroupStorage[groupMember][oorQuestID][oorBoardIndex].savedDelta = oorObjCurrent
				end
			end
	--	end
	end
end

-- [[ Extra Announcements Functions ]] --

function oaQuestAccepted(event, ...)
	local questLogIndex = ...
	--[[ Create initial entry in group members' OOR storage ]]--
		local initQID = GetQuestID()
		for boardIndex = 1, GetNumQuestLeaderBoards(questLogIndex) do
			local objDesc, objType, objComplete = GetQuestLogLeaderBoard(boardIndex, questLogIndex)		
			if (IsInGroup() or IsInRaid()) and (string.find(objDesc, "killed") or string.find(objDesc, "slain")) then
				local chanType = "RAID"	-- "RAID" sends messages to party if not in raid, but check to be sure.									
				if IsInGroup() and not IsInRaid() then chanType = "PARTY" end
			--	chanType = "GUILD"	-- Debug
				oorCommMessage = strjoin("\a", initQID, objDesc, boardIndex)								
				ObjAnnouncer:SendCommMessage("ObjA OOR", oorCommMessage, chanType)	
			end
		end
	if self.db.profile.questAccept then		
		local acceptedLink = GetQuestLink(questLogIndex)
		local Message = "Quest Accepted -- "..acceptedLink
		if self.db.profile.enableAcceptFailSound then PlaySoundFile(self.db.profile.acceptSoundFile,"Master") end
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