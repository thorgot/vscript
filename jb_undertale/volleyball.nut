
RANDOMIZER_AREA_MIN <- Vector(576.0, 3928.0, 236.0);
RANDOMIZER_AREA_MAX <- Vector(704.0, 4056.0, 364.0);
const PLAYER_WIDTH_HALF = 16.0;
SECTION_LOCATIONS <- array(4);
SECTION_ANGLES <- array(4);

DEBUG_PRINT<-false
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function OnPostSpawn() //Called after the logic_script spawns
{
	EntFireByHandle(self, "RunScriptCode", "Setup()", 0.5, null, null)
}

function Setup()
{
	for (local i = 1; i <= 4; i++) {
		local dest = Entities.FindByName(null,"4square_door_tp_dest" + i);
		SECTION_LOCATIONS[i-1] = dest.GetOrigin();
		SECTION_ANGLES[i-1] = dest.GetAngles();
	}
}

function RandomizePlayers()
{
	players <- [];
	local ply = null;
	while ((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		local playerOrigin = ply.GetOrigin()
		if (playerOrigin.x >= RANDOMIZER_AREA_MIN.x - PLAYER_WIDTH_HALF && playerOrigin.x <= RANDOMIZER_AREA_MAX.x + PLAYER_WIDTH_HALF &&
			playerOrigin.y >= RANDOMIZER_AREA_MIN.y - PLAYER_WIDTH_HALF && playerOrigin.y <= RANDOMIZER_AREA_MAX.y + PLAYER_WIDTH_HALF &&
			playerOrigin.z >= RANDOMIZER_AREA_MIN.z && playerOrigin.z < RANDOMIZER_AREA_MAX.z && ply.GetHealth() > 0)
		{
			players.push(ply);
		}
	}
	
	local NUM_TEAMS = 4;
	if (players.len() % 4 == 0)
	{
		NUM_TEAMS = 4;
	}
	else if (players.len() % 3 == 0)
	{
		NUM_TEAMS = 3;
	}
	else if (players.len() % 2 == 0)
	{
		NUM_TEAMS = 2;
	}
	//debugprint("NUM_TEAMS: " + NUM_TEAMS.tostring());
	local location = 0;
	while (players.len() > 0)
	{
		local playerIndex = RandomInt(0, players.len() - 1);
		local ply = players[playerIndex];
		players.remove(playerIndex);
		ply.SetOrigin(SECTION_LOCATIONS[location]);
		ply.SetAngles(SECTION_ANGLES[location].x, SECTION_ANGLES[location].y, SECTION_ANGLES[location].z);
		if (++location >= NUM_TEAMS)
		{
			location = 0;
		}
	}
}

RouletteStarter<-null;
function SetActivatorAsRouletteStarter()
{
	RouletteStarter = activator;
}

function KillRouletteStarter()
{
	if (RouletteStarter != null && RouletteStarter.GetHealth() > 0) {
		EntFireByHandle(RouletteStarter, "SetHealth", "0", 0.0, self, self);
	}
}