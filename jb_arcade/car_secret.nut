//===============================
//=====       BY            =====
//=====       THORGOT       =====
//===============================


secretPlayer<-null;
item<-null;
speedmod<-null;
timer<-null;

ITEM_LOCATION <- Vector(-63.231995, -275.157990, -698.593018);
const SPEED_BONUS = 1.4;

DEBUG_PRINT<-false;
::debugprint<-function(text) {
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}


function Setup() {
	item = Entities.FindByName(null, "secret_car_item");
	speedmod = Entities.FindByName(null, "secret_car_speed");
	timer = Entities.FindByName(null, "secret_car_timer");
}

//ent_fire secret_car_script runscriptcode "SetItemLocation()"
function SetItemLocation() {
	Setup();
	if (item != null) {
		item.SetOrigin(ITEM_LOCATION);
		EntFire("secret_car_model", "Alpha", "255", 0.0, null);
	}
}

function SetSpeed(ply, speed) {
	if (ply == null || !ply.IsValid() || ply.GetHealth() <= 0) return;
	EntFireByHandle(speedmod, "ModifySpeed", speed.tostring(), 0.0, ply, null);
}

function pickup() {
	if (activator != null) {
		if (activator != secretPlayer) {
			//New owner, disable speed on old owner
			SetSpeed(secretPlayer, 1.0);
		}
		secretPlayer = activator;
		SetSpeed(secretPlayer, SPEED_BONUS);
		EntFireByHandle(timer, "Enable", "", 0.0, null, null);
	}
}

function update()
{
	if (secretPlayer == null) {
		EntFireByHandle(timer, "Disable", "", 0.0, null, null);
		return;
	}
	
	//Item deleted or has no owner
	if (item == null || !item.IsValid() || item.GetOwner() == null) {
		EntFireByHandle(timer, "Disable", "", 0.0, null, null);
		SetSpeed(secretPlayer, 1.0);
		secretPlayer = null;
	}
}
