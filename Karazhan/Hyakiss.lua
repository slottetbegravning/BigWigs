﻿------------------------------
--      Are you local?      --
------------------------------

local boss = BB["Hyakiss the Lurker"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local L2 = AceLibrary("AceLocale-2.2"):new("BigWigsCommonWords")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Hyakiss",

	web = "Web",
	web_desc = "Alert when a player gets webbed.",
	web_trigger = "^(%S+) (%S+) afflicted by Hyakiss' Web%.$",
	web_message = "%s has been webbed!",
	web_bar = "Web: %s",
} end )

L:RegisterTranslations("zhTW", function() return {
	web = "亞奇斯之網",
	web_desc = "當人員受到亞奇斯之網影響時警告",
	web_trigger = "^(.+)受(到[了]*)亞奇斯之網效果的影響。",
	web_message = "亞奇斯之網：[%s]",
	web_bar = "亞奇斯之網：%s",
} end )

L:RegisterTranslations("frFR", function() return {
	web = "Rets",
	web_desc = "Préviens quand un joueur se fait piégé par les Rets.",
	web_trigger = "^(%S+) (%S+) subit les effets .* Rets d'Hyakiss%.$",
	web_message = "%s a été piégé par les Rets !",
	web_bar = "Rets : %s",
} end )

L:RegisterTranslations("koKR", function() return {
	web = "거미줄",
	web_desc = "거미줄에 걸린 플레이어를 알립니다.",
	web_trigger = "^([^|;%s]*)(.*)히아키스의 거미줄에 걸렸습니다%.$", -- check
	web_message = "%s님이 거미줄에 걸렸습니다!",
	web_bar = "거미줄: %s",
} end )

L:RegisterTranslations("zhCN", function() return {
	web = "希亚其斯之网",
	web_desc = "当队员受到希亚其斯之网时发出警告。",
	web_trigger = "^(.+)受(.+)了希亚其斯之网效果的影响。$",
	web_message = "希亚其斯之网：>%s<！",
	web_bar = "<希亚其斯之网: %s>",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Karazhan"]
mod.enabletrigger = boss
mod.toggleoptions = {"web", "bosskill"}
mod.revision = tonumber(("$Revision$"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "WebEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "WebEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "WebEvent")

	self:AddCombatListener("SPELL_AURA_APPLIED", "Web", 29896)
	self:AddCombatListener("UNIT_DIED", "GenericBossDeath")
	
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "GenericBossDeath")

	self:RegisterEvent("BigWigs_RecvSync")
	self:TriggerEvent("BigWigs_ThrottleSync", "HyakissWeb", 3)
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Web(player)
	if player then self:Sync("HyakissWeb", player) end
end

function mod:WebEvent(msg)
	local wplayer, wtype = select(3, msg:find(L["web_trigger"]))
	if wplayer and wtype then
		if wplayer == L2["you"] and wtype == L2["are"] then
			wplayer = UnitName("player")
		end
		self:Sync("HyakissWeb", wplayer)
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if sync == "HyakissWeb" and rest and self.db.profile.web then
		self:Message(L["web_message"]:format(rest), "Urgent")
		self:Bar(L["web_bar"]:format(rest), 8, "Spell_Nature_Web")
	end
end

