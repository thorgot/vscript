
const NO_CELL = -1;
const STRAFE_CLIMB = 0;
const CLIMB = 1;
const ICE_CLIMB = 2;
const WATER_RACE = 3;
const SURF = 4;
const NOJUMP = 5;
const LASERS = 6;
const BHOP = 7;
const LONGJUMP = 8;
const NUM_CELLS = 9;

CELL_INSTRUCTION_STRINGS<-[
	"Climb and strafe to reach the goal.",
	"Climb to reach the goal.",
	"Climb the ice to reach the goal.",
	"Swim and avoid the walls to reach the green wall at the end.",
	"Ski, surf and drop to reach the goal.",
	"Crouch over the gaps to reach the goal.\nJumping is disabled.",
	"Avoid the lasers to reach the goal.",
	"Bunny hop on the platforms to reach the goal.",
	"Jump and strafe in midair over the gaps to reach the goal.",
];

STRAFE_AREA_MIN <- Vector(452.0, -2112.0, 0.0);
STRAFE_AREA_MAX <- Vector(960.0, -572.0, 0.0);
CLIMB_AREA_MIN <- Vector(-60.0, -2112.0, 0.0);
CLIMB_AREA_MAX <- Vector(444.0, -572.0, 0.0);
ICE_CLIMB_AREA_MIN <- Vector(-576.0, -2112.0, 0.0);
ICE_CLIMB_AREA_MAX <- Vector(-68.0, -572.0, 0.0);
WATER_RACE_AREA_MIN <- Vector(-960.0, -576.0, 0.0);
WATER_RACE_AREA_MAX <- Vector(-572.0, -224.0, 0.0);
SURF_AREA_MIN <- Vector(-960.0, -216.0, 0.0);
SURF_AREA_MAX <- Vector(-572.0, 152.0, 0.0);
NOJUMP_AREA_MIN <- Vector(-960.0, 160.0, 0.0);
NOJUMP_AREA_MAX <- Vector(-572.0, 512.0, 0.0);
LASERS_AREA_MIN <- Vector(-576.0, 508.0, 0.0);
LASERS_AREA_MAX <- Vector(-68.0, 2048.0, 0.0);
BHOP_AREA_MIN <- Vector(-60.0, 508.0, 0.0);
BHOP_AREA_MAX <- Vector(444.0, 2048.0, 0.0);
LONGJUMP_AREA_MIN <- Vector(452.0, 508.0, 0.0);
LONGJUMP_AREA_MAX <- Vector(960.0, 2048.0, 0.0);

AREA_MIN<-[STRAFE_AREA_MIN, CLIMB_AREA_MIN, ICE_CLIMB_AREA_MIN, WATER_RACE_AREA_MIN, SURF_AREA_MIN, NOJUMP_AREA_MIN, LASERS_AREA_MIN, BHOP_AREA_MIN, LONGJUMP_AREA_MIN];
AREA_MAX<-[STRAFE_AREA_MAX, CLIMB_AREA_MAX, ICE_CLIMB_AREA_MAX, WATER_RACE_AREA_MAX, SURF_AREA_MAX, NOJUMP_AREA_MAX, LASERS_AREA_MAX, BHOP_AREA_MAX, LONGJUMP_AREA_MAX];

const MAX_PLAYERS = 64;
GameTextEntities<-array(MAX_PLAYERS+1);

EnabledForPlayer<-array(MAX_PLAYERS+1);
Disabled<-false;

DEBUG_PRINT<-true
function debugprint(text) {
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}


function OnPostSpawn() { //Called after the logic_script spawns
	EntFireByHandle(self, "RunScriptCode", "Setup()", 0.5, null, null)
}

function Setup() {
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		GameTextEntities[i] = Entities.FindByName(null,"display_score_" + i);
		EnabledForPlayer[i] = true;
	}
}

function DisableForActivator() {
	EnabledForPlayer[activator.entindex()] = false;
}

function DisableForAll() {
	Disabled = true;
}

function GetPlayerCell(ply) {
	if (ply.GetHealth() <= 0) return NO_CELL;
	
	local playerOrigin = ply.GetOrigin();
	for (local i = 0; i < NUM_CELLS; i++) {
		//debugprint("playerOrigin: " + playerOrigin.tostring());
		//debugprint("AREA_MIN[i]: " + AREA_MIN[i].tostring());
		if (playerOrigin.x >= AREA_MIN[i].x && playerOrigin.x <= AREA_MAX[i].x && playerOrigin.y >= AREA_MIN[i].y && playerOrigin.y <= AREA_MAX[i].y) {
			//debugprint("Returning cell " + i.tostring() + " for player " + ply.entindex().tostring());
			return i;
		}
	}
	return NO_CELL;
}

function DisplayHelpText() {
	if (Disabled) return;
	local ply = null;
	while ((ply = Entities.FindByClassname(ply, "player")) != null) {
		if (EnabledForPlayer[ply.entindex()]) {
			local cell = GetPlayerCell(ply);
			if (cell != NO_CELL) {
				DisplayText(ply, CELL_INSTRUCTION_STRINGS[cell]);
			}
		}
	}
}

function DisplayText(ply, text) {
	local game_txt = GameTextEntities[ply.entindex()];
	if (game_txt != null) {
		game_txt.__KeyValueFromString("message", text);
		EntFireByHandle(game_txt,"Display","",0.02,ply,ply);
	}
}