//===============================
//=====       GRAB          =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

grabbedPlayer <- null;
secretPlayer <- null;
originEntity<-null;
item<-null;
hudtext<-null;

const GRAB_DISTANCE = 96.0;
const GRAB_VELOCITY = 10.0;

const BUTTON_LEFT = 0;
const BUTTON_RIGHT = 1;
buttons_pressed<-array(2, false);

DEBUG_PRINT<-false;
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}


function OnPostSpawn() //Called after the logic_script spawns
{
	//DoIncludeScript("custom/Util.nut",null); //Include the utility functions/classes from Util.nut in this script
}

function Setup() {
	item = Entities.FindByName(null, "secret_grab_item");
	originEntity = Entities.FindByName(null, "secret_grab_origin");
	hudtext = Entities.FindByName(null, "secret_grab_text");
}

function pickup()
{
	if (activator != null) {
		if (activator != secretPlayer) {
			disable(secretPlayer);
		}
		secretPlayer = activator;
		//NextTimeAllowed = Time() + 0.5;
		EntFireByHandle(hudtext,"Display","",0.01,secretPlayer,secretPlayer);
		buttons_pressed[0] = false;
		buttons_pressed[1] = false;
	}
}

function resetName(ply) {
	if (ply != null && ply.IsValid() && ply.GetName() == "secret_grabber") {
		ply.__KeyValueFromString("targetname","default");
	}
}

function disable(ply) {
	freeGrabbedPlayer()
	resetName(ply);
	secretPlayer = null;
}

function Think() {
	if (secretPlayer == null || item == null) return;
	
	if (!item.IsValid()) {
		item = null;
		disable(secretPlayer);
		return;
	}

	if (item.GetOwner() != secretPlayer || secretPlayer.GetHealth() < 1) {
		disable(secretPlayer);
		return;
	}
	
	if (grabbedPlayer == null) {
		return;
	} else if (!(grabbedPlayer.IsValid())) {
		grabbedPlayer = null;
		return;
	} else if (grabbedPlayer.GetHealth() < 1) {
		EntFireByHandle(grabbedPlayer,"AddOutput","gravity 1",0.0,self,self);
		grabbedPlayer = null;
		return;
	}
	
	//Get forward vector
	local forwardVector = originEntity.GetForwardVector();
	local grabLocation = secretPlayer.EyePosition() + Scale(forwardVector, 64);
	grabLocation.z -= 32.0;
	
	local playerOrigin = grabbedPlayer.GetOrigin();
	local vel = grabLocation - playerOrigin;
	//Release if grabbedPlayer is far away now
	if (vel.Length() > 512.0) {
		freeGrabbedPlayer();
		return;
	}
	vel.x *= 10.0;
	vel.y *= 10.0;
	vel.z *= 10.0;
	grabbedPlayer.SetVelocity(vel);
}

function grabActivator() {
	grabPlayer(activator);
}

function grabPlayer(ply) {
	freeGrabbedPlayer();
	grabbedPlayer = ply;
	EntFireByHandle(grabbedPlayer,"AddOutput","gravity .01",0.0,self,self);
}

function grab() {
	Deactivate();
	
	if (secretPlayer == null || secretPlayer != activator || item == null || item.GetOwner() != secretPlayer) {
		return;
	}
	if (grabbedPlayer != null) {
		freeGrabbedPlayer();
		//debugprint("Freed grabbed player");
		return;
	}
	
	local forwardVector = originEntity.GetForwardVector();
	local grabLocation = secretPlayer.EyePosition() + Scale(forwardVector, 64);
	local closestLivingPlayer = null;
	local closestDistance = 9999;
	local ply = null;
	while ((ply = Entities.FindByClassnameWithin(ply, "player", grabLocation, GRAB_DISTANCE)) != null) {
		if (ply.GetHealth() > 0 && ply != secretPlayer) {
			local distance = (grabLocation - ply.GetOrigin()).Length();
			//debugprint("Found candidate " + ply + " at distance " + distance);
			if (distance < closestDistance && distance < GRAB_DISTANCE) {
				closestDistance = distance;
				closestLivingPlayer = ply;
			}
		}
	}
	if (closestLivingPlayer != null) {
		//debugprint("Found player to grab: " + closestLivingPlayer + " (" + closestDistance + " distance from grab location)");
		grabPlayer(closestLivingPlayer);
	}
}

function freeGrabbedPlayer() {
	if (grabbedPlayer != null && grabbedPlayer.IsValid()) {
		EntFireByHandle(grabbedPlayer,"AddOutput","gravity 1",0.0,self,self);
		grabbedPlayer = null;
	}
}


//Scales a vector
Scale<-function(v, scalar)
{
	local len = v.Length();
	if (len == 0) {
		return v;
	}
	return Vector(v.x*scalar/len,v.y*scalar/len,v.z*scalar/len);
}

function PressButton(button, value) {
	Deactivate();
	buttons_pressed[button] = value;
	if (buttons_pressed[0] && buttons_pressed[1]) {
		grab();
	}
}

function Deactivate() {
	if ((item == null || !item.IsValid() || item.GetOwner() == null) && activator != null) {
		DoEntFire("secret_grab_ui", "Deactivate", "", 0.0, activator, activator);
		return;
	}
}