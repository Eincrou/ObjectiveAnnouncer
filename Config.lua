local NAME, S = ...
local ObjAnn = _G.ObjAnnouncer
local optionsGUI = {}

local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local LSM = LibStub("LibSharedMedia-3.0")

local myOptions = {
	name = NAME.." "..S.VERSION.." |cFFFF7F00by Bantou|r |cFF339900and Eincrou|r",
	type = "group",
	childGroups = "tab",
	args = {
		options = {
			name = "General",
			type="group",
			order = 1,
			args={
				announceModes = {
				--	inline = true,
					name = "|TInterface\\Icons\\Ability_Warrior_RallyingCry:18|t Announce Mode",
					desc = "Set when to send announcements for quests and objectives.",
					type="group",
					order = 1,
					args = {
						annchandesc = {
							order = 1,
							type = "description",
							name = "Set when to send announcements for quests and objectives.",
						},								
						announce = {
							name = "Announcement Mode",
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
							set = function(info,val) ObjAnn.db.profile.annType = val end,
							get = function(info) return ObjAnn.db.profile.annType end,
							order = 2,
						},
						progressbar = {
							name = "When using \"Both Quests & Objectives\" mode and a bonus objective has a progress bar, set how often announcements are sent.",
							type = "description",
							order = 3,							
							width = "full"						
						},						
						progressbarint = {
							name = "Progress Bar % Interval",
							desc = "How often to announce your progress bar quests.|n|cFF9ffbffOnly effective with \"Both Quests & Objectives.\" \"Objective Progress\" or \"Progress & Comp. Quests\" announce every time progress advances.|r",
							type = "range",
							min = 0.05,
							max = 0.5,
							set = function(info,val) ObjAnn.db.profile.progBarInterval = val * 100 end,
							get = function(info) return ObjAnn.db.profile.progBarInterval / 100 end,			
							step = 0.05,
							order = 4,
							isPercent = true,
							disabled = function ()
								local disableRange = true
								if ObjAnn.db.profile.annType == 3 then
									disableRange = false 
								end
								return disableRange
							end,
						},
					},
				},
				announceChannels = {
				--	inline = true,
					name = "|TInterface\\Icons\\Warrior_disruptingshout:18|t Announce To",
					desc = "Set who will see your announcements.",
					type="group",
					order = 2,
					args = {
						annchandesc = {
							order = 1,
							type = "description",
							name = "Set who will see your announcements.",
						},						
					--[[ Private ]]--
						header1 = {
							name = "Private Announcements",
							type = "header",
							order = 2,
							width = "double"
						},
						mememe = {
							name = "Self",
							desc = "Sets whether to announce to yourself when no public announcements have been made.|n|cFF9ffbffChoose where to output your self messages in the Self Output tab above.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.selftell = val end,
							get = function(info) return ObjAnn.db.profile.selftell end,
							order = 4,
							disabled = function() return ObjAnn.db.profile.selftellalways end,
							width = "half"
						},
						mememealways = {
							name = "Always Self Announce",
							desc = "Announce to self even when a public message has been sent.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.selftellalways = val end,
							get = function(info) return ObjAnn.db.profile.selftellalways end,
							order = 6,
							width = "normal"
						},
						selfTextColor = {
							name = "Color for self messages",
							desc = "Choose your color.",
							type = "color",
							get = function() return ObjAnn.db.profile.selfColor.r, ObjAnn.db.profile.selfColor.g, ObjAnn.db.profile.selfColor.b, 1.0 end,
							set = function(info, r, g, b, a)
								ObjAnn.db.profile.selfColor.r, ObjAnn.db.profile.selfColor.g, ObjAnn.db.profile.selfColor.b = r, g, b
								ObjAnn.db.profile.selfColor.hex = "|cff"..string.format("%02x%02x%02x", ObjAnn.db.profile.selfColor.r * 255, ObjAnn.db.profile.selfColor.g * 255, ObjAnn.db.profile.selfColor.b * 255) 
								end,								
							order = 8,
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
							set = function(info,val) ObjAnn.db.profile.saychat = val end,
							get = function(info) return ObjAnn.db.profile.saychat end,
							order = 12,							
							width = "half"
						},
						party = {
							name = "|cFFA8A8FFParty|r",	-- /dump ChatTypeInfo.PARTY
							desc = "Sets whether to announce to Party Chat.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.partychat = val end,
							get = function(info) return ObjAnn.db.profile.partychat end,
							order = 14,
							width = "half"
						},
						instance = {
							name = "|cFFFD8100Instance",
							desc = "Sets whether to announce to Instance Chat if in a Looking For Dungeon group.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.instancechat = val end,
							get = function(info) return ObjAnn.db.profile.instancechat end,
							order = 16,
							width = "half"
						},
						raid = {
							name = "|cFFFF7F00Raid",
							desc = "Sets whether to announce to Raid Chat.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.raidchat = val end,
							get = function(info) return ObjAnn.db.profile.raidchat end,
							order = 18,
							width = "half"
						},
						guild = {
							name = "|cFF40FF40Guild",
							desc = "Sets whether to announce to Guild Chat|n|cFFF02121(Disables Officer Chat announcements).",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.guildchat = val end,
							get = function(info) return ObjAnn.db.profile.guildchat end,
							order = 20,
							width = "half"
						},
						officer = {
							name = "|cFF40C040Officer",
							desc = "Sets whether to announce to Officer Chat.|n|cFF9ffbff(Only if no announcement has already been sent to Guild)",
							type = "toggle",
							disabled = function() return ObjAnn.db.profile.guildchat end,
							set = function(info,val) ObjAnn.db.profile.officerchat = val end,
							get = function(info) return ObjAnn.db.profile.officerchat end,
							order = 22,
							width = "half",
						},
						channel = {
							name = "|cFFFFC0C0Channel",
							desc = "Sets whether to announce to a channel. Please don't be rude!",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.channelchat = val end,
							get = function(info) return ObjAnn.db.profile.channelchat end,
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
							set = function(info,val) ObjAnn.db.profile.chanName = val end,
							get = function(info) return ObjAnn.db.profile.chanName end,
							order = 26,
						},
					},
				},
				oorAlerts = {
				--	inline = true,
					name = "|TInterface\\Icons\\ability_rogue_combatexpertise:18|t Out-Of-Range Alerts",
					desc = "Announce when you miss credit for a kill quest.",
					type="group",
					order = 4,
					args={
						oordesc = {
							order = 1,
							type = "description",
							name = "Requires party or raid members to have Objective Announcer v6.0.3a or higher.",
						},					
						qlink = {
							name = "Enable OOR Alerts",
							desc = "Send announcements if you do not receive credit when party members using Objective Announcer advance kill quests.|n|cFF9ffbffRequires party members to have Objective Announcer v6.0.3a+.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.enableOOR = val end,
							get = function(info) return ObjAnn.db.profile.enableOOR end,
							order = 2,
						},							
					},
				},					
				extraInfo = {
				--	inline = true,
					name = "|TInterface\\Icons\\inv_jewelry_trinket_15:18|t Extra Information",
					desc = "Add additional information about quests to announcements.",
					type="group",
					order = 4,
					args={
						oordesc = {
							order = 1,
							type = "description",
							name = "Add additional information about quests to announcements.",
						},						
						qlink = {
							name = "Quest Link",
							desc = "Adds a clickable link of the relevant quest to your objective and progress announcements.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.questlink = val end,
							get = function(info) return ObjAnn.db.profile.questlink end,
							order = 2,
						},
						qgroupsize = {
							name = "Suggested Group",
							desc = "Adds the quest's suggested group size to your announcements.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.infoSuggGroup = val end,
							get = function(info) return ObjAnn.db.profile.infoSuggGroup end,
							order = 3,
						},
						qtag = {
							name = "Quest Tag",
							desc = "Adds special tagging of quest to announcements.|n|cFF9ffbffGroup, Raid, Account, etc.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.infoTag = val end,
							get = function(info) return ObjAnn.db.profile.infoTag end,
							order = 4,
						},
						qfreq = {
							name = "Frequency",
							desc = "Adds whether it's a daily or weekly quest to your announcements.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.infoFrequency = val end,
							get = function(info) return ObjAnn.db.profile.infoFrequency end,
							order = 5,
						},									
						qlevel = {
							name = "Quest Level",
							desc = "Adds the intended level of the quest to announcements.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.infoLevel = val end,
							get = function(info) return ObjAnn.db.profile.infoLevel end,
							order = 6,
						},
			
					},
				},
				questStartEnd = {
				--	inline = true,
					name = "|TInterface\\Icons\\Achievement_quests_completed_08:18|t Quest Start/End",
					desc = "Announcements and assistance for beginning and ending quests.",
					type="group",
					order = 5,
					args={
						oordesc = {
							order = 1,
							type = "description",
							name = "Announcements and assistance for beginning and ending quests.",
						},							
						accept = {
							name = "Accept a Quest",
							desc = "Make an announcement when you accept a new quest.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.questAccept = val end,
							get = function(info) return ObjAnn.db.profile.questAccept end,
							order = 2,
							width = "normal",
						},
						turnIn = {
							name = "Turn in a Quest",
							desc = "Make an announcement when you turn in a quest.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.questTurnin = val end,
							get = function(info) return ObjAnn.db.profile.questTurnin end,
							order = 3,
						},
						qfailed = {
							name = "Fail a Quest",
							desc = "Make an announcement when you fail a quest.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.questFail = val end,
							get = function(info) return ObjAnn.db.profile.questFail end,
							order = 4,
						},										
						escort = {
							name = "Auto-accept escort/event quests",
							desc = "Automatically accepts event quests started by party members.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.questEscort = val end,
							get = function(info) return ObjAnn.db.profile.questEscort end,
							order = 5,
							width = "double",
						},
						qautocomp = {
							name = "Auto-Complete",
							desc = "Send an extra announcement when you complete a quest that can be completed remotely.|n|cFF9ffbffAlso causes the remote turn-in dialogue window to appear.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.infoAutoComp = val end,
							get = function(info) return ObjAnn.db.profile.infoAutoComp end,
							order = 6,								
						},
						taskArea = {
							name = "Bonus Objective",
							desc = "Send an extra announcement when you enter a Bonus Objective area.|n|cFF9ffbffWill not announce unless you receive the bonus objective.",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.questTask = val end,
							get = function(info) return ObjAnn.db.profile.questTask end,
							order = 7,								
						},
					},
				},					
				soundOptions = {
				--	inline = true,
					name = "|TInterface\\Icons\\Inv_misc_archaeology_trolldrum:18|t Sound",
					desc = "Play sounds for questing events.",
					type="group",
					order = 6,
					args={
						oordesc = {
							order = 1,
							type = "description",
							name = "Play sounds for questing events.",
						},						
						soundCompletion = {
							name = "Completion Sounds",
							desc = "Sets whether to play sounds when announcements are made.|n|cFF9ffbffOnly plays if an announcement is sent",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.enableCompletionSound = val end,
							get = function(info) return ObjAnn.db.profile.enableCompletionSound end,
							order = 2,
						},
						soundFileObj = {
							type = 'select',
							dialogControl = 'LSM30_Sound',
							values = AceGUIWidgetLSMlists.sound,
							order = 3,
							name = "Objective Complete",
							desc = "Select a sound to play when you complete an objective",
							get = function() return ObjAnn.db.profile.annSoundName end,
							set = function(info, value)
								ObjAnn.db.profile.annSoundName = value
								ObjAnn.db.profile.annSoundFile = LSM:Fetch("sound", ObjAnn.db.profile.annSoundName)									
							end,
						},
						soundFileComp = {
							type = 'select',
							dialogControl = 'LSM30_Sound',
							values = AceGUIWidgetLSMlists.sound,
							order = 4,
							name = "Quest Complete",
							desc = "Select a sound to play when you complete a quest",
							get = function() return ObjAnn.db.profile.compSoundName end,
							set = function(info, value)
								ObjAnn.db.profile.compSoundName = value
								ObjAnn.db.profile.compSoundFile = LSM:Fetch("sound", ObjAnn.db.profile.compSoundName)
								
							end,
						},
						soundAcceptFail = {
							name = "Accept/Fail Sounds",
							desc = "Sets whether to play sounds when accepting or failing a quest.|n|cFF9ffbffOnly plays if an announcement is sent",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.enableAcceptFailSound = val end,
							get = function(info) return ObjAnn.db.profile.enableAcceptFailSound end,
							order = 5,
						},
						soundFileAccept = {
							type = 'select',
							dialogControl = 'LSM30_Sound',
							values = AceGUIWidgetLSMlists.sound,
							order = 6,
							name = "Quest Accept",
							desc = "Select a sound to play when you accept a new quest",
							get = function() return ObjAnn.db.profile.acceptSoundName end,
							set = function(info, value)
								ObjAnn.db.profile.acceptSoundName = value
								ObjAnn.db.profile.acceptSoundFile = LSM:Fetch("sound", ObjAnn.db.profile.acceptSoundName)									
							end,
						},
						soundFileFail = {
							type = 'select',
							dialogControl = 'LSM30_Sound',
							values = AceGUIWidgetLSMlists.sound,
							order = 7,
							name = "Quest Fail",
							desc = "Select a sound to play when you fail a quest",
							get = function() return ObjAnn.db.profile.failSoundName end,
							set = function(info, value)
								ObjAnn.db.profile.failSoundName = value
								ObjAnn.db.profile.failSoundFile = LSM:Fetch("sound", ObjAnn.db.profile.failSoundName)
								
							end,
						},							
						soundComm = {
							name = "OA Communication Sounds",
							desc = "Sets whether to play a sound when other players with Objective Announcer send announcements",
							type = "toggle",
							set = function(info,val) ObjAnn.db.profile.enableCommSound = val end,
							get = function(info) return ObjAnn.db.profile.enableCommSound end,
							order = 8,
							width = "double",
						},	
						soundFileComm = {
							type = 'select',
							dialogControl = 'LSM30_Sound',
							values = AceGUIWidgetLSMlists.sound,
							order = 9,
							name = "OA Communication",
							desc = "Select a sound to play when another player announces an objective",
							get = function() 
								return ObjAnn.db.profile.commSoundName
							end,
							set = function(info, value)
								ObjAnn.db.profile.commSoundName = value
								ObjAnn.db.profile.commSoundFile = LSM:Fetch("sound", ObjAnn.db.profile.commSoundName)								
							end,
						},							
					},
				},
			},
		},
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
   |cff55ff55/oa oor|r Toggle Out-of-range Alerts]]
 --[[   |cff55ff55/oa accept|r Toggle "Accept A Quest"
   |cff55ff55/oa turnin|r Toggle "Turn In A Quest"
   |cff55ff55/oa escort|r Toggle "Auto-Accept Escort/Event Quests"
   |cff55ff55/oa fail|r Toggle "Quest Failure"
   |cff55ff55/oa soundcomp|r Toggle Completion Sounds
   |cff55ff55/oa soundaf|r Toggle Accept/Fail Sounds   
   |cff55ff55/oa soundcomm|r Toggle Communication Sounds]]
   
local slashCommands = {
	["quest"] = function()
		ObjAnn.db.profile.annType = 1
		ObjAnnouncer:Print("Now Announcing Completed Quests Only")
	end,
	["obj"] = function()
		ObjAnn.db.profile.annType = 2
		ObjAnnouncer:Print("Now Announcing Completed Objectives Only")
	end,
	["both"] = function()
		ObjAnn.db.profile.annType = 3
		ObjAnnouncer:Print("Now Announcing Both Completed Quests & Objectives")
	end,
	["prog"] = function()
		ObjAnn.db.profile.annType = 4
		ObjAnnouncer:Print("Now Announcing Objective Progress")
	end,
	["progq"] = function()
		ObjAnn.db.profile.annType = 5
		ObjAnnouncer:Print("Now Announcing Objective Progress & Completed Quests")		
	end,
	["self"] = function()
		if ObjAnn.db.profile.selftell then
			ObjAnn.db.profile.selftell = false
			ObjAnn.db.profile.selftellalways = false
			ObjAnnouncer:Print("Self Messages |cFFFF0000Disabled|r (Always Self Announce also disabled)")
		else
			ObjAnn.db.profile.selftell = true
			ObjAnnouncer:Print("Self Messages |cFF00FF00Enabled|r")
		end
	end,
	["pub"] = function(v)
		if v == "say" then	-- There's probably a more efficient way to do this, but it works...
			if ObjAnn.db.profile.saychat then
				ObjAnn.db.profile.saychat = false
				ObjAnnouncer:Print("Say Chat |cFFFF0000Disabled|r")
			else
				ObjAnn.db.profile.saychat = true
				ObjAnnouncer:Print("Say Chat |cFF00FF00Enabled|r")
			end
		elseif	v == "party" then
			if ObjAnn.db.profile.partychat then
				ObjAnn.db.profile.partychat = false
				ObjAnnouncer:Print("|cFFA8A8FFParty Chat|r |cFFFF0000Disabled|r")
			else
				ObjAnn.db.profile.partychat = true
				ObjAnnouncer:Print("|cFFA8A8FFParty Chat|r |cFF00FF00Enabled|r")
			end
		elseif v == "instance" then
			if ObjAnn.db.profile.instancechat then
				ObjAnn.db.profile.instancechat = false
				ObjAnnouncer:Print("|cFFFD8100Instance Chat|r |cFFFF0000Disabled|r")
			else
				ObjAnn.db.profile.instancechat = true
				ObjAnnouncer:Print("|cFFFD8100Instance Chat|r |cFF00FF00Enabled|r")
			end
		elseif v == "raid" then
			if ObjAnn.db.profile.raidchat then
				ObjAnn.db.profile.raidchat = false
				ObjAnnouncer:Print("|cFFFF7F00Raid Chat|r |cFFFF0000Disabled|r")
			else
				ObjAnn.db.profile.raidchat = true
				ObjAnnouncer:Print("|cFFFF7F00Raid Chat|r |cFF00FF00Enabled|r")
			end		
		elseif v == "guild" then
			if ObjAnn.db.profile.guildchat then
				ObjAnn.db.profile.guildchat = false
				ObjAnnouncer:Print("|cFF40ff40Guild Chat|r |cFFFF0000Disabled|r")
			else
				ObjAnn.db.profile.guildchat = true
				ObjAnnouncer:Print("|cFF40ff40Guild Chat|r |cFF00FF00Enabled|r")
			end
		elseif v == "officer" then
			if ObjAnn.db.profile.officerchat then
				ObjAnn.db.profile.officerchat = false
				ObjAnnouncer:Print("|cFF40c040Officer Chat|r |cFFFF0000Disabled|r")
			else
				ObjAnn.db.profile.officerchat = true
				ObjAnn.db.profile.guildchat = false
				ObjAnnouncer:Print("|cFF40c040Officer Chat|r |cFF00FF00Enabled|r (|cFF40ff40Guild Chat|r |cFFFF0000Disabled|r)")
			end
		elseif v == "channel" then
			if ObjAnn.db.profile.channelchat then
				ObjAnn.db.profile.channelchat = false
				ObjAnnouncer:Print("|cFFffc0c0Channel Chat|r |cFFFF0000Disabled|r")
			else
				ObjAnn.db.profile.channelchat = true
				ObjAnnouncer:Print("|cFFffc0c0Channel Chat|r |cFF00FF00Enabled|r")
			end
		else
			ObjAnnouncer:Print("Valid public chat names are: say, party, instance, raid, guild, officer & channel.")
		end
	end,
	["oor"] = function()
		if ObjAnn.db.profile.enableOOR then
			ObjAnn.db.profile.enableOOR = false
			ObjAnnouncer:Print("Out-of-range Alerts |cFFFF0000Disabled|r")
		else
			ObjAnn.db.profile.enableOOR = true
			ObjAnnouncer:Print("Out-of-range Alerts |cFF00FF00Enabled|r")
		end
	end,			
	["accept"] = function()
		if ObjAnn.db.profile.questAccept then
			ObjAnn.db.profile.questAccept = false
			ObjAnnouncer:Print("Announce Quest Accepted |cFFFF0000Disabled|r")
		else
			ObjAnn.db.profile.questAccept = true
			ObjAnnouncer:Print("Announce Quest Accepted |cFF00FF00Enabled|r")
		end
	end,		
	["turnin"] = function()
		if ObjAnn.db.profile.questTurnin then
			ObjAnn.db.profile.questTurnin = false
			ObjAnnouncer:UnregisterEvent("QUEST_COMPLETE", oaQuestTurnin)
			ObjAnnouncer:Print("Announce Quest Turn-in |cFFFF0000Disabled|r")
		else
			ObjAnn.db.profile.questTurnin = true
			ObjAnnouncer:RegisterEvent("QUEST_COMPLETE", oaQuestTurnin)
			ObjAnnouncer:Print("Announce Quest Turn-in |cFF00FF00Enabled|r")
		end
	end,
	["escort"] = function()
		if ObjAnn.db.profile.questEscort then
			ObjAnn.db.profile.questEscort = false
			ObjAnnouncer:Print("Announce Failed Quests |cFFFF0000Disabled|r")
		else
			ObjAnn.db.profile.questEscort = true
			ObjAnnouncer:Print("Announce Failed Quests |cFF00FF00Enabled|r")
		end
	end,			
	["fail"] = function()
		if ObjAnn.db.profile.questFail then
			ObjAnn.db.profile.questFail = false
			ObjAnnouncer:Print("Announce Failed Quests |cFFFF0000Disabled|r")
		else
			ObjAnn.db.profile.questFail = true
			ObjAnnouncer:Print("Announce Failed Quests |cFF00FF00Enabled|r")
		end
	end,		
	["soundcomp"] = function()
		if ObjAnn.db.profile.enableCompletionSound then
			ObjAnn.db.profile.enableCompletionSound = false
			ObjAnnouncer:Print("Quest/Objective Complete Sounds |cFFFF0000Disabled|r")
		else
			ObjAnn.db.profile.enableCompletionSound = true
			ObjAnnouncer:Print("Quest/Objective Complete Sounds |cFF00FF00Enabled|r")
		end
	end,
	["soundaf"] = function()
		if ObjAnn.db.profile.enableAcceptFailSound then
			ObjAnn.db.profile.enableAcceptFailSound = false
			ObjAnnouncer:Print("Quest Accept/Fail Sounds |cFFFF0000Disabled|r")
		else
			ObjAnn.db.profile.enableAcceptFailSound = true
			ObjAnnouncer:Print("Quest Accept/Fail Sounds |cFF00FF00Enabled|r")
		end
	end,		
	["soundcomm"] = function()
		if ObjAnn.db.profile.enableCommSound then
			ObjAnn.db.profile.enableCommSound = false
			ObjAnnouncer:Print("Communication Sounds |cFFFF0000Disabled|r")
		else
			ObjAnn.db.profile.enableCommSound = true
			ObjAnnouncer:Print("Communication Sounds |cFF00FF00Enabled|r")
		end
	end,		
}	

function ObjAnn:oacommandHandler(input)
	local k,v = string.match(string.lower(input), "([%w%+%-%=]+) ?(.*)")
	if slashCommands[k] then	-- If valid...
		slashCommands[k](v)
	elseif k then	-- If user typed something invalid, show help.
	   ObjAnn:Print(helpText)		
	else
		if ACD.OpenFrames[NAME] then
			ACD:Close(NAME)
		else
			ACD:Open(NAME)
		end			
	--	InterfaceOptionsFrame_OpenToCategory(optionsGUI.general)
	end
end

	--[[ LibSharedMedia ]]--
LSM:Register("sound", "PVPFlagCapturedHorde","Sound\\Interface\\PVPFlagCapturedHordeMono.wav")
LSM:Register("sound", "PVPFlagCaptured", "Sound\\Interface\\PVPFlagCapturedMono.wav")
LSM:Register("sound", "GM ChatWarning", "Sound\\Interface\\GM_ChatWarning.ogg")
LSM:Register("sound", "Hearthstone-QuestAccepted", "Interface\\Addons\\ObjectiveAnnouncer\\Sounds\\Hearthstone-QuestingAdventurer_QuestAccepted.ogg")
LSM:Register("sound", "Hearthstone-QuestFailed", "Interface\\Addons\\ObjectiveAnnouncer\\Sounds\\Hearthstone-QuestingAdventurer_QuestFailed.ogg")



ObjAnn.myOptions = myOptions
ACR:RegisterOptionsTable(NAME, myOptions)
LibStub("AceConfig-3.0"):RegisterOptionsTable("Objective Announcer", myOptions)
optionsGUI.general = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Objective Announcer")
optionsGUI.libsink = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Objective Announcer", "Self Outputs", "Objective Announcer", "libsink")
optionsGUI.profile = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Objective Announcer", "Profiles", "Objective Announcer", "profile")


ObjAnn:RegisterChatCommand("oa", "oacommandHandler")
ObjAnn:RegisterChatCommand("obja", "oacommandHandler")
