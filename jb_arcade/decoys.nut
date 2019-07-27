
teleportItem<-null;
specialPlayerTeleport<-null
teleportationTarget <- null;
old_teleportation_position <- null;
new_teleportation_position <- null;

concussionItem<-null;
specialPlayerConcussion <- null;
concussionTarget <- null;

DEBUG_PRINT <- true;

debugprint<-function(text)
{
	if (DEBUG_PRINT) printl("*************" + text + "*************")
}

function PickUpTeleportItem() {
	teleportItem = caller;
	specialPlayerTeleport = activator;
	EntFire("secret_decoy_timer", "Enable", "", 0.0, self);
	
	
	if (teleportationTarget == null)
	{
		teleportationTarget = Entities.FindByName(null, "secret_teleportation_target");
		debugprint("Found teleportationTarget: " + teleportationTarget)
	}
}

function PickUpConcussionItem() {
	concussionItem = caller;
	specialPlayerConcussion = activator;
	EntFire("secret_decoy_timer", "Enable", "", 0.0, self);
	
	
	if (concussionTarget == null)
	{
		concussionTarget = Entities.FindByName(null, "secret_concussion_target");
		debugprint("Found concussionTarget: " + concussionTarget)
	}
}


function CheckForNewDecoys() {
	if (teleportItem != null && (!teleportItem.IsValid() || teleportItem.GetOwner() != specialPlayerTeleport)) {
		specialPlayerTeleport = null;
	}
	if (concussionItem != null && (!concussionItem.IsValid() || concussionItem.GetOwner() != specialPlayerConcussion)) {
		specialPlayerConcussion = null;
	}
	
	if (specialPlayerTeleport == null && specialPlayerConcussion == null) {
		EntFire("secret_decoy_timer", "Disable", "", 0.0, self);
		return;
	}
	
	decoy <- null;
	while((decoy = Entities.FindByClassname(decoy, "decoy_projectile")) != null) {
		debugprint("decoy " + decoy + " has owner " + decoy.GetOwner());
		if(specialPlayerTeleport != null && decoy.GetOwner() == specialPlayerTeleport) {
			local velocity = decoy.GetVelocity();
			if (velocity.x == 0 && velocity.y == 0 && velocity.z == 0) {
				TeleportGrenade(decoy);
			}
		}
		if(specialPlayerConcussion != null && decoy.GetOwner() == specialPlayerConcussion) {
			local velocity = decoy.GetVelocity();
			if (velocity.x == 0 && velocity.y == 0 && velocity.z == 0) {
				ConcussionGrenade(decoy);
			}
		}
	}
}

function TeleportGrenade(decoy) {
	if (teleportItem == null || !decoy.IsValid()) return;
	local thrower = decoy.GetOwner();
	if (thrower == null || teleportItem.GetOwner() != thrower) return;
	
	old_teleportation_position = thrower.GetOrigin();
	local decoyPosition = decoy.GetOrigin();
	new_teleportation_position = Vector(decoyPosition.x, decoyPosition.y, decoyPosition.z + 0.5);
	
	//Play sounds and sparks at start and ending positions
	teleportationTarget.SetOrigin(old_teleportation_position);
	DoEntFire("secret_teleportation_sound", "PlaySound", "10", 0.1, thrower, thrower)
	DoEntFire("secret_teleportation_sound2", "PlaySound", "10", 0.1, thrower, thrower)
	local startSpark = Entities.FindByName(null, "secret_teleportation_spark1");
	local endSpark = Entities.FindByName(null, "secret_teleportation_spark2");
	startSpark.SetOrigin(Vector(old_teleportation_position.x, old_teleportation_position.y, old_teleportation_position.z + 5));
	EntFireByHandle(startSpark,"SparkOnce","",0.1,thrower,thrower);
	endSpark.SetOrigin(new_teleportation_position);
	EntFireByHandle(endSpark,"SparkOnce","",0.1,thrower,thrower);
	
	debugprint("killing decoy: " + decoy);
	EntFireByHandle(decoy,"Kill","",0.01,decoy,decoy);
	thrower.SetOrigin(new_teleportation_position);
	//Remove z velocity so if they are midjump they don't get teleported back
	local vel=thrower.GetVelocity();
	vel.z=0;
	thrower.SetVelocity(vel);
	debugprint("Old position: " + old_teleportation_position);
	debugprint("New position: " + new_teleportation_position);
	//Check if the player has fallen to the ground 0.2 seconds later
	EntFireByHandle(self,"RunScriptCode","CheckIfMoved()",0.2,thrower,thrower);
}

function CheckIfMoved()
{
	if (activator == null || activator.GetHealth() <= 0 || new_teleportation_position == null || old_teleportation_position == null)
	{
		return;
	}
	
	debugprint("player origin: " + activator.GetOrigin());
	debugprint("new_teleportation_position: " + new_teleportation_position);
	if (new_teleportation_position.z - activator.GetOrigin().z < 1.5 )
	{
		debugprint("Player has not moved so must be stuck. moving back to " + old_teleportation_position);
		activator.SetOrigin(old_teleportation_position);
	}
}

function ConcussionGrenade(decoy) {
	if (concussionItem == null || !decoy.IsValid()) return;
	local thrower = decoy.GetOwner();
	if (thrower == null || concussionItem.GetOwner() != thrower) return;
	local playerTeam = thrower.GetTeam();
	local decoyPosition = decoy.GetOrigin();
	
	//Play sound at grenade position
	concussionTarget.SetOrigin(Vector(decoyPosition.x, decoyPosition.y, decoyPosition.z + 0.5));
	DoEntFire("secret_concussion_sound", "PlaySound", "10", 0.05, thrower, thrower)

	//Kill decoy
	debugprint("killing decoy: " + decoy);
	EntFireByHandle(decoy,"Kill","",0.01,decoy,decoy);

	//Push players
	local grenadePosition = Vector(decoyPosition.x,decoyPosition.y,decoyPosition.z);
	local grenadePositionUp = Vector(decoyPosition.x,decoyPosition.y,decoyPosition.z - 24.0);
	local ply = null;
	while ((ply = Entities.FindByClassnameWithin(ply, "player", Vector(decoyPosition.x, decoyPosition.y, decoyPosition.z), 512.0)) != null)
	{
		if (ply.GetTeam() == playerTeam && ply != thrower) continue;
		debugprint("found nearby player " + ply);
		local posdif=ply.GetOrigin() - grenadePositionUp;
		local speedboost=Scale(posdif, 600.0);
		//debugprint(speedboost);
		if (speedboost.z < 300.0) speedboost.z = 300.0;
		//debugprint(speedboost);
		ply.SetVelocity(ply.GetVelocity()+speedboost);
	}

}