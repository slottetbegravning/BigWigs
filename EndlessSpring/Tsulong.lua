
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Tsulong", 886, 742)
if not mod then return end
mod:RegisterEnableMob(62442)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.win_trigger = "I thank you, strangers" -- I thank you, strangers. I have been freed.

	L.phases = "Phases"
	L.phases_desc = "Warning for phase changes"

	L.unstable_sha, L.unstable_sha_desc = EJ_GetSectionInfo(6320)
	L.unstable_sha_icon = 122938

	L.breath, L.breath_desc = EJ_GetSectionInfo(6313)
	L.breath_icon = 122752

	L.day = EJ_GetSectionInfo(6315)
	L.night = EJ_GetSectionInfo(6310)
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"ej:6550",
		"breath", 122768, 122789, { 122777, "PROXIMITY", "FLASHSHAKE", "SAY" },
		122855, "unstable_sha", 123011,
		"berserk", "phases", "bosskill",
	}, {
		["ej:6550"] = "heroic",
		["breath"] = L["night"],
		[122855] = L["day"],
		berserk = "general",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "SunBreath", 122855)
	self:Log("SPELL_CAST_SUCCESS", "ShadowBreath", 122752)
	self:Log("SPELL_CAST_SUCCESS", "Terrorize", 123011)
	self:Log("SPELL_AURA_APPLIED_DOSE", "DreadShadows", 122768)
	self:Log("SPELL_AURA_APPLIED", "Sunbeam", 122789)
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "EngageCheck")

	self:Yell("Win", L["win_trigger"])
	self:Death("Deaths", 62969)
end

function mod:OnEngage(diff)
	self:OpenProximity(8, 122777)
	self:Berserk(self:LFR() and 600 or 490)
	self:Bar("phases", L["day"], 121, 122789)
	self:Bar(122777, 122777, 15.6, 122777) --Nightmares
end

function mod:VerifyEnable(unit)
	return UnitCanAttack("player", unit)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:EngageCheck()
	self:CheckBossStatus()
	-- assume only 1 Embodied Terror is up at a time, else you wipe
	if UnitExists("boss2") and self:GetCID(UnitGUID("boss2")) == 62969 then
		self:Bar(123011, "~"..self:SpellName(123011), 5, 123011) -- Terrorize
	end
end

function mod:Terrorize(_, spellId, _, _, spellName)
	self:Message(spellId, spellName, "Important", spellId)
	self:Bar(spellId, spellName, 41, spellId) -- stop this when add dies, might be tricky if more than one add can be up
end

function mod:DreadShadows(player, spellId, _, _, spellName, buffStack)
	if UnitIsUnit("player", player) and buffStack > (self:Heroic() and 5 or 11) and buffStack % 3 == 0 then -- might need adjusting
		self:LocalMessage(spellId, ("%s (%d)"):format(spellName, buffStack), "Personal", spellId, "Info")
	end
end

function mod:Sunbeam(player, spellId, _, _, spellName)
	if UnitIsUnit("player", player) then
		self:LocalMessage(spellId, spellName, "Positive", spellId)
	end
end

function mod:SunBreath(_, spellId, _, _, spellName)
	self:Bar(spellId, spellName, 29, spellId)
	self:Message(spellId, spellName, "Urgent", spellId)
end

function mod:ShadowBreath(player, spellId, _, _, spellName)
	self:Bar("breath", "~"..spellName, 25, spellId)
	self:Message("breath", spellName, "Urgent", spellId)
end

do
	local prev = 0
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, unitId, _, _, _, spellId)
		if not unitId:match("boss") then return end

		if spellId == 123252 then -- end of night phase
			self:CloseProximity(122777)
			self:StopBar(122752) -- shadow breath
			self:Message("phases", L["day"], "Positive", 122789)
			self:Bar("phases", L["night"], 121, 122768)
			self:Bar("unstable_sha", 122953, 18, 122938)
		elseif spellId == 122767 then -- start of night phase
			self:OpenProximity(8, 122777)
			self:Message("phases", L["night"], "Positive", 122768)
			self:Bar("phases", L["day"], 121, 122789)
			self:StopBar(122953) -- summon unstable sha
			self:StopBar(122855) -- sun breath
		elseif spellId == 122953 then -- summon unstable sha
			local t = GetTime()
			if t-prev > 2 then
				prev = t
				self:Message("unstable_sha", spellId, "Important", 122938, "Alert") -- summon unstable sha
				self:Bar("unstable_sha", spellId, 18, 122938) -- summon unstable sha
			end
		elseif spellId == 122770 or spellId == 122775 then -- Nightmares
			local t = GetTime()
			if t-prev > 2 then
				prev = t
				self:Bar(122777, 122777, 15, 122777) -- Nightmares
				self:Message(122777, 122777, "Attention", 122777)
			end
		elseif spellId == 123813 then -- dark of night- heroic
			self:Bar("ej:6550", spellId, 30, 130013) -- dark of night
			self:Message("ej:6550", spellId, "Urgent", 130013, "Alarm") -- dark of night
		end
	end
end

function mod:Deaths(mobId)
	self:StopBar(123011) -- Terrorize
end

