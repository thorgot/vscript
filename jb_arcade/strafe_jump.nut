
Damage<-0;
MAX_DAMAGE<-20;
MIN_DAMAGE<-0;
DamageSignTT<-null;

MAX_WINNERS<-32;
MIN_WINNERS<-3;
WinnersSettings<-4;
Winners<-0;
WinnersSettingTT<-null;

DAMAGE_TO_TEXTURE <- {[0] = 0, [5] = 1, [10] = 2, [15] = 3, [20] = 4, [25] = 5, [50] = 6, [75] = 7, [100] = 8};

STRAFE_MIN <- Vector(1024.0, -1312.0, -16072.0);
STRAFE_MAX <- Vector(1536.0, -800.0, -511.0);
STRAFE_HARD_MIN <- Vector(1088.0, -6720.0, -16072.0);
STRAFE_HARD_MAX <- Vector(1600.0, -6208.0, 16000.0);

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
	DamageSignTT = Entities.FindByName(null, "sj_damage_sign_tt");
	
	Damage = 0;
	EntFireByHandle(DamageSignTT, "SetTextureIndex", DAMAGE_TO_TEXTURE[Damage].tostring(), 0.0, null, self);
}

function UpdateTeleports()
{
	local teleportDesinationEntities = [EntityGroup[0], EntityGroup[1], EntityGroup[2]];
	local winnersDestination = EntityGroup[3];
	local losersDestination = EntityGroup[4];
	local teleportDestination = losersDestination;
	local easyWinTeleport = EntityGroup[5];
	local hardWinTeleport = EntityGroup[6];

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
	EntFireByHandle(easyWinTeleport, "SetRemoteDestination", teleportDestination.GetName(), 0.0, this, this);
	EntFireByHandle(hardWinTeleport, "SetRemoteDestination", teleportDestination.GetName(), 0.0, this, this);
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
		WinnersSettingTT = Entities.FindByName(null, "sj_winners_sign_tt");
	}
	
	EntFireByHandle(WinnersSettingTT, "SetTextureIndex", WinnersSettings.tostring(), 0.0, null, self);
	
	if (Winners > 0)
	{
		UpdateTeleports();
	}
}

function AddToDamage(toAdd)
{
	Damage += toAdd;
	if (Damage > MAX_DAMAGE) Damage = MAX_DAMAGE;
	if (Damage < MIN_DAMAGE) Damage = MIN_DAMAGE;

	EntFireByHandle(DamageSignTT, "SetTextureIndex", DAMAGE_TO_TEXTURE[Damage].tostring(), 0.0, null, self);
	EntFire("sj_easy_damage", "SetDamage", (Damage*2).tostring(), 0.0);
	EntFire("sj_medium_damage", "SetDamage", (Damage*2).tostring(), 0.0);
	EntFire("sj_hard_damage", "SetDamage", (Damage*2).tostring(), 0.0);
	EntFire("sj_fail_damage", "SetDamage", (Damage*2).tostring(), 0.0);
}

function StopActivatorZ()
{
	StopPlayerZ(activator);
}

function StopPlayerZ(ply)
{
	if (ply != null) {
		local oldVel = ply.GetVelocity();
		ply.SetVelocity(Vector(oldVel.x, oldVel.y, 0));
	}
}

function IsWithinGame(ply) {
	local playerOrigin = ply.GetOrigin()
	if (playerOrigin.x >= STRAFE_MIN.x && playerOrigin.x <= STRAFE_MAX.x &&
		playerOrigin.y >= STRAFE_MIN.y && playerOrigin.y <= STRAFE_MAX.y &&
		playerOrigin.z >= STRAFE_MIN.z && playerOrigin.z < STRAFE_MAX.z)
	{
		return true;
	}
	else if (playerOrigin.x >= STRAFE_HARD_MIN.x && playerOrigin.x <= STRAFE_HARD_MAX.x &&
		playerOrigin.y >= STRAFE_HARD_MIN.y && playerOrigin.y <= STRAFE_HARD_MAX.y &&
		playerOrigin.z >= STRAFE_HARD_MIN.z && playerOrigin.z < STRAFE_HARD_MAX.z)
	{
		return true;
	}
	else
	{
		return false;
	}
}

function Recall()
{
	local zeroVector = Vector(0, 0, 0);
	local ply = null;
	while((ply = Entities.FindByClassname(ply, "player")) != null) {
		if (ply.IsValid() && ply.GetHealth() > 0 && IsWithinGame(ply)) {
			ply.SetOrigin(EntityGroup[12].GetOrigin());
			ply.SetVelocity(zeroVector);
		}
	}
}