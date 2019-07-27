//===============================
//=====       LIGHTDUEL     =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

//Continue game with just one player
DEVELOPER<-true;

enum directions {
	up,
	down,
	left,
	right,
	none
}

enum spriteTypes {
	player,
	rocket,
	explosion
}

//Sprite Data
MOVEMENT_DISTANCE<-16.0;
DRAWTIME<-0.2;
DrawColor<-array(4);
DrawColor[0]=[255,192,192];
DrawColor[1]=[192,255,192];
DrawColor[2]=[192,192,255];
DrawColor[3]=[255,255,255];
DrawHeadColor<-array(4);
DrawHeadColor[0]=[255,1,1];
DrawHeadColor[1]=[1,255,1];
DrawHeadColor[2]=[1,1,255];
DrawHeadColor[3]=[200,200,200];
DrawCount<-0;
DrawSize<-8.0;
SpriteToSpriteMaker<-{};
SpriteToSpriteMaker[spriteTypes.player]<-"cycle_entity_maker";
SpriteToSpriteMaker[spriteTypes.rocket]<-"cycle_entity_maker_rocket";
SpriteToSpriteMaker[spriteTypes.explosion]<-"cycle_entity_maker_explosion";
SpriteToSpriteName<-{};
SpriteToSpriteName[spriteTypes.player]<-"cycle_sprite";
SpriteToSpriteName[spriteTypes.rocket]<-"cycle_sprite_rocket";
SpriteToSpriteName[spriteTypes.explosion]<-"cycle_sprite_explosion";
DirectionToAngles<-{};
DirectionToAngles[directions.up]<-Vector(270,0,0)
DirectionToAngles[directions.down]<-Vector(90,0,0)
DirectionToAngles[directions.left]<-Vector(180,0,0)
DirectionToAngles[directions.right]<-Vector(0,0,0)
DirectionToAngles[directions.none]<-Vector(0,0,0)

//Movement and Game State
LastSprite<-0.0;
LastPosition<-array(4,null);
LastDirection<-array(4, null);
NextDirection<-array(4, null);
IsAlive<-array(4, false);
IsPlayerActive<-array(4, false);
GameActive<-false;
GameStarted<-false;
GameEnded<-false;
OtherGameStarted<-false;
RocketPosition<-array(4,null);
RocketDirection<-array(4,null);
RocketSize <- DrawSize * 3.0;
PlayerSprites<-array(4,null);
CountDown<-0;
NextCountdown<-0.0;
TurnOffGameAt<-null;
BOOTH_AREA_MIN <- Vector(1340.0, -1965.0, -511.0);
BOOTH_AREA_MAX <- Vector(1658.0, -1927.0, -446.0);

//Prevent using up too many entities
MAXDRAWLIMIT<-512; //Board is 20x20, so this will never exceed 400.
LastLimitCheck<-0.0;
LIMITCHECKTIME<-5.0;

//Board Data
MIN_ENGINE_COORD<-Vector(1339.0,-2351.0,-500.0); //map coords
MAX_ENGINE_COORD<-Vector(1659.0,-2348.9,-180.0); //map coords
//MIN_ENGINE_COORD<-Vector(936.0,4088.0,248.0); //prototype coords
//MAX_ENGINE_COORD<-Vector(1256.0,4090.1,568.0); //prototype coords
START_POSITIONS<-[Vector(MIN_ENGINE_COORD.x+280.0,MIN_ENGINE_COORD.y+2.1,MIN_ENGINE_COORD.z+280.0), Vector(MIN_ENGINE_COORD.x+280.0,MIN_ENGINE_COORD.y+2.1,MIN_ENGINE_COORD.z+40.0), Vector(MIN_ENGINE_COORD.x+40.0,MIN_ENGINE_COORD.y+2.1,MIN_ENGINE_COORD.z+280.0), Vector(MIN_ENGINE_COORD.x+40.0,MIN_ENGINE_COORD.y+2.1,MIN_ENGINE_COORD.z+40.0)]
//START_POSITIONS<-[Vector(1216.0,4090.1,528.0), Vector(1216.0,4090.1,288.0), Vector(976.0,4090.1,528.0), Vector(976.0,4090.1,288.0)]
START_DIRECTIONS<-[directions.right, directions.right, directions.left, directions.left]

//Prebuilt levels
PrebuiltLevels<-array(4);
PrebuiltLevels[0]=[];
PrebuiltLevels[1]=[Vector(10,0,10),Vector(10,0,11),Vector(11,0,10),Vector(11,0,11),Vector(7,0,7),Vector(6,0,7),Vector(7,0,6),Vector(7,0,14),Vector(7,0,15),Vector(6,0,14),Vector(14,0,7),Vector(15,0,7),Vector(14,0,6),Vector(14,0,14),Vector(14,0,15),Vector(15,0,14)];
PrebuiltLevels[2]=[Vector(9,0,9),Vector(9,0,12),Vector(12,0,9),Vector(12,0,12),Vector(1,0,2),Vector(2,0,1),Vector(1,0,19),Vector(2,0,20),Vector(19,0,1),Vector(20,0,2),Vector(19,0,20),Vector(20,0,19)];
PrebuiltLevels[3]=[Vector(4,0,10),Vector(4,0,11),Vector(10,0,4),Vector(11,0,4),Vector(17,0,10),Vector(17,0,11),Vector(10,0,17),Vector(11,0,17)];


//Entity Caches
teleportEntities<-array(4);
GameTextEntities<-array(MAX_PLAYERS+1);

DEBUG_PRINT<-true;
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function OnPostSpawn() //Called after the logic_script spawns
{
	DoIncludeScript("custom/Util.nut",null); //Include the utility functions/classes from Util.nut in this script
	EntFireByHandle(self, "RunScriptCode", "Setup()", 0.5, null, null)
}

function Setup()
{
	for (local i = 0; i < 4; i++)
	{
		teleportEntities[i] = EntityGroup[i];
	}
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		GameTextEntities[i] = Entities.FindByName(null,"display_score_" + i);
	}
}

function Think()
{
	if (GameActive && CountDown && Time() >= NextCountdown)
	{
		if (CountDown == 1)
		{
			DoEntFire("cycle_start_sound", "PlaySound", "4", 0.0, null, null);
		}
		else
		{
			DoEntFire("cycle_warmup_sound", "PlaySound", "4", 0.0, null, null);
		}
		CountDown--;
		NextCountdown = Time() + 1.0;
	}
	//Only draw sprites at most 5 times per second
	if (GameActive && Time() >= LastSprite + DRAWTIME)
	{
		GameStarted = true
		//debugprint("Drawing sprites.")
		LastSprite = Time()
		UpdateRockets()
		SpawnSprites()
		
		//End the game if there are 0 or 1 players remaining
		if (GetLivingPlayers() <= 0)
		{
			//StopGame()
			GameActive = false;
			GameStarted = false;
			GameEnded = true;
			TurnOffGameAt = Time() + 5.0;
		}
	}
	if (TurnOffGameAt != null && Time() >= TurnOffGameAt)
	{
		StopGame();
	}
}

//For entity count testing
function StressTest()
{
	GameActive = true;
	for (local x = 0; x < 20; x++) {
		for (local z = 0; z < 20; z++) {
			local engineCoords = GameCoordsToEngineCoords(Vector(x, 0, z));
			SpawnSprite(engineCoords, 64, 64, 64, spriteTypes.player, directions.none);
		}
	}
	GameActive = false;
}

function SpawnSprites()
{
	//Turn off game if drawcount is reached.
	if (DrawCount >= MAXDRAWLIMIT)
	{
		return
	}
	local randomlyOrderedPlayers = ChooseRandomPlayerOrder(false);
	foreach (player in randomlyOrderedPlayers)
	{
		if (!IsAlive[player])
		{
			continue
		}
		
		if (NextDirection[player] != null)
		{
			LastDirection[player] = NextDirection[player]
			NextDirection[player] = null
		}
		
		drawPosition<-ChooseNewSpritePosition(LastPosition[player],LastDirection[player])
		if (HasCollided(drawPosition))
		{
			//debugprint("Player " + player + " has collided and is dead. " + drawPosition)
			KillPlayer(player)
			continue
		}
		
		DrawCount++
		
		//Recolor previous sprite
		local previousSprite = Entities.FindByClassnameWithin(null,"env_sprite_oriented",LastPosition[player],0.5);
		if (previousSprite != null)
		{
			previousSprite.__KeyValueFromString("rendercolor","" + DrawColor[player][0] + " " + DrawColor[player][1] + " " + DrawColor[player][2]);
		}
		
		sprite <- SpawnSprite(drawPosition, DrawHeadColor[player][0], DrawHeadColor[player][1], DrawHeadColor[player][2], spriteTypes.player, directions.none)
		PlayerSprites[player] = sprite
		
		LastPosition[player]=drawPosition
	}
}

function SpawnSprite(position, r, g, b, spriteType, direction)
{
	debugprint("In lightduel SpawnSprite");
	if (!GameActive) return
	env_entity_maker <- null
	env_entity_maker <- Entities.FindByName(env_entity_maker,SpriteToSpriteMaker[spriteType])
	env_entity_maker.SpawnEntityAtLocation(position,DirectionToAngles[direction]);
	local sprite = Entities.FindByNameWithin(null,SpriteToSpriteName[spriteType],position,0.5);
	debugprint("Created sprite " + SpriteToSpriteName[spriteType] + ":" + sprite + " at (" + position.x + "," + position.y + "," + position.z + ")")
	if (sprite != null)
	{
		sprite.__KeyValueFromInt("rendermode",9);
		sprite.__KeyValueFromInt("renderamt",255);
		sprite.__KeyValueFromString("rendercolor","" + r + " " + g + " " + b);
	}
	return sprite
}

function KillAllSprites()
{
	local sprite  = null;
	while ((sprite = Entities.FindByName(sprite, "cycle_sprite")) != null)
	{
		EntFireByHandle(sprite, "Kill", "", 0.0, this, this);
	}
	while ((sprite = Entities.FindByName(sprite, "cycle_sprite_rocket")) != null)
	{
		EntFireByHandle(sprite, "Kill", "", 0.0, this, this);
	}
	while ((sprite = Entities.FindByName(sprite, "cycle_sprite_explosion")) != null)
	{
		EntFireByHandle(sprite, "Kill", "", 0.0, this, this);
	}
}

function SpawnPlayers()
{
	if (OtherGameStarted || GameActive || GameStarted || GameEnded) return;
	
	KillAllSprites();
	
	DoEntFire("blob_script", "RunScriptCode", "SetOtherGameStarted(true)", 0.0, null, null);
	EntFire("sj_stop_relay", "Trigger", "", 0.0, null); //Close strafe jump to prevent easy cheating
	DoEntFire("blob_start_tt", "SetTextureIndex", "2", 0.0, null, null);
	DoEntFire("cycle_start_tt", "SetTextureIndex", "1", 0.0, null, null);
	DoEntFire("cycle_stop_tt", "SetTextureIndex", "0", 0.0, null, null);
	GameActive = true
	for (player <- 0; player < 4; player++)
	{
		if (IsPlayerActive[player])
		{
			SpawnPlayer(player)
		}
	}
	DrawCount=0
	LastSprite = Time() + 3.0
	CountDown = 4;
	NextCountdown = 0.0;
	
	SpawnArena(RandomInt(0, PrebuiltLevels.len()-1))
	
}

//Spawn players after start button has been pressed but before game has started
function SpawnPlayer(player)
{
	if (!IsAlive[player] && GameActive && !GameStarted)
	{
		DoEntFire("cycle_start_trigger"+player, "Enable", "", 0.00, null, null)
		DoEntFire("cycle_start_trigger"+player, "Disable", "", 0.25, null, null)
		IsAlive[player] = true
		LastPosition[player] = START_POSITIONS[player]
		LastDirection[player] = START_DIRECTIONS[player]
		NextDirection[player] = null
		SpawnSprite(START_POSITIONS[player], DrawHeadColor[player][0], DrawHeadColor[player][1], DrawHeadColor[player][2], spriteTypes.player, directions.none)
	}
}


function SpawnArena(arena)
{
	engineCoords <- null
	foreach (coords in PrebuiltLevels[arena])
	{
		engineCoords = GameCoordsToEngineCoords(coords)
		SpawnSprite(engineCoords, 64, 64, 64, spriteTypes.player, directions.none)
	}
}

function StopGame()
{
	TurnOffGameAt = null;
	KillAllSprites();
	for (local player = 0; player < 4; player++)
	{
		IsAlive[player] = false
		PlayerSprites[player] = null
	}
	GameActive = false;
	GameStarted = false;
	GameEnded = false;
	if (!OtherGameStarted) {
		DoEntFire("blob_start_tt", "SetTextureIndex", "0", 0.0, null, null);
		DoEntFire("blob_script", "RunScriptCode", "SetOtherGameStarted(false)", 0.0, null, null);
		DoEntFire("cycle_start_tt", "SetTextureIndex", "0", 0.0, null, null);
		DoEntFire("cycle_stop_tt", "SetTextureIndex", "1", 0.0, null, null);
	}
}

function KillPlayer(player)
{
	local livingPlayers = GetLivingPlayers();
	debugprint("There are " + livingPlayers + " livingPlayers");
	if (livingPlayers == 4) livingPlayers = 5;
	EntFireByHandle(teleportEntities[player], "SetRemoteDestination", "blob_teleport" + livingPlayers, 0.0, this, this);
	debugprint("Called EntFireByHandle");
	DoEntFire("cycle_game"+player, "Deactivate", "", 0.00, self, null) //CRASHES GAME WITH NO ACTIVATOR
	DoEntFire("cycle_kill"+player, "Enable", "", 0.05, null, null)
	DoEntFire("cycle_kill"+player, "Disable", "", 0.5, null, null)
	IsAlive[player]=false
	PlayerSprites[player]=null
	if (livingPlayers == 1) {
		GameActive = false;
		GameStarted = false;
		TurnOffGameAt = Time() + 5.0;
	}
	debugprint("Finished KillPlayer");
}

function GetLivingPlayers()
{
	livingPlayers<-0
	foreach (living in IsAlive)
	{
		if (living)
		{
			livingPlayers++
		}
	}
	return livingPlayers
}

function ChooseNewSpritePosition(oldPosition, direction)
{
	switch (direction) {
		case directions.up:
			return Vector(oldPosition.x, oldPosition.y, oldPosition.z + MOVEMENT_DISTANCE)
		case directions.down:
			return Vector(oldPosition.x, oldPosition.y, oldPosition.z - MOVEMENT_DISTANCE)
		case directions.left:
			return Vector(oldPosition.x + MOVEMENT_DISTANCE, oldPosition.y, oldPosition.z)
		case directions.right:
			return Vector(oldPosition.x - MOVEMENT_DISTANCE, oldPosition.y, oldPosition.z)
		default:
			return oldPosition
	}
}

function SetDirection(player, direction)
{
	activator.SetVelocity(Vector(0,0,0))
	if ((LastDirection[player] == directions.up && direction == directions.down) ||
		(LastDirection[player] == directions.down && direction == directions.up) ||
		(LastDirection[player] == directions.left && direction == directions.right) ||
		(LastDirection[player] == directions.right && direction == directions.left))
	{
		return
	}
	NextDirection[player]=direction
}

function SetPlayerActive(player, isActive)
{
	IsPlayerActive[player] = isActive
}

function EraseSprites(pos)
{
	sprite <- null
	while ((sprite = Entities.FindByClassnameWithin(sprite, "env_sprite_oriented", pos, DrawSize)) != null)
	{
		EntFireByHandle(sprite, "kill", "", 0, null, null)
		DrawCount--
	}
}

function IsWithinPlayArea(x,y,z)
{
	return z < MAX_ENGINE_COORD.z && z > MIN_ENGINE_COORD.z && x > MIN_ENGINE_COORD.x && x < MAX_ENGINE_COORD.x
}

function SetDrawColor(r,g,b)
{
	DrawColor = [r,g,b]
}

function SetDrawSize(size)
{
	DrawSize <- size
}

function GameCoordsToEngineCoords(gameCoords)
{
	return Vector((gameCoords.x*16).tofloat()+MIN_ENGINE_COORD.x - 8.0, MAX_ENGINE_COORD.y, (gameCoords.z*16).tofloat()+MIN_ENGINE_COORD.z - 8.0)
}

function HasCollided(pos)
{
	if (!IsWithinPlayArea(pos.x, pos.y, pos.z))
	{
		return true
	}
	local existingSprite = Entities.FindByClassnameWithin(null,"env_sprite_oriented",pos,DrawSize*2.0);
	return existingSprite != null
}

function FireRocket(player)
{
	if (IsAlive[player] && GameStarted && RocketPosition[player] == null)
	{
		RocketPosition[player] = ChooseNewSpritePosition(LastPosition[player],LastDirection[player])
		RocketDirection[player] = LastDirection[player]
		CheckRocketCollision(player)
	}
}

function UpdateRockets()
{
	UndrawRockets()
	local randomlyOrderedPlayersWithRockets = ChooseRandomPlayerOrder(true);
	foreach (player in randomlyOrderedPlayersWithRockets)
	{
		for (moves <- 0; moves < 2; moves++)
		{
			RocketPosition[player] = ChooseNewSpritePosition(RocketPosition[player],RocketDirection[player])
			if (CheckRocketCollision(player))
			{
				break
			}
		}
	}
	DrawRockets()
}

function CheckRocketCollision(player)
{
	if (HasCollided(RocketPosition[player]))
	{
		//debugprint("Rocket has hit something and is exploding at " + RocketPosition[player])
		Explode(RocketPosition[player])
		RocketPosition[player] = null
		return true
	}
	return false
}

function DrawRockets()
{
	for(player <- 0; player < 4; player++)
	{
		if (RocketPosition[player] != null)
		{
			SpawnSprite(RocketPosition[player], DrawHeadColor[player][0], DrawHeadColor[player][1], DrawHeadColor[player][2], spriteTypes.rocket, RocketDirection[player])
		}
	}

}

function UndrawRockets()
{
	for(player <- 0; player < 4; player++)
	{
		if (RocketPosition[player] != null)
		{
			local sprite = Entities.FindByNameWithin(null,"cycle_sprite_rocket",RocketPosition[player],DrawSize*2.0);
			if (sprite != null)
			{
				EntFireByHandle(sprite, "kill", "", 0, null, null)
			}
		}
	}
}

function Explode(position)
{
	local sprite = null
	while ((sprite = Entities.FindByClassnameWithin(sprite, "env_sprite_oriented", position,RocketSize)) != null)
	{
		foreach(player,playersprite in PlayerSprites)
		{
			if (playersprite == sprite)
			{
				KillPlayer(player)
			}
		}
		EntFireByHandle(sprite, "kill", "", 0, null, null)
		DrawCount--
	}
	SpawnSprite(position, 255, 128, 128, spriteTypes.explosion, directions.none)
	explosion <- null
	while ((explosion = Entities.FindByClassnameWithin(explosion, "env_sprite_oriented", position,DrawSize*2.0)) != null)
	{
		debugprint("Explosion sprite: " + explosion)
		EntFireByHandle(explosion, "SetScale", "0.5", 0.1, null, null)
		EntFireByHandle(explosion, "SetScale", "1.0", 0.2, null, null)
		EntFireByHandle(explosion, "SetScale", "2.0", 0.3, null, null)
		EntFireByHandle(explosion, "kill", "", 0.5, null, null)
	}
}

function ChooseRandomPlayerOrder(rocket)
{
	local playerOptions = [0, 1, 2, 3];
	local orderedPlayers = [];
	
	while(playerOptions.len() > 0)
	{
		local index = RandomInt(0, playerOptions.len()-1);
		local player = playerOptions[index];
		playerOptions.remove(index);
		if ((!rocket && IsAlive[player]) || (rocket && RocketPosition[player]))
		{
			orderedPlayers.append(player);
		}
	}
	return orderedPlayers;
}

function DisplayHelpText()
{
	if (GameStarted) return;
	local ply = null;
	while ((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		local playerOrigin = ply.GetOrigin()
		if (playerOrigin.x >= BOOTH_AREA_MIN.x && playerOrigin.x <= BOOTH_AREA_MAX.x &&
			playerOrigin.y >= BOOTH_AREA_MIN.y && playerOrigin.y <= BOOTH_AREA_MAX.y &&
			playerOrigin.z >= BOOTH_AREA_MIN.z && playerOrigin.z < BOOTH_AREA_MAX.z)
		{
			DisplayText(ply, "Instructions\n1. Look forward and press use.\n2. WASD to turn.\n3. Attack to fire rocket.");
		}
	}
}

function DisplayText(ply, text)
{
	local game_txt = GameTextEntities[ply.entindex()];
	if (game_txt != null)
	{
		game_txt.__KeyValueFromString("message", text);
		EntFireByHandle(game_txt,"Display","",0.1,ply,ply);
	}
}

function SetOtherGameStarted(val)
{
	OtherGameStarted = val;
}