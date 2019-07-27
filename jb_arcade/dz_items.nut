//===============================
//=====       DZ ITEMS      =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

function OnPostSpawn() //Called after the logic_script spawns
{
	EntFireByHandle(self, "RunScriptCode", "Setup()", 0.1, null, null);
}

function Setup()
{
	self.PrecacheModel("models/props_survival/dronegun/dronegun.mdl");
	//EntFire("dronegun_spawner", "Spawn", "", 0.5, null); //Added to logic_auto instead
	self.PrecacheModel("models/props_survival/upgrades/exojump.mdl");
	
	self.PrecacheModel("models/props_survival/upgrades/parachutepack.mdl");
	self.PrecacheModel("models/props_survival/upgrades/upgrade_dz_helmet.mdl");
	self.PrecacheModel("models/weapons/v_parachute.mdl");
	EntFire("dzitems_spawner", "ForceSpawn", "", 0.5, null);
}

//ent_fire dronegun RunScriptCode "self.SetOwner(Entities.FindByName(null, @"default"))"

//None of the stuff below here works
/*
prop_weapon_upgrade_exojump <- null;
function GiveActivatorExojump() {
	prop_weapon_upgrade_exojump = Entities.CreateByClassname("prop_weapon_upgrade_exojump");
	EntFireByHandle(self, "RunScriptCode", "SetPositionDelayed()", 0.5, activator, null);
}
*/

/*
function SetPositionDelayed() {
	//prop_weapon_upgrade_exojump.__KeyValueFromString("physicsmode","1");
	//prop_weapon_upgrade_exojump.__KeyValueFromString("physdamagescale","0.1");
	//prop_weapon_upgrade_exojump.__KeyValueFromString("max_health","1");
	//prop_weapon_upgrade_exojump.__KeyValueFromString("CollisionGroup","1");
	//prop_weapon_upgrade_exojump.__KeyValueFromString("addon","ai_addon_thrownprojectile");
	local location = activator.GetOrigin();
	location.z += 64;
	prop_weapon_upgrade_exojump.SetOrigin(location);
	prop_weapon_upgrade_exojump.SetModel("models/props_survival/upgrades/exojump.mdl");
}
*/

/*
function SetOwnerActivator() {
	SetOwner(activator);
}

function SetOwner(owner) {
	local drone = Entities.FindByClassname(null, "dronegun");
	
	if (drone == null) {
		return;
	}
	drone.SetOwner(owner)
	drone.__KeyValueFromString("TeamNum","2");
	drone.__KeyValueFromString("teamnumber","2");
	
}
*/