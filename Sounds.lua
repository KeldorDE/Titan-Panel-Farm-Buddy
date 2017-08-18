-- **************************************************************************
-- * TitanFarmBuddy.lua
-- *
-- * By: Keldor
-- **************************************************************************

local NOTIFICATION_SOUNDS = {
	AlarmClockWarning2 = 'AlarmClockWarning2',
	AlarmClockWarning3 = 'AlarmClockWarning3',
	FriendJoinGame = 'FriendJoinGame',
	Glyph_MinorCreate = 'Glyph_MinorCreate',
	LEVELUPSOUND = 'LEVELUPSOUND',
	LFG_DungeonReady = 'LFG_DungeonReady',
	LFG_Rewards = 'LFG_Rewards',
	LFG_RoleCheck = 'LFG_RoleCheck',
	PVPENTERQUEUE = 'PVPENTERQUEUE',
	PVPFlagCapturedMono = 'PVPFlagCapturedMono',
	PVPFlagTakenHordeMono = 'PVPFlagTakenHordeMono',
	PVPTHROUGHQUEUE = 'PVPTHROUGHQUEUE',
	PVPVictoryAllianceMono = 'PVPVictoryAllianceMono',
	PVPVictoryHordeMono = 'PVPVictoryHordeMono',
	PVPWarningAllianceMono = 'PVPWarningAllianceMono',
	PVPWarningHordeMono = 'PVPWarningHordeMono',
	QUESTADDED = 'QUESTADDED',
	QUESTCOMPLETED = 'QUESTCOMPLETED',
	RaidBossEmoteWarning = 'RaidBossEmoteWarning',
	RaidWarning = 'RaidWarning',
	ReadyCheck = 'ReadyCheck',
	UI_Challenges_MedalExpires = 'UI_Challenges_MedalExpires',
	UI_FightClub_Victory = 'UI_FightClub_Victory',
	UI_GARRISON_START_WORK_ORDER = 'UI_GARRISON_START_WORK_ORDER',
	UI_Garrison_Toast_BuildingComplete = 'UI_Garrison_Toast_BuildingComplete',
	UI_Garrison_Toast_FollowerGained = 'UI_Garrison_Toast_FollowerGained',
	UI_Garrison_Toast_InvasionAlert = 'UI_Garrison_Toast_InvasionAlert',
	UI_Garrison_Toast_MissionComplete = 'UI_Garrison_Toast_MissionComplete',
	UI_GuildLevelUp = 'UI_GuildLevelUp',
	UI_MISSION_SUCCESS_CHEERS = 'UI_MISSION_SUCCESS_CHEERS',
	UI_ORDERHALL_TALENT_READY_CHECK = 'UI_ORDERHALL_TALENT_READY_CHECK',
	UI_ORDERHALL_TALENT_READY_TOAST = 'UI_ORDERHALL_TALENT_READY_TOAST',
	UI_ORDERHALL_TALENT_SELECT = 'UI_ORDERHALL_TALENT_SELECT',
	UI_PVPCaptureMineCartAlliance = 'UI_PVPCaptureMineCartAlliance',
	UI_PVPCaptureMineCartHorde = 'UI_PVPCaptureMineCartHorde',
	UI_PetBattle_PVE_Victory = 'UI_PetBattle_PVE_Victory',
	UI_PetBattle_Start = 'UI_PetBattle_Start',
	UI_QuestObjectivesComplete = 'UI_QuestObjectivesComplete',
	UI_RAID_BOSS_DEFEATED = 'UI_RAID_BOSS_DEFEATED',
	UI_RaidBossWhisperWarning = 'UI_RaidBossWhisperWarning',
	UI_Scenario_Ending = 'UI_Scenario_Ending',
	UI_Scenario_Stage_Begin = 'UI_Scenario_Stage_Begin',
	UI_Scenario_Stage_End = 'UI_Scenario_Stage_End',
	UI_WORLDQUEST_COMPLETE = 'UI_WORLDQUEST_COMPLETE',
	UI_WORLDQUEST_START = 'UI_WORLDQUEST_START',
}



-- **************************************************************************
-- NAME : TitanFarmBuddy_GetSounds()
-- DESC : Get a list of available sounds.
-- **************************************************************************
function TitanFarmBuddy_GetSounds()
	return NOTIFICATION_SOUNDS
end
