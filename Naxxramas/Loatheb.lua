------------------------------
--      Are you local?      --
------------------------------

local boss = AceLibrary("Babble-Boss-2.0")("Loatheb")
local L = AceLibrary("AceLocale-2.0"):new("BigWigs"..boss)

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "loatheb",

	doom_cmd = "doom",
	doom_name = "Inevitable Doom Alert",
	doom_desc = "Warn for Inevitable Doom",
	
	spore_cmd = "spore",
	spore_name = "Spore Spawning Alert",
	spore_desc = "Warn when a spore spawns",

	curse_cmd = "curse",
	curse_name = "Remove Curse Alert",
	curse_desc = "Warn when a curses are removed from Loatheb",

	doombar = "Inevitable Doom",
	doomwarn = "Inevitable Doom",
	doomwarn5sec = "Inevitable Doom in 5 seconds",		
	doomtrigger = "^([^%s]+) is afflicted by Inevitable Doom.",
	
	sporewarn = "Spore Spawned",
	sporebar = "Summon Spore",
	sporespawntrigger = "Loatheb casts Summon Spore.",
	sporedietrigger = "Spore dies.",

	removecursewarn = "Curses removed on Loatheb",
	removecursebar = "Remove Curse",
	removecursetrigger = "Loatheb casts Remove Curse on Loatheb.",

	you = "You",
	are = "are",
} end )


----------------------------------
--      Module Declaration      --
----------------------------------

BigWigsLoatheb = BigWigs:NewModule(boss)
BigWigsLoatheb.zonename = AceLibrary("Babble-Zone-2.0")("Naxxramas")
BigWigsLoatheb.enabletrigger = boss
BigWigsLoatheb.toggleoptions = {"doom", "spore", "curse", "bosskill"}
BigWigsLoatheb.revision = tonumber(string.sub("$Revision$", 12, -3))

------------------------------
--      Initialization      --
------------------------------

function BigWigsLoatheb:OnEnable()
	self.started = nil

	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF")

	self:RegisterEvent("BigWigs_RecvSync")
	self:TriggerEvent("BigWigs_ThrottleSync", "LoathebDoom", 10)
	self:TriggerEvent("BigWigs_ThrottleSync", "LoathebStart", 10)
	self:TriggerEvent("BigWigs_ThrottleSync", "LoathebSporeSpawn", 5)
	self:TriggerEvent("BigWigs_ThrottleSync", "LoathebRemoveCurse", 10)
end

function BigWigsLoatheb:PLAYER_REGEN_ENABLED()
	local go = self:Scan()
	local running = self:IsEventScheduled("Loatheb_CheckWipe")
	if (not go) then
		self:TriggerEvent("BigWigs_RebootModule", self)
	elseif (not running) then
		self:ScheduleRepeatingEvent("Loatheb_CheckWipe", self.PLAYER_REGEN_ENABLED, 2, self)
	end
end

function BigWigsLoatheb:Scan()
	if (UnitName("target") == boss and UnitAffectingCombat("target")) then
		return true
	elseif (UnitName("playertarget") == boss and UnitAffectingCombat("playertarget")) then
		return true
	else
		local i
		for i = 1, GetNumRaidMembers(), 1 do
			if (UnitName("raid"..i.."target") == boss and UnitAffectingCombat("raid"..i.."target")) then
				return true
			end
		end
	end
	return false
end

function BigWigsLoatheb:PLAYER_REGEN_DISABLED()
	local go = self:Scan()
	local running = self:IsEventScheduled("Loatheb_CheckStart")
	if (go) then
		self:CancelScheduledEvent("Loatheb_CheckStart")
		self:TriggerEvent("BigWigs_SendSync", "LoathebStart")
	elseif not running then
		self:ScheduleRepeatingEvent("Loatheb_CheckStart", self.PLAYER_REGEN_DISABLED, .5, self)
	end
end

function BigWigsLoatheb:BigWigs_RecvSync(sync)
	if sync == "LoathebStart" and not self.started then
		self.started = true
		if self.db.profile.doom then 
			self:TriggerEvent("BigWigs_StartBar", self, L"doombar", 120, 1, "Interface\\Icons\\Spell_Shadow_NightOfTheDead", "Green", "Yellow", "Orange", "Red")
			self:ScheduleEvent("bwloathebdoom", "BigWigs_Message", 115, L"doomwarn5sec", "Orange")
		end
	elseif sync == "LoathebDoom" then
		if self.db.profile.doom then
			self:TriggerEvent("BigWigs_Message", L"doomwarn", "Red")
			self:TriggerEvent("BigWigs_StartBar", self, L"doombar", 30, 1, "Interface\\Icons\\Spell_Shadow_NightOfTheDead", "Yellow", "Orange", "Red")
			self:ScheduleEvent("bwloathebdoom", "BigWigs_Message", 25, L"doomwarn5sec", "Orange")
		end
	elseif sync == "LoathebSporeSpawn" then
		if self.db.profile.spore then
			self:TriggerEvent("BigWigs_Message", L"sporewarn", "Red")
			self:TriggerEvent("BigWigs_StartBar", self, L"sporebar", 12, 2, "Interface\\Icons\\Ability_TheBlackArrow", "Yellow", "Orange", "Red")
		end
	elseif sync == "LoathebRemoveCurse" then
		if self.db.profile.curse then
			self:TriggerEvent("BigWigs_Message", L"removecursewarn", "Red")
			self:TriggerEvent("BigWigs_StartBar", self, L"removecursebar", 30, 3, "Interface\\Icons\\Spell_Holy_RemoveCurse", "Yellow", "Orange", "Red")
		end
	end
end

--triggers
function BigWigsLoatheb:Event( msg )
	if string.find(msg, L"doomtrigger") then self:TriggerEvent("BigWigs_SendSync", "LoathebDoom") end
end

function BigWigsLoatheb:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	if string.find(msg, L"sporedietrigger") then
		self:TriggerEvent("BigWigs_SendSync", "LoathebSporeDie")
	end

	self:GenericBossDeath(msg)
end

function BigWigsLoatheb:CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF( msg )
	if msg == L"sporespawntrigger" then 
		self:TriggerEvent("BigWigs_SendSync", "LoathebSporeSpawn")
	elseif msg == L"removecursetrigger" then 
		self:TriggerEvent("BigWigs_SendSync", "LoathebRemoveCurse")
	end
end

