//===============================
//=====       HAS_WEAPON    =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

GUNS<-{};
GUNS["weapon_ak47"] <- true;
GUNS["weapon_aug"] <- true;
GUNS["weapon_awp"] <- true;
GUNS["weapon_bizon"] <- true;
//GUNS["weapon_c4"] <- true;
GUNS["weapon_cz75a"] <- true;
GUNS["weapon_deagle"] <- true;
//GUNS["weapon_decoy"] <- true;
GUNS["weapon_elite"] <- true;
GUNS["weapon_famas"] <- true;
GUNS["weapon_fiveseven"] <- true;
//GUNS["weapon_flashbang"] <- true;
GUNS["weapon_g3sg1"] <- true;
GUNS["weapon_galilar"] <- true;
GUNS["weapon_glock"] <- true;
//GUNS["weapon_healthshot"] <- true;
//GUNS["weapon_hegrenade"] <- true;
//GUNS["weapon_incgrenade"] <- true;
GUNS["weapon_hkp2000"] <- true;
//GUNS["weapon_knife"] <- true;
GUNS["weapon_m249"] <- true;
GUNS["weapon_m4a1"] <- true;
GUNS["weapon_m4a1_silencer"] <- true;
GUNS["weapon_mac10"] <- true;
GUNS["weapon_mag7"] <- true;
//GUNS["weapon_molotov"] <- true;
GUNS["weapon_mp7"] <- true;
GUNS["weapon_mp9"] <- true;
GUNS["weapon_negev"] <- true;
GUNS["weapon_nova"] <- true;
GUNS["weapon_p250"] <- true;
GUNS["weapon_p90"] <- true;
GUNS["weapon_sawedoff"] <- true;
GUNS["weapon_scar20"] <- true;
GUNS["weapon_sg556"] <- true;
GUNS["weapon_ssg08"] <- true;
//GUNS["weapon_smokegrenade"] <- true;
//GUNS["weapon_tagrenade"] <- true;
//GUNS["weapon_taser"] <- true;
GUNS["weapon_tec9"] <- true;
GUNS["weapon_ump45"] <- true;
GUNS["weapon_usp_silencer"] <- true;
GUNS["weapon_xm1014"] <- true;
GUNS["weapon_revolver"] <- true;

DEBUG_PRINT<-true
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

PlayersInArea <- {};
PlayersWithGuns <- {};
PlayersWithoutGuns <- {};
Enabled <- false;

function SetEnabled(enabled) {
	Enabled = enabled;
	debugprint("Enabled is now " + Enabled + " in SetEnabled");
	if (!enabled) {
		foreach (ply, val in PlayersWithoutGuns) {
			SetVisibleDelayed(ply);
		}
		PlayersInArea.clear();
		PlayersWithGuns.clear();
		PlayersWithoutGuns.clear();
	}
}

function EnterArea() {
	if (activator != null && activator.IsValid()) {
		debugprint("*************" + activator + " has entered area" + "*************")
		PlayersInArea[activator] <- "true";
		if (Enabled) {
			activator.__KeyValueFromInt("alpha",255);
			activator.__KeyValueFromInt("rendermode",1);
		}
	}
}
function ExitArea() {
	if (activator != null && activator.IsValid() && activator in PlayersInArea) {
		debugprint("*************" + activator + " has exited area" + "*************")
		activator.__KeyValueFromInt("rendermode",0);
		activator.__KeyValueFromInt("alpha",255);
		delete PlayersInArea[activator];
		if (activator in PlayersWithGuns) {
			delete PlayersWithGuns[activator];
		}
		if (activator in PlayersWithoutGuns) {
			delete PlayersWithoutGuns[activator];
		}
	}
}

// call function to set invis when start button is pressed, remove when end button is pressed

function CheckForPlayersWithWeapons()
{
	debugprint("Enabled is " + Enabled + " in CheckForPlayersWithWeapons");
	if (!Enabled) return;
	//Copy PlayersInArea
	NewPlayersWithoutGuns <- {};
	NewPlayersWithGuns <- {};
	debugprint("*************" + "CheckForPlayersWithWeapons" + "*************")
	foreach (ply, val in PlayersInArea) {
		NewPlayersWithoutGuns[ply] <- val;
	}

	weapon<-null;
	while((weapon = Entities.FindByClassname(weapon,"weapon_*")) != null) {
		//filter out non-gun weapons and weapons outside of game area
		local owner = weapon.GetOwner();
		//debugprint("*************" + "Testing weapon " + weapon.GetClassname() + ": " + !(weapon.GetClassname() in GUNS) + " / " + weapon.GetOwner() + "*************")
		if (!(weapon.GetClassname() in GUNS) || owner == null || !owner.IsValid() || !(owner in PlayersInArea)) continue;
		
		//debugprint("*************" + "Weapon " + weapon + " passed filters" + "*************")
		//filter out weapons whose owners are already named
		if (owner in NewPlayersWithoutGuns)
		{
			//debugprint("*************" + "Adding " + owner + " to NewPlayersWithGuns" + "*************")
			delete NewPlayersWithoutGuns[owner];
			NewPlayersWithGuns[owner] <- owner;
			continue;
		}
	}
	
	//Set newly armed players to visible
	foreach (ply, val in NewPlayersWithGuns)
	{
		if (!(ply in PlayersWithGuns))
		{
			SetVisibleDelayed(ply);
		}
	}
	PlayersWithGuns = NewPlayersWithGuns;
	
	//Set newly unarmed players to invisible
	foreach (ply, val in NewPlayersWithoutGuns)
	{
		if (!(ply in PlayersWithoutGuns))
		{
			SetInvisibleDelayed(ply);
		}
	}
	PlayersWithoutGuns = NewPlayersWithoutGuns;
}

function SetVisibleDelayed(ply) {
	if (ply != null && ply.IsValid())
	{
		debugprint("*************" + "Setting " + ply + " to visible in 0.5 seconds" + "*************")
		ply.__KeyValueFromInt("rendermode",0);
		EntFireByHandle(ply, "Alpha", "255", 0.25, null, ply);
	}
}

function SetInvisibleDelayed(ply) {
	if (ply != null && ply.IsValid())
	{
		debugprint("*************" + "Setting " + ply + " to invisible in 0.5 seconds" + "*************")
		ply.__KeyValueFromInt("rendermode",1);
		EntFireByHandle(ply, "Alpha", "25", 0.25, null, ply);
	}
}