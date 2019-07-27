const DAMAGE_NAME_PREFIX = "d_f_";

const WEAPON_NUCLEAR = "weapon_nuclear";
const WEAPON_POISON = "weapon_poison";
const WEAPON_LIGHTNING = "weapon_lightning";
const WEAPON_WRECKINGBALL = "weapon_wreckingball";
const TEAM_TERRORIST = 2;
const TEAM_CT = 3;

const HURTER_ONE = "1";
const HURTER_TWO = "2";
const HURTER_THREE = "3";
const HURTER_FOUR = "4";
const HURTER_FIVE = "5";
const HURTER_SIX = "6";

hurters <- {};
attackers <- {};
instaKill <- {};

function debugprint(text)
{
	if (GetDeveloperLevel() == 0) return;
	printl("*************" + text + "*************")
}

function OnPostSpawn() {
	EntFireByHandle(self, "RunScriptCode", "Setup()", 0.0, self, self);
}

function Setup() {
	if (!(HURTER_ONE in hurters)) {
		local hurter = Entities.CreateByClassname("point_hurt");
		hurter.__KeyValueFromString("damagetype", "16");
		hurter.__KeyValueFromString("damage", "500");
		hurter.__KeyValueFromString("damagetarget", DAMAGE_NAME_PREFIX + HURTER_ONE);
		EntFireByHandle(hurter, "AddOutput", "classname " + WEAPON_NUCLEAR, 0.0, self, self);
		hurters[HURTER_ONE] <- hurter;
		instaKill[HURTER_ONE] <- true;
		
	}
	if (!(HURTER_TWO in hurters)) {
		local hurter = Entities.CreateByClassname("point_hurt");
		hurter.__KeyValueFromString("damagetype", "16");
		hurter.__KeyValueFromString("damage", "9");
		hurter.__KeyValueFromString("damagetarget", DAMAGE_NAME_PREFIX + HURTER_TWO);
		EntFireByHandle(hurter, "AddOutput", "classname " + WEAPON_NUCLEAR, 0.0, self, self);
		hurters[HURTER_TWO] <- hurter;
		instaKill[HURTER_TWO] <- false;
	}
	if (!(HURTER_THREE in hurters)) {
		local hurter = Entities.CreateByClassname("point_hurt");
		hurter.__KeyValueFromString("damagetype", "16");
		hurter.__KeyValueFromString("damage", "3");
		hurter.__KeyValueFromString("damagetarget", DAMAGE_NAME_PREFIX + HURTER_THREE);
		EntFireByHandle(hurter, "AddOutput", "classname " + WEAPON_POISON, 0.0, self, self);
		hurters[HURTER_THREE] <- hurter;
		instaKill[HURTER_THREE] <- false;
	}
	if (!(HURTER_FOUR in hurters)) {
		local hurter = Entities.CreateByClassname("point_hurt");
		hurter.__KeyValueFromString("damagetype", "16");
		hurter.__KeyValueFromString("damage", "20");
		hurter.__KeyValueFromString("damagetarget", DAMAGE_NAME_PREFIX + HURTER_FOUR);
		EntFireByHandle(hurter, "AddOutput", "classname " + WEAPON_LIGHTNING, 0.0, self, self);
		hurters[HURTER_FOUR] <- hurter;
		instaKill[HURTER_FOUR] <- false;
	}
	if (!(HURTER_FIVE in hurters)) {
		local hurter = Entities.CreateByClassname("point_hurt");
		hurter.__KeyValueFromString("damagetype", "16");
		hurter.__KeyValueFromString("damage", "10");
		hurter.__KeyValueFromString("damagetarget", DAMAGE_NAME_PREFIX + HURTER_FIVE);
		EntFireByHandle(hurter, "AddOutput", "classname " + WEAPON_LIGHTNING, 0.0, self, self);
		hurters[HURTER_FIVE] <- hurter;
		instaKill[HURTER_FIVE] <- false;
	}
	if (!(HURTER_SIX in hurters)) {
		local hurter = Entities.CreateByClassname("point_hurt");
		hurter.__KeyValueFromString("damagetype", "16");
		hurter.__KeyValueFromString("damage", "500");
		hurter.__KeyValueFromString("damagetarget", DAMAGE_NAME_PREFIX + HURTER_SIX);
		EntFireByHandle(hurter, "AddOutput", "classname " + WEAPON_WRECKINGBALL, 0.0, self, self);
		hurters[HURTER_SIX] <- hurter;
		instaKill[HURTER_SIX] <- true;
	}
}

function hurtDebug() {
	if (hurter == null) {
		local playerOrigin = activator.GetOrigin();
		hurter = Entities.CreateByClassname("point_hurt");
		hurter.SetOrigin(playerOrigin);
		local weaponname = activator.GetName();
		//EntFireByHandle(hurter, "AddOutput", "targetname weapon_thinking", 0.0, self, self);
		//EntFireByHandle(hurter, "AddOutput", "globalname weapon_thinking", 0.0, self, self);
		EntFireByHandle(hurter, "AddOutput", "classname " + weaponname, 0.0, self, self);
		EntFireByHandle(hurter, "AddOutput", "damagetype 2", 0.0, self, self);
		EntFireByHandle(hurter, "AddOutput", "damage 100", 0.0, self, self);
		EntFireByHandle(hurter, "AddOutput", "damagetarget targetdead", 0.0, self, self);
	}
	EntFireByHandle(hurter, "hurt", "", 0.1, activator, activator);
	
}

function getLivingTs() {
	local livingTs = 0;
	local ply = null;
	while((ply = Entities.FindByClassname(ply, "player")) != null) {
		//debugprint("Found player " + ply);
		if (ply.IsValid() && ply.GetHealth() > 0 && ply.GetTeam() == TEAM_TERRORIST) {
			livingTs++;
		}
	}
	return livingTs;
	
}

function getOtherPlayer(ply, ignoreLivingTs) {
	if (ply == null || !ply.IsValid()) return null;
	local playerTeam = ply.GetTeam();
	local otherplys = [];
	local otherply = null;
	while((otherply = Entities.FindByClassname(otherply, "player")) != null) {
		if (otherply == ply) continue;
		local otherTeam = otherply.GetTeam();
		if (otherTeam == playerTeam) continue;
		if (ignoreLivingTs && otherTeam == TEAM_TERRORIST && otherply.GetHealth() > 0) continue;
		if (otherTeam != TEAM_CT && otherTeam != TEAM_TERRORIST) continue;
		
		otherplys.push(otherply);
	}
	
	if (otherplys.len() == 0) return null;
	
	local otherplysIndex = RandomInt(0, otherplys.len()-1);
	//debugprint("Returning otherplys[" + otherplysIndex + "] which is " + otherplys[otherplysIndex]);
	return otherplys[otherplysIndex];
	
}

function hurtActivator(hurterKey) {
	hurtPlayer(hurterKey, activator);
}

function setAttacker(hurterKey) {
	if (activator == null) return;
	attackers[hurterKey] <- activator;
}

function hurtPlayer(hurterKey, target) {
	target.__KeyValueFromString("targetname", DAMAGE_NAME_PREFIX + hurterKey);
	local attacker = null;
	local livingTs = getLivingTs();
	if (livingTs == 3 || livingTs == 2 || livingTs == 1) {
		//If there are 3, 2 or 1 Ts alive, we could be in LR, so just default to self damage.
		attacker = target;
	} else if (hurterKey in attackers) {
		attacker = attackers[hurterKey];
	} else {
		attacker = getOtherPlayer(target, true)
	}
	EntFireByHandle(hurters[hurterKey], "hurt", "", 0.0, attacker, self);
	EntFireByHandle(target, "AddOutput", "targetname default", 0.01, target, self);
	if (instaKill[hurterKey]) {
		//The bug was that the trigger was being disabled, so this is unnecessary
		//EntFireByHandle(self, "RunScriptCode", "ensureDeathActivator("+hurterKey+")", 0.5 + RandomFloat(0.0, 1.0), target, self);
	}
}

function ensureDeathActivator(hurterKeyInt) {
	if (activator != null && activator.IsValid() && activator.GetHealth() > 0) {
		hurtPlayer(hurterKeyInt.tostring(), activator);
	}
}