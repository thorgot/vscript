//===============================
//=====       BY            =====
//=====       THORGOT       =====
//===============================


ITEM_AREA <- Vector(4728.0, 2392.0, -264.0);
MAX_DISTANCE <- 32.0;
ITEM <- "weapon_deagle";

function CheckForItem() {
	local foundItem = Entities.FindByClassnameWithin(null, ITEM, ITEM_AREA, MAX_DISTANCE);
	if (foundItem != null) {
		EntFire("secret_concussion_trigger", "Disable", "", 0.0, null);
		EntFire("secret_concussion_template", "ForceSpawn", "", 0.0, null);
		EntFire("logic_eventlistener_decoy_started", "RunScriptCode", "registerItem()", 0.10, null);
	}
}