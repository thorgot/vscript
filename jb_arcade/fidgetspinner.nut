//===============================
//=====      FIDGET SPINNER =====
//=====      BY             =====
//=====      THORGOT        =====
//===============================

item <- null;
rotating <- null;
SpinnerSpeed <- 0.0;


const RUNNING_SPEED_SQUARED = 62500;
const SPEED_LEEWAY = 25000;
const MIN_SPEED_TO_SPIN = 37500 //RUNNING_SPEED_SQUARED - SPEED_LEEWAY;

const SPEED_INCREASE_PER_TICK = 0.1;
const SPEED_DECREASE_PER_TICK = -0.05;

const MAX_SPEED = 1.0;
const MIN_SPEED = 0.0;

DEBUG_PRINT<-true;
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function Setup() {
	item = Entities.FindByName(null, "fidgetspinner_item");
	rotating = Entities.FindByName(null, "fidgetspinner_model");
	EntFire("fidgetspinner_timer", "Enable", "", 1.0, null);
}

function AddToSpinnerSpeed(speed) {
	if (speed == SPEED_DECREASE_PER_TICK && SpinnerSpeed == MIN_SPEED) {
		return;
	}
	SpinnerSpeed += speed;
	
	if (SpinnerSpeed < MIN_SPEED) {
		SpinnerSpeed = MIN_SPEED;
	}
	
	if (SpinnerSpeed > MAX_SPEED) {
		SpinnerSpeed = MAX_SPEED;
	}
	
	EntFireByHandle(rotating,"SetSpeed",SpinnerSpeed.tostring(),0.0,rotating,rotating);
}

function UpdateSpeed() {
	if (item == null || !item.IsValid()) {
		EntFire("fidgetspinner_timer", "Disable", "0.0", 0.0, null);
		return;
	}
	
	if (item.GetOwner() == null) {
		AddToSpinnerSpeed(SPEED_DECREASE_PER_TICK);
		return;
	}
	
	
	local playerSpeed = item.GetOwner().GetVelocity().Length2DSqr();
	if (playerSpeed < MIN_SPEED_TO_SPIN) {
		AddToSpinnerSpeed(SPEED_DECREASE_PER_TICK);
		return;
	}
	
	AddToSpinnerSpeed(SPEED_INCREASE_PER_TICK);
	
}