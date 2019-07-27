const ODDS_DOUBLE_TELEPORT_TO_ARMORY = 0.0625; // 1/16
const ODDS_SINGLE_TELEPORT_TO_ARMORY = 0.25; // 1/4
const ODDS_DOUBLE_TELEPORT_TO_MAP = 0.0625; // 1/16
const ODDS_SINGLE_TELEPORT_TO_MAP = 0.6875 // 11/16
const ODDS_DOUBLE_GUN = 0.0625; // 1/16
const ODDS_SINGLE_GUN = 0.626; // 10/16

TeleportsToArmoryRemaining <- 0;
TeleportsToMapRemaining <- 0;
GunsRemaining <- 0;
ArmorRemaining <- 0;
GunTemplates <- [];
GunTemplateToGunName <- { cell_vent_glock_template = "cell_vent_glock", cell_vent_p250_template = "cell_vent_p250", cell_vent_hkp_template = "cell_vent_hkp"};
GunNameToWinner <- {};
WinningPlayers <- {};
EntIndexToPlayer <- {};
TeleportedDecoys <- {};

DEBUG_PRINT<-true
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}


/*
ent_fire cell_rewards_script RunScriptCode "RemovePlayersFromWinningPlayers()"
*/
function RemovePlayersFromWinningPlayers() {
	WinningPlayers <- {};
}

function Setup() {
	if (RandomFloat(0.0, 1.0) < ODDS_DOUBLE_TELEPORT_TO_ARMORY) {
		TeleportsToArmoryRemaining = 2;
	} else if (RandomFloat(0.0, 1.0) < ODDS_SINGLE_TELEPORT_TO_ARMORY) {
		TeleportsToArmoryRemaining = 1;
	} else {
		TeleportsToArmoryRemaining = 0;
	}
	
	if (RandomFloat(0.0, 1.0) < ODDS_DOUBLE_TELEPORT_TO_MAP) {
		TeleportsToMapRemaining = 2;
	} else if (RandomFloat(0.0, 1.0) < ODDS_SINGLE_TELEPORT_TO_MAP) {
		TeleportsToMapRemaining = 1;
	} else {
		TeleportsToMapRemaining = 0;
	}
	
	if (RandomFloat(0.0, 1.0) < ODDS_DOUBLE_GUN) {
		GunsRemaining = 2;
	} else if (RandomFloat(0.0, 1.0) < ODDS_SINGLE_GUN) {
		GunsRemaining = 1;
	}
	
	ArmorRemaining = 3;
	GunTemplates = ["cell_vent_glock_template", "cell_vent_p250_template", "cell_vent_hkp_template"];

	UpdateTeleportsAndTriggers();
	
	debugprint("After setup, there are " + TeleportsToArmoryRemaining + " tps to armory, " + TeleportsToMapRemaining + " tps to map, and " + GunsRemaining + " guns");
}

function UpdateTeleportsAndTriggers() {
	if (TeleportsToArmoryRemaining > 0) {
		//Do nothing
	} else if (TeleportsToMapRemaining > 0) {
		EntFire("cell_vent_tp", "SetRemoteDestination", "cell_vent_tpdest", 0.0, null);
	} else {
		EntFire("cell_vent_tp", "Disable", "", 0.0, null);
		//Small delay to prevent teleporter from getting gun
		EntFire("cell_vent_trigger", "Enable", "", 0.1, null);
	}
}

function DisableRewards() {
	TeleportsToArmoryRemaining = 0;
	TeleportsToMapRemaining = 0;
	GunsRemaining = 0;
	EntFire("cell_vent_trigger", "Disable", "", 0.0, null);
	EntFire("cell_vent_tp", "Disable", "", 0.0, null);
	
}

function UseTeleport() {
	WinningPlayers[activator] <- true;
	if (TeleportsToArmoryRemaining > 0) {
		TeleportsToArmoryRemaining--;
	} else if (TeleportsToMapRemaining > 0) {
		TeleportsToMapRemaining--;
	}
	UpdateTeleportsAndTriggers();
}

function ReceiveGun() {
	if (activator == null || activator in WinningPlayers) return;
	WinningPlayers[activator] <- true;
	if (GunsRemaining == 0 || GunTemplates.len() == 0) {
		ReceiveDecoy();
		if (ArmorRemaining > 0) {
			ReceiveArmor();
			ArmorRemaining--;
		}
		return;
	}
	
	local template_index = RandomInt(0, GunTemplates.len() - 1);
	local template = GunTemplates[template_index]
	debugprint("Picked " + template + " (" + template_index + ")" + " which has gun name " + GunTemplateToGunName[template]);
	GunTemplates.remove(template_index);
	
	EntFire(template, "ForceSpawn", "", 0.0, null);
	
	local script_code = "TeleportGun(\"" + GunTemplateToGunName[template] + "\")";
	EntFireByHandle(self, "RunScriptCode", script_code, 0.05, null, self);
	GunNameToWinner[GunTemplateToGunName[template]] <- activator;
	GunsRemaining--;
}

function TeleportGun(gunName) {
	local winner = GunNameToWinner[gunName];
	debugprint("In TeleportGun, gunName = " + gunName + " and winner = " + winner);
	local weapon = Entities.FindByName(null,gunName);
	debugprint("In TeleportGun, weapon = " + weapon);
	if (winner == null || !winner.IsValid() || weapon == null) return;
	
	weapon.SetOrigin(winner.GetOrigin());
}

function ReceiveDecoy() {
	EntIndexToPlayer[activator.entindex()] <- activator;
	EntFire("cell_vent_decoy_template", "ForceSpawn", "", 0.0, null);
	EntFireByHandle(self, "RunScriptCode", "TeleportDecoy(" + activator.entindex() + ")", 0.05, null, self);
}

function ReceiveArmor() {
	DoEntFire("cell_vent_armor", "Use", "", 0.0, activator, activator);
}

function TeleportDecoy(playerIndex) {
	if (!playerIndex in EntIndexToPlayer || !EntIndexToPlayer[playerIndex].IsValid()) return;
	local weapon = null;
	
	//This should only target reward decoys which have never been picked up
	while ((weapon = Entities.FindByName(weapon, "cell_vent_decoy*")) != null) {
		if (!(weapon.entindex() in TeleportedDecoys) && weapon.GetClassname() == "weapon_decoy") {
			break;
		}
		debugprint("Skipping weapon " + weapon.entindex());
	}
	if (weapon == null) return;
	TeleportedDecoys[weapon.entindex()] <- true;
	weapon.SetOrigin(EntIndexToPlayer[playerIndex].GetOrigin());
}
