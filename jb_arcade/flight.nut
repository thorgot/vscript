//===============================
//=====       FLIGHT SECRET =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

flierPlayer<-null;
item<-null;
originEntity<-null;
enabled<-false;
NextToggleAllowed<-0.0;
const TOGGLE_TIME = 6.0;
SECRET_SPEED <- "0.5";
const MAX_PLAYERS = 64;

GameTextEntities<-array(MAX_PLAYERS+1);

STRAFE_MIN <- Vector(1024.0, -1312.0, -16072.0);
STRAFE_MAX <- Vector(1536.0, -800.0, -511.0);
STRAFE_HARD_MIN <- Vector(1088.0, -6720.0, -16072.0);
STRAFE_HARD_MAX <- Vector(1600.0, -6208.0, 16000.0);
DODGE_MIN <- Vector(2176.0, -1824.0, -1024.0);
DODGE_MAX <- Vector(2688.0, 3744.0, -800.0);

DEBUG_PRINT<-true;
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function registerItem()
{
	NextToggleAllowed = Time();
	if (item == null)
	{
		item = Entities.FindByName(null, "secret_flight_c4");
		debugprint("Found item: " + item)
	}
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		GameTextEntities[i] = Entities.FindByName(null,"display_score_" + i);
	}
}

function toggleEnabled()
{
	if (!(flierPlayer == activator) || Time() < NextToggleAllowed) return;
	NextToggleAllowed = Time() + TOGGLE_TIME;
	if (IsWithinDisabledArea(flierPlayer)) return;
	enabled = !enabled;
	if (!enabled)
	{
		disable();
	}
	else
	{
		enable();
	}
}

function disable()
{
	modifySpeed("1.0");
	DoEntFire("secret_flight_gravity", "Disable", "", 0.0, flierPlayer, null);
	updateHUDText();
}

function enable()
{
	modifySpeed(SECRET_SPEED);
	DoEntFire("secret_flight_gravity", "Enable", "", 0.0, flierPlayer, null);
	updateHUDText();
}

function pickup()
{
	if (originEntity == null)
	{
		originEntity = Entities.FindByName(null, "secret_flight_origin");
	}
	if (activator != null)
	{
		flierPlayer = activator;
		enabled = true;
		updateHUDText();
	}
}

function updateHUDText()
{
	if (flierPlayer == null || item == null || item.GetOwner() == null) return;
	local toggleAvailabilityText = "(Ready!)";
	if (Time() < NextToggleAllowed) {
		toggleAvailabilityText = "(" + (NextToggleAllowed - Time() + 1.01).tointeger().tostring() + "s)"
	}

	if (!enabled) {
		DisplayText(flierPlayer, "Right click to toggle flight on " + toggleAvailabilityText);
	} else {
		DisplayText(flierPlayer, "Right click to toggle flight off " + toggleAvailabilityText);
	}
}

function flight()
{
	updateHUDText();
	if (flierPlayer != null && enabled)
	{
		if (item != null)
		{
			if (item.GetOwner() != flierPlayer)
			{
				debugprint("Disabling flight item");
				modifySpeed("1.0");
				flierPlayer = null;
				return;
			}
			if (IsWithinDisabledArea(flierPlayer))
			{
				debugprint("Disabling flight within restricted area");
				enabled = false;
				disable();
				return;
			}
		}
	
		//Get forward vector
		local forwardVector = originEntity.GetForwardVector();
		
		debugprint("forwardVector: " + forwardVector);
	
		local newVelocity=Scale(forwardVector, 600.0);
		newVelocity.z = newVelocity.z + 10.0;
		flierPlayer.SetVelocity(newVelocity);
		modifySpeed(SECRET_SPEED);
	}
}

//debug function
function modifySpeed(speed)
{
	if (flierPlayer != null)
	{
		DoEntFire("speedmod", "ModifySpeed", speed, 0.0, flierPlayer, null);
	}
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
	else if (playerOrigin.x >= DODGE_MIN.x && playerOrigin.x <= DODGE_MAX.x &&
		playerOrigin.y >= DODGE_MIN.y && playerOrigin.y <= DODGE_MAX.y &&
		playerOrigin.z >= DODGE_MIN.z && playerOrigin.z < DODGE_MAX.z)
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

function DisplayText(ply, text)
{
	if (GameTextEntities[ply.entindex()] != null)
	{
		GameTextEntities[ply.entindex()].__KeyValueFromString("message", text);
		EntFireByHandle(GameTextEntities[ply.entindex()],"Display","",0.1,ply,ply);
	}
}
