::SNOWBALL_GAME_BOUNDS<-[Vector(128, -3552, 88), Vector(1152, -3072, 346)]
::SnowballGameStarted <- false;
::CurrentSnowballGameNumber <- 0;
::SnowballTargetMaker <- null;
::SNOWBALL_TARGET_ORIENTATIONS <- [Vector(0, 90, 0), Vector(0, 0, 0), Vector(0, -90, 0)] //left, back, right
const SNOWBALL_TARGET_DIAMETER = 45;
::SNOWBALL_TARGET_BOUNDS_1 <- [Vector(129 + SNOWBALL_TARGET_DIAMETER, -3551, 90+SNOWBALL_TARGET_DIAMETER), Vector(1152 - SNOWBALL_TARGET_DIAMETER, -3551, 346 - SNOWBALL_TARGET_DIAMETER)];
::SNOWBALL_TARGET_BOUNDS_2 <- [Vector(129, -3551 + SNOWBALL_TARGET_DIAMETER, 90+SNOWBALL_TARGET_DIAMETER), Vector(129, -3073 - SNOWBALL_TARGET_DIAMETER, 346 - SNOWBALL_TARGET_DIAMETER)];
::SNOWBALL_TARGET_BOUNDS_3 <- [Vector(129 + SNOWBALL_TARGET_DIAMETER, -3073, 90+SNOWBALL_TARGET_DIAMETER), Vector(1152 - SNOWBALL_TARGET_DIAMETER, -3073, 346 - SNOWBALL_TARGET_DIAMETER)];
::SNOWBALL_TARGET_BOUNDS <- [SNOWBALL_TARGET_BOUNDS_1, SNOWBALL_TARGET_BOUNDS_2, SNOWBALL_TARGET_BOUNDS_3];

::DEBUG_PRINT<-false;
::debugprint<-function(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

::IsWithinBounds<-function(coords, minbound, maxbound)
{
	//debugprint("Result of IsWithinBounds(" + coords + ", " + minbound + ", " + maxbound + "):    " + (coords.x > minbound.x && coords.y > minbound.y && coords.z > minbound.z && coords.x < maxbound.x && coords.y < maxbound.y && coords.z < maxbound.z))
	return coords.x > minbound.x && coords.y > minbound.y && coords.z > minbound.z && coords.x < maxbound.x && coords.y < maxbound.y && coords.z < maxbound.z;
}

::SpawnRandomSnowballTargetDelayed<-function(){
	EntFire("snowball_script", "RunScriptCode", "SpawnRandomSnowballTarget(" + CurrentSnowballGameNumber.tostring() + ")", 0.5, null);
}

::SpawnRandomSnowballTarget<-function(gameNumber){
	if (!SnowballGameStarted || (gameNumber != CurrentSnowballGameNumber)) return;

	
	if (SnowballTargetMaker == null) {
		SnowballTargetMaker = Entities.FindByName(SnowballTargetMaker,"snowball_target_maker");
	}
	
	local wall = RandomInt(0, 2);
	local bounds = SNOWBALL_TARGET_BOUNDS[wall];
	local location = Vector(RandomFloat(bounds[0].x, bounds[1].x), RandomFloat(bounds[0].y, bounds[1].y), RandomFloat(bounds[0].z, bounds[1].z));
	//debugprint("Snowball target spawned at " + location);
	SnowballTargetMaker.SpawnEntityAtLocation(location, SNOWBALL_TARGET_ORIENTATIONS[wall]);
}

::startSnowballGame<-function(){
	if (SnowballGameStarted) return;
	SnowballGameStarted = true;
	CurrentSnowballGameNumber++;
	EntFire("snowball_start_button_texturetoggle", "SetTextureIndex", "1", 0.0, null);
	EntFire("snowball_stop_button_texturetoggle", "SetTextureIndex", "0", 0.0, null);
	local numTargets = (countPlayers() / 3) + 1;
	for (local i = 0; i < numTargets; i++) {
		SpawnRandomSnowballTargetDelayed();
	}
	EntFire("snowballs_timer", "Enable", "0", 0.0, null);
	
	local ply = null;
	while ((ply = Entities.FindByClassname(ply, "player")) != null) {
		if (!ply.ValidateScriptScope()) continue;
		
		ply.GetScriptScope().snowball_points <- 0;
	}
}

::stopSnowballGame<-function(){
	if (!SnowballGameStarted) return;
	SnowballGameStarted = false;
	EntFire("snowball_start_button_texturetoggle", "SetTextureIndex", "0", 0.0, null);
	EntFire("snowball_stop_button_texturetoggle", "SetTextureIndex", "1", 0.0, null);
	EntFire("snowballs_timer", "Disable", "0", 0.0, null);
	EntFire("snowball_target_model", "Kill", "0", 0.0, null);
}

::addSnowballPoint<-function(){
	if (activator == null) return;
	if (!activator.ValidateScriptScope()) return;
	local script_scope=activator.GetScriptScope()
	if (!("snowball_points" in script_scope)) script_scope.snowball_points <- 0;
	
	script_scope.snowball_points = script_scope.snowball_points + 1;
	
	if (script_scope.snowball_points == 5) activator.SetOrigin(Vector(1024, -3648, 92));
}

::resetSnowballPoints<-function(){
	if (activator == null) return;
	if (!activator.ValidateScriptScope()) return;
	local script_scope=activator.GetScriptScope()
	script_scope.snowball_points <- 0;
}

::countPlayers<-function(){
	local players = 0;
	local ply = null;
	//debugprint("Checking players against bounds " + SNOWBALL_GAME_BOUNDS[0] + " to " + SNOWBALL_GAME_BOUNDS[1]);
	while ((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		if (IsWithinBounds(ply.GetOrigin(), SNOWBALL_GAME_BOUNDS[0], SNOWBALL_GAME_BOUNDS[1])) {
			players++;
		}
	}
	//Bots
	ply = null;
	while ((ply = Entities.FindByClassname(ply, "cs_bot")) != null)
	{
		if (IsWithinBounds(ply.GetOrigin(), SNOWBALL_GAME_BOUNDS[0], SNOWBALL_GAME_BOUNDS[1])) {
			players++;
		}
	}
	//debugprint("Found " + players + " players in game");
	return players;
}

::debugGetTargetInfo<-function(){
	local target = null;
	while ((target = Entities.FindByName(target,"snowball_target_model")) != null) {
		//debugprint(target + " is at location " + target.GetOrigin());
	}
}