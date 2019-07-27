//===============================
//=====       BLOB          =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

//EntityGroup[1]: digit1_case1
//EntityGroup[2]: digit2_case1
//EntityGroup[3]: digit3_case1
//EntityGroup[4]: digit1_case2
//EntityGroup[5]: digit2_case2
//EntityGroup[6]: digit3_case2
//EntityGroup[7]: digit1_case3
//EntityGroup[8]: digit2_case3
//EntityGroup[9]: digit3_case3
//EntityGroup[11]: pellet_teleport1
//EntityGroup[12]: pellet_teleport2
//EntityGroup[13]: pellet_teleport3
//EntityGroup[14]: pellet_teleport4

DEBUG_PRINT<-true
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

PI<-3.14;

const MAX_PLAYERS = 64;
NUM_TIMERS<-1
MAX_GAME_TIME<-120
MIN_GAME_TIME<-30
WARMUP_TIME<-4
MAX_WINNERS<-32;
MIN_WINNERS<-3;
const TEAM_TERRORIST = 2;
const TEAM_CT = 3;
SPRITE_SCALE_RATIO <- [1.0, 0.5, 0.25];
SPRITE_SCALE_THRESHHOLDS <- [0.0, 4.0, 8.0];
const NUM_SKINS = 16;

BlobTimeText<-array(NUM_TIMERS+1)
WinnersSettingTT<-null;

SpeedEntity<-null;
GameTextEntities<-array(MAX_PLAYERS+1);
EnvEntityMakerEntity<-null;

playerBlobs<-{};
playerEntities<-{};
playerRadii<-{};
playerAreas<-{};
maxPlayerAreas<-{};
playerBlobsToIndices<-{};
playerActive<-{};
playerSpeedBoostActive<-{};
playerModelChosen<-array(MAX_PLAYERS+1, 0);
spriteNameToScale<-{};
spriteNameToScale["blob_sprite"] <- 0.1;
spriteNameToScale["blob_sprite_negative"] <- 0.1;
spriteToArea<-{};
spriteToRadius<-{};
spriteToModelNum<-{};
spriteNumAndSizeToName<-null;
spriteZoneCenters<-array(NUM_SKINS);
spriteZoneAngles<-array(NUM_SKINS);
spriteMinAngles<-null;
spriteMaxAngles<-null;
spriteZonesEnabled<-false;
SkinSavedEntity<-null;
SKIN_DISPLAY_NAMES<-["white", "csgo", "thorgot", "steam", "white", "homer", "marge", "bart", "lisa", "maggie", "itchy", "scratchy", "doge", "thinking", "pokeball", "rainbow"];
SKIN_SAVED_PREFIX <- "BLOBSKIN";
NPC_SPRITE_AREA_SMALL<-(PI/4);
NPC_SPRITE_AREA_MEDIUM<-PI;
NPC_SPRITE_AREA_LARGE<-(4.0*PI);
NPC_SPRITE_SIZES<-[NPC_SPRITE_AREA_SMALL, NPC_SPRITE_AREA_MEDIUM, NPC_SPRITE_AREA_LARGE];
NPCBlobsToSpawn<-[0,0,0];
NPCBlobsToSpawnNegative<-[0,0,0];

GameTime<-90;
TimeLeft<-GameTime+WARMUP_TIME;
TimerActive<-false;
BetweenGames<-true;
OtherGameStarted<-false;
StartAllowedTime<-0.0;
WinnersSettings<-4;
GameNumber<-0;

NextTickTime<-0.0;
TIME_BETWEEN_TICKS<-0.05; //66 tick, so every other tick on 128 tick servers

COLOR_WHITE<-"255 255 255";
COLOR_RED<-"255 1 1";
COLOR_GREEN<-"1 255 1";
COLOR_BLUE<-"1 1 255";

GAME_AREA_MIN <- Vector(1280.0, -3872.0, -523.0);
GAME_AREA_MAX <- Vector(2816.0, -2368.0, -385.0);
GAME_CENTER<-Vector(2048.0, -3104.0, -523.0); // z was -444, so equivalent would be -523
GAME_Z_MAX<- (-192);
GAME_RADIUS<-688.0; //walls are 768 apart, width 32
GAME_RADIUS_PLAYERS<-768.0;
NPC_SPRITES_POSITIVE<-256;
NPC_SPRITES_NEGATIVE<-32;
SPRITE_Y_CORRECTION<-8.0;
SPRITE_Z_CORRECTION<-10.0;
SPRITE_HEIGHT<-(-512.0);
BASE_SPRITE_SIZE<-8.0;
MAX_SPRITE_SCALE<- 16.0;
MAX_ABSORB<-8; //Max number of sprites you can absorb per tick
SPEED_BOOST<-1.5;
SPEED_BOOST_LENGTH<-2.0;
START_AREA<-PI;

enum directions {
	up,
	down,
	left,
	right,
	none
}
DirectionToAngles<-{};
DirectionToAngles[directions.up]<-Vector(270,0,0)
DirectionToAngles[directions.down]<-Vector(90,0,0)
DirectionToAngles[directions.left]<-Vector(180,0,0)
DirectionToAngles[directions.right]<-Vector(0,0,0)
DirectionToAngles[directions.none]<-Vector(0,0,0)

function Setup()
{
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		GameTextEntities[i] = Entities.FindByName(null,"display_score_" + i);
	}
	EnvEntityMakerEntity = Entities.FindByName(null, "blob_sprite_entity_maker");
	WinnersSettingTT = Entities.FindByName(null, "blob_winners_tt");
	for (local i = 0; i < NUM_TIMERS; i++)
	{
		BlobTimeText[i] = Entities.FindByName(null, "blob_timer_text"+i);
	}
	SpeedEntity = Entities.FindByName(null, "blob_speed");
	SkinSavedEntity = Entities.FindByName(null, "surf_times");
	SetupSkinSprites();
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		playerModelChosen[i] = GetString(SKIN_SAVED_PREFIX + i.tostring()).tointeger();
	}
}

function SetupSkinSprites()
{
	spriteNumAndSizeToName<-array(NUM_SKINS);
	local r = GAME_RADIUS - 64;
	local oneWedge = 2.0 * PI / NUM_SKINS;
	for (local i = 0; i < NUM_SKINS; i++) {
		spriteNumAndSizeToName[i] = array(3);
		spriteNumAndSizeToName[i][0] = "sprites/arcade_blob_" + SKIN_DISPLAY_NAMES[i] + "0.vmt";
		spriteNumAndSizeToName[i][1] = "sprites/arcade_blob_" + SKIN_DISPLAY_NAMES[i] + "1.vmt";
		spriteNumAndSizeToName[i][2] = "sprites/arcade_blob_" + SKIN_DISPLAY_NAMES[i] + "2.vmt";
		local angle = i * oneWedge;
		spriteZoneCenters[i] = Vector(r * cos(angle) + GAME_CENTER.x, r * sin(angle) + GAME_CENTER.y, GAME_CENTER.z + SPRITE_HEIGHT);
		spriteZoneAngles[i] = i * (360 / NUM_SKINS);
	}
	local oneWedge = PI/16;
	spriteMinAngles <- [ 0, 0, 0, 0, 0, 0, 0, 0, -15 * oneWedge, -13 * oneWedge, -11 * oneWedge, -9 * oneWedge, -7 * oneWedge, -5 * oneWedge, -3 * oneWedge, -oneWedge ];
	spriteMaxAngles <- [ -oneWedge, oneWedge, 3 * oneWedge, 5 * oneWedge, 7 * oneWedge, 9 * oneWedge, 11 * oneWedge, 13 * oneWedge, 15 * oneWedge];
}

//ent_fire blob_script RunScriptCode "SpawnSkinSprites()"
function SpawnSkinSprites()
{
	if (spriteZonesEnabled) return;
	spriteZonesEnabled = true;
	for (local i = 0; i < NUM_SKINS; i++) {
		if (i == 4) continue;
		local sprite = SpawnSprite(spriteZoneCenters[i], COLOR_WHITE, i, directions.none, 8.25, "blob_sprite_skin");
		sprite.SetAngles(90, spriteZoneAngles[i], 0);
	}
}

function KillSkinSprites()
{
	EntFire("blob_sprite_skin", "Kill", "", 0.0, null);
	spriteZonesEnabled = false;
}

function SelectSkin(ply, playerOrigin)
{
	if ((playerOrigin - GAME_CENTER).Length() > GAME_RADIUS - 128)
	{
		local angle = atan2(playerOrigin.y - GAME_CENTER.y, playerOrigin.x - GAME_CENTER.x);
		//debugprint("Angle of player is: " + angle);
		for (local i = 8; i < NUM_SKINS; i++) {
			if (angle <= spriteMinAngles[i]) {
				//debugprint("skin selected: " + i);
				playerModelChosen[ply.entindex()] = i;
				SaveString(SKIN_SAVED_PREFIX + ply.entindex().tostring(), i.tostring());
				return;
			}
		}
		for (local i = 8; i >= 0; i--) {
			if (angle >= spriteMaxAngles[i]) {
				if (i == 4) return; //Skip empty spot
				//debugprint("skin selected: " + i);
				playerModelChosen[ply.entindex()] = i;
				SaveString(SKIN_SAVED_PREFIX + ply.entindex().tostring(), i.tostring());
				return;
			}
		}
		debugprint("Error: within range but no angle chosen.");
	}
}

function Think()
{
	if (!TimerActive || Time() < NextTickTime) return;
	NextTickTime = Time() + TIME_BETWEEN_TICKS;
	
	for (local spriteType = 0; spriteType < 3; spriteType ++)
	{
		while (NPCBlobsToSpawn[spriteType] > 0)
		{
			SpawnNPCSprite(true, spriteType)
			NPCBlobsToSpawn[spriteType]--;
		}
		while (NPCBlobsToSpawnNegative[spriteType] > 0)
		{
			SpawnNPCSprite(false, spriteType)
			NPCBlobsToSpawnNegative[spriteType]--;
		}
	}
	
	for (local playerIndex = 0; playerIndex <= MAX_PLAYERS; playerIndex++)
	{
		if (playerIndex in playerBlobs && playerBlobs[playerIndex].IsValid() && playerIndex in playerEntities && playerEntities[playerIndex].IsValid() && playerActive[playerIndex])
		{
			if (playerEntities[playerIndex].GetHealth() <= 0)
			{
				RemovePlayerFromGame(playerEntities[playerIndex]);
				continue;
			}
			
			local success = CheckForAbsorption(playerIndex, playerBlobs[playerIndex]);
			if (success)
			{
				AdjustSpeed(playerEntities[playerIndex], SizeToSpeed(playerRadii[playerIndex]));
			}
		}
	}
}

function CheckForAbsorption(playerIndex, playerBlob)
{
	local success = false;
	local absorbed = 0;
	local sprite = null;
	local absorbedSprites = array(MAX_ABSORB);
	while ((sprite = Entities.FindByClassnameWithin(sprite, "env_sprite_oriented", playerBlob.GetOrigin(), playerRadii[playerIndex] * BASE_SPRITE_SIZE)) != null)
	{
		if (sprite == playerBlob) continue;
		local isPlayerSprite = false;
		
		//Get size of intersecting sprite (whether NPC or human)
		local spriteSize = 0;
		local spriteArea = 0;
		if (sprite in spriteToArea && sprite in spriteToRadius)
		{
			spriteSize = spriteToRadius[sprite];
			spriteArea = spriteToArea[sprite];
		}
		else if (sprite in playerBlobsToIndices && playerActive[playerBlobsToIndices[sprite]])
		{
			isPlayerSprite = true;
			//debugprint("Intersecting with player " + playerBlobsToIndices[sprite] + " who has radius " + playerRadii[playerBlobsToIndices[sprite]] + " and area " + playerAreas[playerBlobsToIndices[sprite]]);
			spriteSize = playerRadii[playerBlobsToIndices[sprite]];
			spriteArea = playerAreas[playerBlobsToIndices[sprite]];
		}
		else
		{
			//Skip, non-game sprite
			continue;
		}
		
		//Absorb if size is 5% larger than the target sprite
		if (playerRadii[playerIndex] > spriteSize * 1.05)
		{
			success = true;
			Absorb(playerIndex, playerBlob, sprite, spriteArea);
			if (isPlayerSprite)
			{
				KillPlayer(playerBlobsToIndices[sprite]);
			}
			else
			{
				absorbedSprites[absorbed++] = sprite;
				//Add to respawn queue
				spriteType <- (spriteArea == NPC_SPRITE_AREA_SMALL ? 0 : (spriteArea == NPC_SPRITE_AREA_MEDIUM ? 1 : (2)));
				if (sprite.GetName() == "blob_sprite_negative")
				{
					NPCBlobsToSpawnNegative[spriteType]++;
				}
				else
				{
					NPCBlobsToSpawn[spriteType]++;
				}
			}
			if (absorbed >= MAX_ABSORB) break;
		}
	}
	for (absorbed = 0; absorbed < MAX_ABSORB; absorbed++)
	{
		if (absorbedSprites[absorbed] != null && absorbedSprites[absorbed].IsValid())
		{
			absorbedSprites[absorbed].Destroy();
		}
	}
	return playerActive[playerIndex] && success;
}

function Absorb(playerIndex, playerBlob, absorbedSprite, spriteArea)
{
	if (absorbedSprite.GetName() == "blob_sprite_negative")
	{
		spriteArea = spriteArea * (-5.0);
	}
	//debugprint("Player " + playerIndex + " of size " + playerRadii[playerIndex] + " absorbing sprite " + absorbedSprite.entindex() + " of area " + spriteArea);
	AddToArea(playerIndex, spriteArea);
	//playerRadii[playerIndex] += spriteArea;
	if (playerRadii[playerIndex] > MAX_SPRITE_SCALE)
	{
		playerRadii[playerIndex] = MAX_SPRITE_SCALE;
	}
	if (playerRadii[playerIndex] < 1.0) 
	{
		KillPlayer(playerIndex);
	}
	SetBlobScale(playerBlob, playerRadii[playerIndex]);
}

function KillPlayer(playerIndex)
{
	//debugprint("Player " + playerIndex + " has died. setting to blue for 5 seconds");
	SetArea(playerIndex, START_AREA);
	playerActive[playerIndex] = false;
	playerSpeedBoostActive[playerIndex] = false;
	playerBlobs[playerIndex].__KeyValueFromString("rendercolor", COLOR_BLUE);
	SetBlobScale(playerBlobs[playerIndex], playerRadii[playerIndex]);
	if (playerIndex in playerEntities)
	{
		AdjustSpeed(playerEntities[playerIndex], 1.5);
	}
	DoEntFire("blob_script", "RunScriptCode", "ReactivatePlayer(" + playerIndex + "," + GameNumber + ")", 5.0, null, null);
}

function ReactivatePlayer(playerIndex, gameNumberWhenKilled)
{
	if (!TimerActive || !(playerIndex in playerActive) || playerActive[playerIndex] || gameNumberWhenKilled != GameNumber) return;
	//debugprint("Player " + playerIndex + " returning to life");
	playerActive[playerIndex] = true;
	if (playerIndex in playerBlobs && playerBlobs[playerIndex].IsValid())
	{
		playerBlobs[playerIndex].__KeyValueFromString("rendercolor", COLOR_WHITE);
	}
	if (playerIndex in playerEntities)
	{
		AdjustSpeed(playerEntities[playerIndex], SizeToSpeed(1.0));
	}
}

function SpeedBoost()
{
	if (!TimerActive) return;
	if (activator == null || activator.entindex() > 64) return;
	local playerIndex = activator.entindex();
	if (!(playerIndex in playerRadii) || playerRadii[playerIndex] < 1.2) return;
	if (playerIndex in playerActive && playerActive[playerIndex] && playerIndex in playerSpeedBoostActive && !playerSpeedBoostActive[playerIndex] && playerIndex in playerRadii && playerIndex in playerBlobs)
	{
		playerSpeedBoostActive[playerIndex] = true;
		AdjustSpeed(activator, SizeToSpeed(playerRadii[playerIndex]));
		DoEntFire("blob_script", "RunScriptCode", "EndSpeedBoost()", SPEED_BOOST_LENGTH, activator, null);
		playerBlobs[playerIndex].__KeyValueFromString("rendercolor", "200 255 200");
		playerRadii[playerIndex] *= 0.9;
		SetBlobScale(playerBlobs[playerIndex], playerRadii[playerIndex]);
	}
	
}

function EndSpeedBoost()
{
	if (!TimerActive) return;
	if (activator == null || activator.entindex() > 64) return;
	local playerIndex = activator.entindex();
	if (playerIndex in playerActive && playerActive[playerIndex] && playerIndex in playerSpeedBoostActive && playerSpeedBoostActive[playerIndex] && playerIndex in playerRadii && playerIndex in playerBlobs)
	{
		playerSpeedBoostActive[playerIndex] = false;
		AdjustSpeed(activator, SizeToSpeed(playerRadii[playerIndex]));
		playerBlobs[playerIndex].__KeyValueFromString("rendercolor", COLOR_WHITE);
	}
	
}

function SetBlobScale(blob, radius)
{
	if (blob == null) return;
	if (!(blob in spriteToModelNum)) spriteToModelNum[blob] <- 0;
	
	local newScale = radius;
	if (radius > SPRITE_SCALE_THRESHHOLDS[2]) {
		blob.SetModel(spriteNumAndSizeToName[spriteToModelNum[blob]][2]);
		newScale *= SPRITE_SCALE_RATIO[2];
	} else if (radius > SPRITE_SCALE_THRESHHOLDS[1]) {
		blob.SetModel(spriteNumAndSizeToName[spriteToModelNum[blob]][1]);
		newScale *= SPRITE_SCALE_RATIO[1];
	} else {
		blob.SetModel(spriteNumAndSizeToName[spriteToModelNum[blob]][0])
	}
	blob.__KeyValueFromFloat("scale", newScale);
}

//Range from 0.5 at size 1.0 to 0.06 at size MAX_SPRITE_SCALE
function SizeToSpeed(size)
{
	return ((MAX_SPRITE_SCALE - size + 1.0) / MAX_SPRITE_SCALE) * 0.45 + 0.05
}

function AdjustSpeed(ply, speed)
{
	EntFireByHandle(SpeedEntity, "ModifySpeed", (playerSpeedBoostActive[ply.entindex()] ? (speed * SPEED_BOOST): speed).tostring(), 0, ply, null);
	//debugprint("Setting player " + ply.entindex().tostring() + " to speed " + speed.tostring());
}

function RemoveSpeedFromActivator()
{
	if (activator != null)
	{
		RemoveSpeed(activator);
	}
}

function RemoveSpeed(ply)
{
	EntFireByHandle(SpeedEntity, "ModifySpeed", "1.0", 0, ply, null);
}

function RemoveSpeedFromAll()
{
	for (local playerIndex = 1; playerIndex <= 64; playerIndex++)
	{
		if (playerIndex in playerEntities && playerEntities[playerIndex].IsValid())
		{
			RemoveSpeed(playerEntities[playerIndex]);
		}
	}
}

function AreaToRadius(area)
{
	//area = 3.14*r*r
	//r^2 = area/(3.14)
	//r = sqrt(area/3.14);2
	//debugprint("radius for area " + area + " = " + ((area < 0) ? "0" : sqrt(area/PI).tostring()));
	if (area < 0) return 0;
	return sqrt(area/PI);
}

function AddToArea(playerIndex, area)
{
	if (playerIndex in playerAreas)
	{
		SetArea(playerIndex, playerAreas[playerIndex] + area);
		//debugprint("Player " + playerIndex + " gained " + area + " area and now has area " + playerAreas[playerIndex]);
	}
}

//3.7 radius: ent_fire blob_script runscriptcode "SetArea(1, 40)"
//7.9 radius: ent_fire blob_script runscriptcode "SetArea(1, 195)"
function SetArea(playerIndex, area)
{
	playerAreas[playerIndex] <- area;
	playerRadii[playerIndex] <- AreaToRadius(playerAreas[playerIndex]);
	if (maxPlayerAreas[playerIndex] < playerAreas[playerIndex]) maxPlayerAreas[playerIndex] <- playerAreas[playerIndex];
}

function AddToGameTime(time)
{
	if (!BetweenGames) return;
	GameTime += time;
	if (GameTime > MAX_GAME_TIME) GameTime = MAX_GAME_TIME;
	if (GameTime < MIN_GAME_TIME) GameTime = MIN_GAME_TIME;
	if (!TimerActive)
	{
		TimeLeft = GameTime + WARMUP_TIME;
		SetTimerSeconds(GameTime);
	}
}

function AddToWinnersSetting(toAdd)
{
	if (TimerActive) return;
	WinnersSettings += toAdd;
	if (WinnersSettings > MAX_WINNERS) WinnersSettings = MAX_WINNERS;
	if (WinnersSettings < MIN_WINNERS) WinnersSettings = MIN_WINNERS;

	EntFireByHandle(WinnersSettingTT, "SetTextureIndex", WinnersSettings.tostring(), 0.0, null, self);
}

//Debug function: ent_fire blob_script runscriptcode "debugSetPlayerSprite(0)"
function debugSetPlayerSprite(num)
{
	for (local i = 1; i < MAX_PLAYERS; i++) {
		if (i in playerBlobs) {
			debugprint("Setting player " + i + " sprite to " + spriteNumAndSizeToName[num][0]);
			playerBlobs[i].SetModel(spriteNumAndSizeToName[num][0]);
		}
	}
}
//Debug function: ent_fire blob_script runscriptcode "debugSetPlayerModel(1, 1)"
function debugSetPlayerModel(playerIndex, model)
{
	debugprint("Setting player " + playerIndex + " sprite to " + spriteNumAndSizeToName[model][0]);
	playerModelChosen[playerIndex] = model;
}
/*
  scale: 0.50
  framerate: 1.00
  HDRColorScale: 1.00
  GlowProxySize: 5.00
  SetScale: 0.50
  classname: env_sprite_oriented
  effects: 80
  friction: 1.00
  fadescale: 1.00
  
  scale: 0.50
  framerate: 1.00
  HDRColorScale: 1.00
  GlowProxySize: 5.00
  SetScale: 0.50
  classname: env_sprite_oriented
  hammerid: 1180908
  effects: 80
  friction: 1.00
  spawnflags: 1
  fademindist: -1.00
  fadescale: 1.00
*/
function SpawnSprite(position, rgb, spriteNum, direction, scale, targetname)
{
	//debugprint("In blob SpawnSprite");
	//if (!TimerActive) return
	/*
	//Doesn't work for some reason, so using EnvEntityMaker
	local sprite = Entities.CreateByClassname("env_sprite_oriented");
	sprite.SetModel(spriteNumAndSizeToName[spriteNum][0]);
	sprite.SetOrigin(position);
	sprite.__KeyValueFromString("targetname","blob_sprite");
	debugprint("Created sprite #" + spriteNum + ": " + sprite + " at " + sprite.GetOrigin())
	sprite.__KeyValueFromInt("rendermode",9);
	sprite.__KeyValueFromInt("renderamt",255);
	sprite.__KeyValueFromString("rendercolor", rgb);
	sprite.__KeyValueFromString("angles", "90 270 0");
	sprite.__KeyValueFromString("framerate", "1.0");
	sprite.__KeyValueFromString("GlowProxySize", "5.0");
	sprite.__KeyValueFromString("rendermode", "1");
	sprite.__KeyValueFromInt("effects", 80);
	sprite.__KeyValueFromFloat("fadescale", 1.0);
	SetBlobScale(sprite, scale);
	EntFireByHandle(sprite, "ShowSprite", "", 0.05, null, null);*/
	//local correctedSpawnPosition = Vector(position.x - SPRITE_Y_CORRECTION, position.y, position.z + SPRITE_Z_CORRECTION);
	local correctedSpawnPosition = Vector(position.x, position.y, position.z);
	EnvEntityMakerEntity.SpawnEntityAtLocation(correctedSpawnPosition,DirectionToAngles[direction]);
	local sprite = Entities.FindByNameNearest("blob_sprite",position,0.5);
	if (sprite != null)
	{
		sprite.__KeyValueFromString("targetname",targetname);
		//debugprint("Created sprite " + targetname + " #" + spriteNum + ": " + sprite + " at " + sprite.GetOrigin())
		sprite.__KeyValueFromInt("rendermode",9);
		sprite.__KeyValueFromInt("renderamt",255);
		sprite.__KeyValueFromString("rendercolor", rgb);
		sprite.SetModel(spriteNumAndSizeToName[spriteNum][0]);
		spriteToModelNum[sprite] <- spriteNum;
		SetBlobScale(sprite, scale);
	}
	else
	{
		debugprint("ERROR: Could not find sprite spawned by blob at " + position + " (corrected: " + correctedSpawnPosition + ")");
		local tmp = Entities.FindByNameNearest("blob_sprite",position,25);
		if (tmp != null)
		{
			debugprint("sprite found too far away at: " + tmp.GetOrigin())
		
		}
	}
	
	return sprite;
}

function SpawnTestPlayerSprite(playerIndex)
{
	local size = RandomFloat(START_AREA, 9*START_AREA).tofloat();
	local position = GetRandomPointInCircle(GAME_CENTER, GAME_RADIUS);
	position.z += SPRITE_HEIGHT;
	debugprint("Spawning test sprite for player at " + position);
	sprite <- SpawnSprite(position, COLOR_WHITE, 0, directions.none, AreaToRadius(size), "blob_sprite_parented");
	playerBlobs[playerIndex] <- sprite;
	SetArea(playerIndex, size); //Set area and radius
	playerSpeedBoostActive[playerIndex] <- false;
	playerBlobsToIndices[sprite] <- playerIndex;
	playerActive[playerIndex] <- true;
}

function SpawnAndAttachPlayerSprite(ply)
{
	local playerIndex = ply.entindex();
	maxPlayerAreas[playerIndex] <- START_AREA;
	position <- ply.GetOrigin();
	position.z += SPRITE_HEIGHT - SPRITE_Z_CORRECTION;
	//debugprint("Spawning sprite for player " + ply + " who is at " + ply.GetOrigin());
	sprite <- SpawnSprite(position, COLOR_WHITE, playerModelChosen[playerIndex], directions.none, AreaToRadius(START_AREA), "blob_sprite_parented");
	if (sprite != null)
	{
		EntFireByHandle(sprite, "SetParent", "!activator", 0, ply, null);
		playerBlobs[playerIndex] <- sprite;
		playerBlobsToIndices[sprite] <- playerIndex;
		local angles = ply.GetAngles();
		sprite.SetAngles(90, angles.y - 360, 0);
	}
	SetArea(playerIndex, START_AREA); //Set area and radius
	playerActive[playerIndex] <- false;
	playerSpeedBoostActive[playerIndex] <- false;
}

function SpawnAndAttachPlayerSprites()
{
	local startSpeed = SizeToSpeed(1.0);
	ply <- null;
	while ((ply = Entities.FindByClassnameWithin(ply, "player", GAME_CENTER, GAME_RADIUS_PLAYERS)) != null)
	{
		//debugprint("ply.GetOrigin().z: " + ply.GetOrigin().z.tostring() + " being compared to GAME_Z_MAX: " + GAME_Z_MAX);
		if (ply.GetOrigin().z > GAME_Z_MAX || ply.GetHealth() <= 0 || (ply.GetTeam() != TEAM_TERRORIST && ply.GetTeam() != TEAM_CT) ) continue;
		//debugprint("spawning sprite for player " + ply);
		SpawnAndAttachPlayerSprite(ply);
		playerEntities[ply.entindex()] <- ply;
		AdjustSpeed(ply, startSpeed);
	}
}

function GetRandomPointInCircle(center, radius)
{
	for (local i = 0; i < 64; i++)
	{
		local randomX = RandomFloat(-radius, radius);
		local randomY = RandomFloat(-radius, radius);
		if ((randomX)*(randomX) + (randomY)*(randomY) > radius * radius)
		{
			//debugprint("Discarding point " + randomX + "," + randomY + " because it lies outside the circle: " + (randomX) + "^2 + " + (randomY) + "^2 > " + radius + "^2");
			continue;
		}
		return Vector(randomX + center.x, randomY + center.y, center.z);
	}
	return null;
}

function SpawnNPCSprite(positive, type)
{
	if (!TimerActive) return;
	local position = GetRandomPointInCircle(GAME_CENTER, GAME_RADIUS);
	if (position == null) return;
	local spriteName = positive ? "blob_sprite" : "blob_sprite_negative";
	local color = positive ? COLOR_GREEN : COLOR_RED;
	position.z += SPRITE_HEIGHT;
	local area = NPC_SPRITE_SIZES[type];
	local radius = AreaToRadius(area);
	sprite <- SpawnSprite(position, color, 0, directions.none, radius, spriteName);
	spriteToArea[sprite] <- area;
	spriteToRadius[sprite] <- radius;
	//debugprint("Spawned NPC sprite at " + sprite.GetOrigin() + " of type " + type.tostring() + (positive ? "+" : "-").tostring());
}

function GetRandomSpriteType()
{
	local randomSize = RandomInt(0,100);
	if (randomSize == 0)
	{
		return 2;
	}
	else if (randomSize <= 5)
	{
		return 1;
	}
	return 0;
}

function SpawnAllNPCSprites()
{
	EntFireByHandle(self, "RunScriptCode", "SpawnNPCSprites(false, "+NPC_SPRITES_NEGATIVE+")", 0.0, null, self);
	for (local i = 1; i <= 8; i++)
	{
		EntFireByHandle(self, "RunScriptCode", "SpawnNPCSprites(true, "+(NPC_SPRITES_POSITIVE/8)+")", 0.1 * i, null, self);
	}
}

function SpawnNPCSprites(positive, quantity)
{
	for (local i = 0; i < quantity; i++)
	{
		SpawnNPCSprite(positive, GetRandomSpriteType());
	}
}

function StartTimer()
{
	if (TimerActive || TimeLeft <= 0 || Time() < StartAllowedTime || OtherGameStarted) return;
	DoEntFire("draw_script", "RunScriptCode", "SetOtherGameStarted(true)", 0.0, null, null);
	EntFire("sj_stop_relay", "Trigger", "", 0.0, null); //Close strafe jump to prevent easy cheating
	KillSkinSprites();
	DoEntFire("cycle_start_tt", "SetTextureIndex", "2", 0.0, null, null);
	DoEntFire("blob_reset_tt", "SetTextureIndex", "0", 0.0, null, null);
	DoEntFire("blob_start_tt", "SetTextureIndex", "1", 0.0, null, null);
	GameNumber++;
	BetweenGames = false;
	TimerActive = true;
	SpawnAllNPCSprites();
	SpawnAndAttachPlayerSprites();
	
	/*
	local testplayerindex = RandomInt(20,30); //for testing
	SpawnTestPlayerSprite(testplayerindex); //for testing
	SpawnTestPlayerSprite(testplayerindex+1); //for testing
	SpawnTestPlayerSprite(testplayerindex+2); //for testing
	SpawnTestPlayerSprite(testplayerindex+3); //for testing
	SpawnTestPlayerSprite(testplayerindex+4); //for testing
	SpawnTestPlayerSprite(testplayerindex+5); //for testing
	*/
	
	DoEntFire("blob_script", "RunScriptCode", "TimerTick()", 1.0, null, null);
}

function TimerTick()
{
	if (!TimerActive) return;
	TimeLeft--;
	if (TimeLeft > 0)
	{
		DoEntFire("blob_script", "RunScriptCode", "TimerTick()", 1.0, null, null);
		if (TimeLeft == GameTime)
		{
			//Warmup is over, start the game!
			SetTimerTextAll("GO!!", COLOR_GREEN);
			DoEntFire("blob_start_sound", "PlaySound", "4", 0.0, null, null);
			for (local playerIndex = 1; playerIndex <= 64; playerIndex++)
			{
				if (playerIndex in playerActive)
				{
					playerActive[playerIndex] = true;
				}
			}
			DisplayHudTextToAll();
		}
		else if (TimeLeft > GameTime)
		{
			SetTimerTextAll(" " + (TimeLeft - GameTime).tostring() + "!", COLOR_RED);
			DoEntFire("blob_warmup_sound", "PlaySound", "4", 0.0, null, null);
		}
		else
		{
			SetTimerSeconds(TimeLeft);
			DisplayHudTextToAll();
		}
	}
	else
	{
		EndGame(true);
		ResetTime();
	}
}

function EndGame(rankPlayers)
{
	TimerActive = false;
	DoEntFire("blob_sprite", "Kill", "", 0.0, null, null);
	DoEntFire("blob_sprite_negative", "Kill", "", 0.0, null, null);
	DoEntFire("blob_sprite_parented", "Kill", "", 0.0, null, null);
	RemoveSpeedFromAll();
	if (rankPlayers)
	{
		RetrieveTopScores(WinnersSettings);
	}
	playerActive.clear();
	playerBlobs.clear();
	playerEntities.clear();
	playerRadii.clear();
	playerAreas.clear();
	maxPlayerAreas.clear();
	playerBlobsToIndices.clear();
	playerSpeedBoostActive.clear();
	spriteToArea.clear();
	spriteToRadius.clear();
	spriteToModelNum.clear();
	return;
}

function SetGameTime(time)
{
	GameTime = time;
}

function StopButton()
{
	EndGame(false);
	ResetTime();
}

function ResetTime()
{
	StartAllowedTime<-Time()+1.0;
	//debugprint("StartAllowedTime set to: " + StartAllowedTime);
	BetweenGames = true;
	TimeLeft = GameTime + WARMUP_TIME;
	SetTimerSeconds(GameTime);
	if (!OtherGameStarted) {
		DoEntFire("cycle_start_tt", "SetTextureIndex", "0", 0.0, null, null);
		DoEntFire("draw_script", "RunScriptCode", "SetOtherGameStarted(false)", 0.0, null, null);
		DoEntFire("blob_reset_tt", "SetTextureIndex", "1", 0.0, null, null);
		DoEntFire("blob_start_tt", "SetTextureIndex", "0", 0.0, null, null);
	}
	return;
}

function SetTimerSeconds(time)
{
	local minutes = time / 60;
	local seconds = time % 60;
	local timeString = minutes.tostring() + ":" + (seconds < 10 ? "0" : "") + seconds;
	SetTimerTextAll(timeString, COLOR_WHITE);
}

function SetTimerTextAll(text, color)
{
	for (local i = 0; i < NUM_TIMERS; i++)
	{
		SetTimerText(i, text, color);
	}
}

function SetTimerText(timer, text, color)
{
	BlobTimeText[timer].__KeyValueFromString("message", text);
	BlobTimeText[timer].__KeyValueFromString("color", color);
}

function RetrieveTopScores(winners)
{
	winningPlayers<-SortPlayersByScore();
	
	teleportDesinationEntities<-[EntityGroup[0], EntityGroup[1], EntityGroup[2]];
	winnersDestination<-EntityGroup[3];
	losersDestination<-EntityGroup[4];
	for (local winningScores = 0; winningScores < winningPlayers.len(); winningScores++)
	{
		local playerIndex = winningPlayers[winningScores].index;
		local teleportDestination = losersDestination;
		if (winningScores < 3)
		{
			debugprint("Player " + playerIndex + " for podium " + (winningScores+1));
			teleportDestination = teleportDesinationEntities[winningScores];
		}
		else if (winningScores < winners)
		{
			debugprint("Player " + playerIndex + " for winners podium");
			teleportDestination = winnersDestination;
		}
		else
		{
			debugprint("Player " + playerIndex + " for losers podium");
		}
		if (!(playerIndex in playerEntities) || !(playerEntities[playerIndex].IsValid())) continue;
		delete playerActive[playerIndex];
		playerEntities[playerIndex].SetOrigin(teleportDestination.GetOrigin());
		playerEntities[playerIndex].SetVelocity(Vector(0,0,0));
	}
}

function ArrayToString(_array, length)
{
	if (_array == null) return "";
	local returnString = "[";
	for (local i = 0; i < length; i++)
	{
		returnString += _array[i];
		if (i != length - 1) returnString += ", ";
	}
	return returnString + "]";
}

function ComparePlayersByScores(playerA,playerB)
{
	//debugprint("comparing player " + playerA.index + " with player " + playerB.index);
	//debugprint("area/maxarea: " +playerA.area+","+playerA.maxarea+" to "+playerB.area+","+playerB.maxarea);
	if      (playerA.area < playerB.area) return 1;
    else if (playerA.area > playerB.area) return -1;
	else if (playerA.maxarea < playerB.maxarea) return 1;
	else if (playerA.maxarea > playerB.maxarea) return -1;
	return 0;
}

function SortPlayersByScore()
{
	local activePlayers = array(65);
	local numPlayers = 0;
	for (local playerIndex = 1; playerIndex <= 64; playerIndex++)
	{
		//if (!(playerIndex in playerActive) || !playerActive[playerIndex]) continue;
		//if (!(playerIndex in playerEntities) || playerEntities[playerIndex].GetHealth() <= 0) continue;
		if (!(playerIndex in playerAreas)) continue;
		//This should really be how the data is stored, but instead bad design decisions were made.
		local activePlayer = {index = playerIndex, area = playerAreas[playerIndex], maxarea = maxPlayerAreas[playerIndex]};
		activePlayers[numPlayers++] = activePlayer;
		//debugprint("Adding player " + playerIndex + " with area " + playerAreas[playerIndex] + " to active players");
	}
	activePlayers = activePlayers.slice(0, numPlayers);
	//debugprint("Players before sort: " + ArrayToString(activePlayers, numPlayers));
	activePlayers.sort(ComparePlayersByScores);
	//debugprint("Players after sort: " + ArrayToString(activePlayers, numPlayers));
	return activePlayers;
}


function GetPlayerPosition(playerIndex)
{
	score <- playerAreas[playerIndex]
	other_player <- null;
	scores <- {
		position=1
		next_score=99999
	}
	for (local otherPlayerIndex = 1; otherPlayerIndex <= MAX_PLAYERS; otherPlayerIndex++)
	{
		if (otherPlayerIndex == playerIndex || !(otherPlayerIndex in playerAreas)) continue;
		if (playerAreas[otherPlayerIndex] > score)
		{
			scores.position++
			if (playerAreas[otherPlayerIndex] < scores.next_score)
			{
				scores.next_score = playerAreas[otherPlayerIndex]
			}
		}
	}
	return scores

}

function GetPlayerScore(player)
{
	if (!player.ValidateScriptScope() || player.GetHealth() <= 0)
	{
		return 0
	}
	local script_scope=player.GetScriptScope()
	if (!("pellet_score" in script_scope))
	{
		return 0
	}
	return script_scope.pellet_score
}

function DisplayHudTextToAll()
{
	local totalPlayers = 0;
	
	for (local playerIndex = 0; playerIndex <= MAX_PLAYERS; playerIndex++)
	{
		if (playerIndex in playerEntities && playerIndex in playerAreas && playerEntities[playerIndex].GetHealth() > 0)
		{
			totalPlayers++;
		}
	}
	
	for (local playerIndex = 0; playerIndex <= MAX_PLAYERS; playerIndex++)
	{
		if (playerIndex in playerEntities && playerIndex in playerAreas)
		{
			DisplayScore(playerIndex, totalPlayers);
		}
	}
}

function DisplayScore(playerIndex, totalPlayers)
{
	if (!(playerIndex in playerEntities) || !playerEntities[playerIndex].IsValid() || playerEntities[playerIndex].GetHealth() <= 0) return;
	local game_txt = GameTextEntities[playerIndex];
	local scores = GetPlayerPosition(playerIndex);
	if (game_txt != null)
	{
		score_text <- "Current Area: " + (playerAreas[playerIndex] * 10.0).tointeger().tostring() + //"(radius " + playerRadii[playerIndex] + ")" +
					  "\nTime Left: " + TimeLeft + "s" +
					  "\nCurrent Place: " + scores.position.tostring() + " out of " + totalPlayers.tostring() +
					  "\nNext Place Score: " + ((scores.next_score < 99999) ? (scores.next_score * 10.0).tointeger().tostring() : "N/A")
		game_txt.__KeyValueFromString("message", score_text);
		EntFireByHandle(game_txt,"Display","",0.1,playerEntities[playerIndex],playerEntities[playerIndex]);
	}
}

function DebugSetHudTextLocation(x, y)
{
	game_txt <- Entities.FindByName(null,"display_score_1");
	game_txt.__KeyValueFromString("x", x.tostring());
	game_txt.__KeyValueFromString("y", y.tostring());
}

// ent_fire blob_script runscriptcode "RemovePlayerFromGameIndex(1)"
function RemovePlayerFromGameIndex(playerIndex)
{
	RemovePlayerFromGame(playerEntities[playerIndex]);
}

function RemovePlayerFromGameActivator()
{
	RemovePlayerFromGame(activator);
}

function RemovePlayerFromGame(ply)
{
	if (ply == null || !ply.IsValid()) return;
	
	local playerIndex = ply.entindex();
	if (!(playerIndex in playerActive) || !(playerIndex in playerBlobs)) return;
	
	local vectorFromGameCenter = GAME_CENTER - ply.GetOrigin();
	//debugprint("vectorFromGameCenter: " + vectorFromGameCenter);
	//debugprint("vectorFromGameCenter.Length(): " + vectorFromGameCenter.Length().tostring() + " compared to GAME_RADIUS_PLAYERS: " + GAME_RADIUS_PLAYERS.tostring());
	if (ply.GetHealth() > 0 && vectorFromGameCenter.Length() < GAME_RADIUS_PLAYERS && ply.GetOrigin().z < GAME_Z_MAX)
	{
		//debugprint("Leaving player in game because player is still within GAME_RADIUS_PLAYERS of GAME_CENTER");
		return;
	}
	
	DisplayText(ply, "You have exited the game.");
	
	delete playerBlobsToIndices[playerBlobs[playerIndex]];
	if (playerBlobs[playerIndex].IsValid())
	{
		EntFireByHandle(playerBlobs[playerIndex], "Kill", "", 0.0, null, null);
	
	}
	
	
	delete playerActive[playerIndex];
	delete playerBlobs[playerIndex];
	delete playerEntities[playerIndex];
	delete playerRadii[playerIndex];
	delete playerAreas[playerIndex];
	delete maxPlayerAreas[playerIndex];
	delete playerSpeedBoostActive[playerIndex];
	
	RemoveSpeed(ply);
}

function DisplayHelpText()
{
	if (TimerActive) return;
	local playersInGame = false;
	local ply = null;
	while ((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		local playerOrigin = ply.GetOrigin()
		if (playerOrigin.x >= GAME_AREA_MIN.x && playerOrigin.x <= GAME_AREA_MAX.x &&
			playerOrigin.y >= GAME_AREA_MIN.y && playerOrigin.y <= GAME_AREA_MAX.y &&
			playerOrigin.z >= GAME_AREA_MIN.z && playerOrigin.z < GAME_AREA_MAX.z)
		{
			SelectSkin(ply, playerOrigin);
			DisplayText(ply, "Instructions\n1. Look down and run around.\n2. Absorb green orbs and smaller players to gain mass.\n3. Red orbs make you lose mass.\n4. Press use to boost for -10% mass.\n5. If absorbed, you will turn blue and respawn after 5s.\n6. Most mass at the end wins! (Tiebreaker: highest mass achieved.)\n\nSkin Selected: " + SKIN_DISPLAY_NAMES[playerModelChosen[ply.entindex()]]);
			playersInGame = true;
		}
	}
	if (playersInGame && !OtherGameStarted)
	{
		SpawnSkinSprites();
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
	if (OtherGameStarted) KillSkinSprites();
}

SaveString<-function(key, string)
{
	
	local script_scope=SkinSavedEntity.GetScriptScope();
	script_scope[key]<-string;
}

GetString<-function(key)
{
	local script_scope=SkinSavedEntity.GetScriptScope();
	if (key in script_scope)
	{
		return script_scope[key];
	}
	return "0";

}