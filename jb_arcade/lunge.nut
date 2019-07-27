//===============================
//=====       LUNGE SECRET  =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

secretPlayer<-null;
item<-null;
originEntity<-null;
hudtext<-null;
NextTimeAllowed<-0.0;

const LUNGE_STRENGTH = 900.0;
const COOLDOWN = 3.0;
const COLOR_READY = "0 206 0";
const COLOR_NOTREADY = "0 123 145";
STRAFE_MIN <- Vector(1024.0, -1312.0, -16072.0);
STRAFE_MAX <- Vector(1536.0, -800.0, -511.0);
STRAFE_HARD_MIN <- Vector(1088.0, -6720.0, -16072.0);
STRAFE_HARD_MAX <- Vector(1600.0, -6208.0, 16000.0);

DEBUG_PRINT<-false;
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}


function Setup()
{
	item = Entities.FindByName(null, "secret_lunge_item");
	originEntity = Entities.FindByName(null, "secret_lunge_origin");
	hudtext = Entities.FindByName(null, "secret_lunge_text");
}

function resetName(ply)
{
	if (ply != null && ply.GetName() == "secret_lunger")
	{
		ply.__KeyValueFromString("targetname","default");
	}

}

function disable(ply, disableTimer)
{
	debugprint("Disabling lunge item for " + ply);
	resetName(ply);
	secretPlayer = null;
	if (disableTimer)
	{
		EntFire("secret_lunge_timer", "Disable", "0.0", 0.0, null);
	}
}

function pickup()
{
	if (activator != null)
	{
		if (activator != secretPlayer)
		{
			disable(secretPlayer, false);
		}
		secretPlayer = activator;
		NextTimeAllowed = Time() + 0.5;
	}
}

function lunge()
{
	if (Time() < NextTimeAllowed || secretPlayer == null || item == null) return;

	if (item.GetOwner() != secretPlayer)
	{
		disable(secretPlayer, true);
		return;
	}
	if (IsWithinDisabledArea(secretPlayer))
	{
		debugprint("Disallowing lunge flight within restricted area");
		return;
	}

	NextTimeAllowed = Time() + COOLDOWN;
	//Get forward vector
	local forwardVector = originEntity.GetForwardVector();
	
	debugprint("forwardVector: " + forwardVector);

	local newVelocity=Scale(forwardVector, LUNGE_STRENGTH);
	newVelocity.z = newVelocity.z + 10.0;
	secretPlayer.SetVelocity(newVelocity);
}

function updateHUD()
{
	if (item == null || secretPlayer == null || secretPlayer.GetHealth() < 0 || item.GetOwner() != secretPlayer) {
		debugprint("Disabling secret_lunge_timer because item no longer exists or is no longer held");
		disable(secretPlayer, true);
		return;
	}
	local text = "Lunge ready!";
	local color = COLOR_READY;
	if (Time() < NextTimeAllowed) {
		text = ((NextTimeAllowed - Time() + 1.01).tointeger().tostring() + "s until lunge ready.");
		color = COLOR_NOTREADY;
	}
	hudtext.__KeyValueFromString("message", text);
	hudtext.__KeyValueFromString("color", color);
	EntFireByHandle(hudtext,"Display","",0.01,secretPlayer,secretPlayer);
}

//Scales a vector
::Scale<-function(v, scalar)
{
	local len = v.Length();
	if (len == 0)
	{
		return v;
	}
	return Vector(v.x*scalar/len,v.y*scalar/len,v.z*scalar/len);
}

function IsWithinDisabledArea(ply) {
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
	else if (("inGame" in ply.GetScriptScope()) && ply.GetScriptScope().inGame == true)
	{
		return true;
	}
	else
	{
		return false;
	}
}