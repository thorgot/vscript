//===============================
//=====       TARGET GAME   =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

DEBUG_PRINT<-false
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

GAME_MIN <- Vector(5512.0, -1144.0, -192.0);
GAME_MAX <- Vector(7422.0, 800.0, 368.0); 
TARGET_GAME_BOUNDS <- [GAME_MIN, Vector(GAME_MAX.x, GAME_MAX.y, -16.0)]
GameStarted <- false;
WeaponSelection <- 1;
const NUM_WEAPONS = 14;

const TEAM_T = 2;
const TEAM_CT = 3;
CurrentGameNumber <- 0;
TargetMaker <- null;
TARGET_ORIENTATIONS <- [Vector(0, 90, 0), Vector(0, 0, 0), Vector(0, -90, 0), Vector(0, -180, 0)] //left, back, right, front
const TARGET_DIAMETER = 45;
TARGET_BOUNDS_1 <- [Vector(TARGET_GAME_BOUNDS[0].x + TARGET_DIAMETER + 1, TARGET_GAME_BOUNDS[0].y + 1, TARGET_GAME_BOUNDS[0].z+TARGET_DIAMETER), Vector(TARGET_GAME_BOUNDS[1].x - TARGET_DIAMETER, TARGET_GAME_BOUNDS[0].y + 1, TARGET_GAME_BOUNDS[1].z - TARGET_DIAMETER)];
TARGET_BOUNDS_2 <- [Vector(TARGET_GAME_BOUNDS[0].x + 1, TARGET_GAME_BOUNDS[0].y + 1 + TARGET_DIAMETER, TARGET_GAME_BOUNDS[0].z+TARGET_DIAMETER), Vector(TARGET_GAME_BOUNDS[0].x + 1, TARGET_GAME_BOUNDS[1].y-1 - TARGET_DIAMETER, TARGET_GAME_BOUNDS[1].z - TARGET_DIAMETER)];
TARGET_BOUNDS_3 <- [Vector(TARGET_GAME_BOUNDS[0].x + TARGET_DIAMETER + 1, TARGET_GAME_BOUNDS[1].y - 1, TARGET_GAME_BOUNDS[0].z+TARGET_DIAMETER), Vector(TARGET_GAME_BOUNDS[1].x - TARGET_DIAMETER, TARGET_GAME_BOUNDS[1].y - 1, TARGET_GAME_BOUNDS[1].z - TARGET_DIAMETER)];
TARGET_BOUNDS_4 <- [Vector(TARGET_GAME_BOUNDS[1].x + 1, TARGET_GAME_BOUNDS[0].y + TARGET_DIAMETER - 1, TARGET_GAME_BOUNDS[0].z+TARGET_DIAMETER), Vector(TARGET_GAME_BOUNDS[1].x + 1, TARGET_GAME_BOUNDS[1].y -TARGET_DIAMETER - 1, TARGET_GAME_BOUNDS[1].z - TARGET_DIAMETER)];
TARGET_BOUNDS <- [TARGET_BOUNDS_1, TARGET_BOUNDS_2, TARGET_BOUNDS_3, TARGET_BOUNDS_4];
const POINTS_REQUIRED = 10;

function OnPostSpawn() //Called after the logic_script spawns
{
	EntFireByHandle(self, "RunScriptCode", "Setup()", 0.1, null, null);
}

function Setup()
{
	EntFire("shield_gun_model*", "Disable", "", 0.0, null);
	EntFire("shield_gun_model1", "Enable", "", 0.05, null);
	TARGET_BOUNDS[1][1].y = 558; // Prevent targets from spawning in portal
}

function IsWithinBounds(coords, minbound, maxbound)
{
	//debugprint("Result of IsWithinBounds(" + coords + ", " + minbound + ", " + maxbound + "):    " + (coords.x > minbound.x && coords.y > minbound.y && coords.z > minbound.z && coords.x < maxbound.x && coords.y < maxbound.y && coords.z < maxbound.z))
	return coords.x > minbound.x && coords.y > minbound.y && coords.z > minbound.z && coords.x < maxbound.x && coords.y < maxbound.y && coords.z < maxbound.z;
}

function StartGame()
{
	EntFire("shield_equip_trigger", "Enable", "", 0.0, null);
	GameStarted = true;
	
	CurrentGameNumber++;
	local numTargets = (countPlayers() / 2) + 1;
	for (local i = 0; i < numTargets; i++) {
		SpawnRandomTargetDelayed();
	}
	
	local ply = null;
	while ((ply = Entities.FindByClassname(ply, "player")) != null) {
		if (!ply.ValidateScriptScope()) continue;
		
		ply.GetScriptScope().target_points <- 0;
	}
}

function StopGame()
{
	GameStarted = false;
	
	EntFire("shield_equip_trigger", "Disable", "", 0.0, null);
	EntFire("shield_strip_trigger", "Enable", "", 0.05, null);
	
	//Turn off shield stripper
	EntFire("shield_strip_trigger", "Disable", "", 0.30, null);
	
	EntFire("target_model", "Kill", "0", 0.0, null);
}

function GetGamePlayers() {
	gameplayers <- {};
	gameplayer <- null;
	while((gameplayer = Entities.FindByClassname(gameplayer,"player")) != null) {
		local playerOrigin = gameplayer.GetOrigin();
		if (playerOrigin.x >= GAME_MIN.x && playerOrigin.x <= GAME_MAX.x &&
		    playerOrigin.y >= GAME_MIN.y && playerOrigin.y <= GAME_MAX.y &&
			gameplayer.GetHealth() > 0)
		{
			gameplayers[gameplayer.entindex()] <- gameplayer;
		}
	}
	return gameplayers;
}

function AddWeaponSelection(amt) {
	if(GameStarted) return;
	EntFire("shield_gun_model"+WeaponSelection, "Disable", "", 0.0, null);
	WeaponSelection += amt;
	if (WeaponSelection > NUM_WEAPONS) WeaponSelection = 1;
	if (WeaponSelection < 1) WeaponSelection = NUM_WEAPONS;
	EntFire("shield_gun_model"+WeaponSelection, "Enable", "", 0.0, null);
}

function EquipGun() {
	EntFire("shield_gun_equip" + WeaponSelection, "Use", "", 0.0, activator);
}

function SpawnRandomTargetDelayed(){
	EntFireByHandle(self, "RunScriptCode", "SpawnRandomTarget(" + CurrentGameNumber.tostring() + ")", 0.5, null, null);
}

function SpawnRandomTarget(gameNumber){
	if (!GameStarted || (gameNumber != CurrentGameNumber)) return;

	
	if (TargetMaker == null) {
		TargetMaker = Entities.FindByName(TargetMaker,"target_maker");
	}
	
	local wall = RandomInt(0, 3);
	local bounds = TARGET_BOUNDS[wall];
	local location = Vector(RandomFloat(bounds[0].x, bounds[1].x), RandomFloat(bounds[0].y, bounds[1].y), RandomFloat(bounds[0].z, bounds[1].z));
	//debugprint("target spawned at " + location + " on wall " + wall);
	TargetMaker.SpawnEntityAtLocation(location, TARGET_ORIENTATIONS[wall]);
}

function addTargetPoint(){
	if (activator == null) return;
	if (!activator.ValidateScriptScope()) return;
	local script_scope=activator.GetScriptScope()
	if (!("target_points" in script_scope)) script_scope.target_points <- 0;
	
	script_scope.target_points = script_scope.target_points + 1;
	
	if (script_scope.target_points == POINTS_REQUIRED) {
		activator.SetOrigin(Vector(5144, -1120, -111));
		activator.SetVelocity(Vector(0,0,0));
		EntFire("shield_stripper", "Use", "", 0.0, activator);
	}
}

function resetTargetPoints(){
	if (activator == null) return;
	if (!activator.ValidateScriptScope()) return;
	local script_scope=activator.GetScriptScope()
	script_scope.target_points <- 0;
}

function countPlayers(){
	local players = 0;
	local ply = null;
	//debugprint("Checking players against bounds " + TARGET_GAME_BOUNDS[0] + " to " + TARGET_GAME_BOUNDS[1]);
	while ((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		if (IsWithinBounds(ply.GetOrigin(), TARGET_GAME_BOUNDS[0], TARGET_GAME_BOUNDS[1])) {
			players++;
		}
	}
	//Bots
	ply = null;
	while ((ply = Entities.FindByClassname(ply, "cs_bot")) != null)
	{
		if (IsWithinBounds(ply.GetOrigin(), TARGET_GAME_BOUNDS[0], TARGET_GAME_BOUNDS[1])) {
			players++;
		}
	}
	//debugprint("Found " + players + " players in game");
	return players;
}