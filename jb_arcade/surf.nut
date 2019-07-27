
Damage<-0;
MAX_DAMAGE<-20;
MIN_DAMAGE<-0;
DamageSignTT<-null;
DAMAGE_TO_TEXTURE <- {[0] = 0, [5] = 1, [10] = 2, [15] = 3, [20] = 4, [25] = 5, [50] = 6, [75] = 7, [100] = 8};

MAX_WINNERS<-32;
MIN_WINNERS<-3;
WinnersSettings<-4;
Winners<-0;
WinnersSettingTT<-null;

DEBUG_PRINT<-true
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function OnPostSpawn() //Called after the logic_script spawns
{
	EntFireByHandle(self, "RunScriptCode", "Setup()", 0.5, null, null);
}

function Setup()
{
	DamageSignTT = Entities.FindByName(null, "surf_damage_sign_tt");
	
	Damage = 0;
	EntFireByHandle(DamageSignTT, "SetTextureIndex", DAMAGE_TO_TEXTURE[Damage].tostring(), 0.0, null, self);
}


function AddToDamage(toAdd)
{
	Damage += toAdd;
	if (Damage > MAX_DAMAGE) Damage = MAX_DAMAGE;
	if (Damage < MIN_DAMAGE) Damage = MIN_DAMAGE;

	EntFireByHandle(DamageSignTT, "SetTextureIndex", DAMAGE_TO_TEXTURE[Damage].tostring(), 0.0, null, self);
	if (Damage == 0) {
		EntFire("surf_damage", "Disable", "", 0.0);
	} else {
		EntFire("surf_damage", "Enable", "", 0.0);
	}
	EntFire("surf_damage", "SetDamage", (Damage*2).tostring(), 0.0);
}

function StopActivator()
{
	StopPlayer(activator);
}

function StopPlayer(ply)
{
	if (ply != null) {
		ply.SetVelocity(Vector(0, 0, 0));
	}
}


function UpdateTeleports()
{
	local teleportDesinationEntities = [EntityGroup[0], EntityGroup[1], EntityGroup[2]];
	local winnersDestination = EntityGroup[3];
	local losersDestination = EntityGroup[4];
	local teleportDestination = losersDestination;
	local winTeleport = EntityGroup[5];

	if (Winners < 3)
	{
		debugprint("Setting teleportDestination to podium " + (Winners+1));
		teleportDestination = teleportDesinationEntities[Winners];
	}
	else if (Winners < WinnersSettings)
	{
		debugprint("Setting teleportDestination to winners podium");
		teleportDestination = winnersDestination;
	}
	else
	{
		debugprint("Setting teleportDestination to losers podium");
	}
	debugprint("podium name: " + teleportDestination.GetName());
	EntFireByHandle(winTeleport, "SetRemoteDestination", teleportDestination.GetName(), 0.0, this, this);
}

function AddToWinners()
{
	Winners++;
	UpdateTeleports();
}

function ResetWinners()
{
	Winners = 0;
	UpdateTeleports();
}

function AddToWinnersSetting(toAdd)
{
	WinnersSettings += toAdd;
	if (WinnersSettings > MAX_WINNERS) WinnersSettings = MAX_WINNERS;
	if (WinnersSettings < MIN_WINNERS) WinnersSettings = MIN_WINNERS;

	if (WinnersSettingTT == null)
	{
		WinnersSettingTT = Entities.FindByName(null, "surf_winners_sign_tt");
	}
	
	EntFireByHandle(WinnersSettingTT, "SetTextureIndex", WinnersSettings.tostring(), 0.0, null, self);
	
	if (Winners > 0)
	{
		UpdateTeleports();
	}
}