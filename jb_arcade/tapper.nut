//===============================
//=====       TAPPER        =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

DEBUG_PRINT<-true
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

NUM_BOOTHS<-4
MAX_SCORE<-999999999
SCORE_PER_TAP<-10
MAX_UPGRADES<-9
MAX_GAME_TIME<-60
MIN_GAME_TIME<-10
WARMUP_TIME<-4
const MAX_PLAYERS = 64;

TapperScoreText<-array(NUM_BOOTHS)
TapperScoreTextOuter<-array(NUM_BOOTHS)
TapperTimeText<-array(NUM_BOOTHS+1)
TapperRankText<-array(NUM_BOOTHS)
TapperPlatform<-array(NUM_BOOTHS)
GameTextEntities<-array(MAX_PLAYERS+1);

scores<-[0,0,0,0]
ranks<-[0,0,0,0]
GameTime<-40;
TimeLeft<-GameTime+WARMUP_TIME;
TimerActive<-false;
BetweenGames<-true;
StartAllowedTime<-0.0;
GameEndedAt<-(-900.0);
score_text<-["$0", "$0", "$0", "$0"];

upgrades<-array(NUM_BOOTHS)
upgrades[0]=[0,0,0,0,0]
upgrades[1]=[0,0,0,0,0]
upgrades[2]=[0,0,0,0,0]
upgrades[3]=[0,0,0,0,0]
upgrades_previous_texture<-array(NUM_BOOTHS)
upgrades_previous_texture[0]=[0,0,0,0,0]
upgrades_previous_texture[1]=[0,0,0,0,0]
upgrades_previous_texture[2]=[0,0,0,0,0]
upgrades_previous_texture[3]=[0,0,0,0,0]
button_upgrades<-array(NUM_BOOTHS)
button_upgrades[0]=[false, false, false]
button_upgrades[1]=[false, false, false]
button_upgrades[2]=[false, false, false]
button_upgrades[3]=[false, false, false]
button_upgrades_previous_texture<-array(NUM_BOOTHS)
button_upgrades_previous_texture[0]=[0,0,0]
button_upgrades_previous_texture[1]=[0,0,0]
button_upgrades_previous_texture[2]=[0,0,0]
button_upgrades_previous_texture[3]=[0,0,0]



UPGRADE_BASE_COST<-[20, 100, 500, 2700, 14250]
UPGRADE_POWER<-[1, 5, 20, 100, 500]
UPGRADE_COST<-array(5)
UPGRADE_COST[0]=[20,23,26,29,33,37,42,48,55,9999999]
UPGRADE_COST[1]=[100,115,132,151,173,198,227,261,300,9999999]
UPGRADE_COST[2]=[500,575,661,760,874,1005,1155,1328,1527,9999999]
UPGRADE_COST[3]=[2700,3105,3570,4105,4720,5428,6242,7178,8254,9999999]
UPGRADE_COST[4]=[14250,16387,18845,21671,24921,28659,32957,37900,43585,9999999]
BUTTON_UPGRADE_COST<-[50, 400, 1000] //decoy, defuse kit, kevlar
BUTTON_UPGRADE_MULTIPLIER<-[2, 4, 4]

RANK_TEXTS<-["1st Place", "2nd Place", "3rd Place", "4th Place"];
COLOR_WHITE<-"255 255 255";
COLOR_RED<-"255 1 1";
COLOR_GREEN<-"1 255 1";

SCORE_POSITIONS<-array(NUM_BOOTHS)
SCORE_POSITIONS[0]=Vector(4033,1292,-96)
SCORE_POSITIONS[1]=Vector(4033,1516,-96)
SCORE_POSITIONS[2]=Vector(4033,1740,-96)
SCORE_POSITIONS[3]=Vector(4033,1964,-96)
SCORE_POSITIONS_OUTER<-array(NUM_BOOTHS)
SCORE_POSITIONS_OUTER[0]=Vector(4257,1292,-155)
SCORE_POSITIONS_OUTER[1]=Vector(4257,1516,-155)
SCORE_POSITIONS_OUTER[2]=Vector(4257,1740,-155)
SCORE_POSITIONS_OUTER[3]=Vector(4257,1964,-155)

BOOTH_AREA_MIN <- Vector(4032.0, 1200.0, -161.0);
BOOTH_AREA_MAX <- Vector(4255.0, 2064.0, 90.0);

RANDOMIZER_AREA_MIN <- Vector(4000.0, 864.0, -161.0);
RANDOMIZER_AREA_MAX <- Vector(4256.0, 1168.0, 96.0);
const PLAYER_WIDTH_HALF = 16.0;
TAPPER_LOCATIONS <- array(4);

//For debug purposes
function SetScorePerTap(scorePerTap)
{
	SCORE_PER_TAP = scorePerTap
}

function OnPostSpawn() //Called after the logic_script spawns
{
	EntFireByHandle(self, "RunScriptCode", "Setup()", 0.5, null, null)
}

function Setup()
{
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		GameTextEntities[i] = Entities.FindByName(null,"display_score_" + i);
	}
	for (local i = 1; i <= 4; i++) {
		TAPPER_LOCATIONS[i-1] = Entities.FindByName(null,"tapper_teleport" + i).GetOrigin();
	}
}

function AddToTapperScore(booth,amount,automatic)
{
	adjusted_amount <- amount
	
	//Don't multiply amount for purchases
	if (amount > 0)
	{
		adjusted_amount <- adjusted_amount * SCORE_PER_TAP
	}
	
	//Adjust by multiplier if this is a manual button press
	if (!automatic)
	{
		for (local upgrade = 0; upgrade <= 2; upgrade++)
		{
			if (button_upgrades[booth][upgrade])
			{
				adjusted_amount *= BUTTON_UPGRADE_MULTIPLIER[upgrade]
			}
		}
	}
	//Add to the score
	scores[booth] += adjusted_amount
	
	//Bound score at 0 <= score <= MAX_SCORE
	if (scores[booth] < 0)
	{
		scores[booth] = 0
	}
	if (scores[booth] > MAX_SCORE)
	{
		scores[booth] = MAX_SCORE
	}
	
	//Display score for booth
	//DisplayTapperScore(booth)
	DisplayTapperScoreText(booth, scores[booth])
	
	
	//Update buttons in case an upgrade is now available
	for (local upgrade = 0; upgrade <= 4; upgrade++)
	{
		DisplayUpgrade(booth,upgrade)
	}
	for (local upgrade = 0; upgrade < 3; upgrade++)
	{
		DisplayButtonUpgrade(booth, upgrade)
	}
}

//ent_fire tapper_script runscriptcode "SetTapperScore(0,100000000)
function SetTapperScore(booth,amount)
{
	scores[booth] = amount
}

function BuyTapperUpgrade(booth,upgrade)
{
	if (CanAffordUpgrade(booth,upgrade))
	{
		AddToTapperScore(booth, -GetCostOfUpgrade(booth,upgrade), true)
		upgrades[booth][upgrade]++
		debugprint("Booth " + booth.tostring() + " bought upgrade " + upgrade.tostring() + " (total: " + upgrades[booth][upgrade].tostring() + ")")
		DisplayUpgrade(booth,upgrade)

		return
	}
	debugprint("Booth " + booth.tostring() + " was unable to buy upgrade " + upgrade.tostring() + " ($" + scores[booth].tostring() + " available)")
}

function BuyTapperButtonUpgrade(booth,upgrade)
{
	if (CanAffordButtonUpgrade(booth, upgrade))
	{
		AddToTapperScore(booth, -BUTTON_UPGRADE_COST[upgrade], true)
		button_upgrades[booth][upgrade] = true
		DisplayButtonUpgrade(booth, upgrade)
	}
}

function CanAffordUpgrade(booth,upgrade)
{
	return scores[booth] >= GetCostOfUpgrade(booth,upgrade) && upgrades[booth][upgrade] < MAX_UPGRADES
}

function CanAffordButtonUpgrade(booth,upgrade)
{
	return scores[booth] >= BUTTON_UPGRADE_COST[upgrade] && !button_upgrades[booth][upgrade];
}

function GetCostOfUpgrade(booth,upgrade)
{
	return UPGRADE_COST[upgrade][upgrades[booth][upgrade]]
}

function AutoTap()
{
	if (!TimerActive) return;
	for (local booth = 0; booth < NUM_BOOTHS; booth++)
	{
		local boothTaps = 0
		for (local upgrade = 0; upgrade < 5; upgrade++)
		{
			boothTaps += upgrades[booth][upgrade] * UPGRADE_POWER[upgrade]
		}
		if (boothTaps > 0)
		{
			AddToTapperScore(booth, boothTaps, true)
		}
	}
}
//1: 0
//2: 5
//3: 10

function SetButtonLockState(state)
{
	DoEntFire("tapper_tap*", state, "", 0.0, null, null);
	DoEntFire("tapper_tap_upgrade*", state, "", 0.0, null, null);
	DoEntFire("tapper_tap_buttonupgrade*", state, "", 0.0, null, null);
}

function ClearTapperScoreTexts()
{
	for (local i = 0; i < NUM_BOOTHS; i++)
	{
		DisplayTapperScoreText(i, "");
		DisplayRank(i, -1);
	}
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

function SetGameTime(time)
{
	GameTime = time;
}

function ResetTime()
{
	StartAllowedTime<-Time()+1.0;
	//debugprint("StartAllowedTime set to: " + StartAllowedTime);
	EndGame(false);
	BetweenGames = true;
	TimeLeft = GameTime + WARMUP_TIME;
	SetTimerSeconds(GameTime);
	for (local booth = 0; booth < NUM_BOOTHS; booth++)
	{
		upgrades[booth]=[0,0,0,0,0]
		button_upgrades[booth]=[false,false,false];
		AddToTapperScore(booth,-MAX_SCORE,true);
	}
	ClearTapperScoreTexts();
	ResetPlatforms();
}

function StartTimer()
{
	if (TimerActive || TimeLeft <= 0 || Time() < StartAllowedTime) return;
	BetweenGames = false;
	TimerActive = true;
	DoEntFire("tapper_script", "RunScriptCode", "TimerTick()", 1.0, null, null);
	ranks<-[0,0,0,0];
}

function TimerTick()
{
	if (!TimerActive) return;
	TimeLeft--;
	if (TimeLeft > 0)
	{
		DoEntFire("tapper_script", "RunScriptCode", "TimerTick()", 1.0, null, null);
		if (TimeLeft == GameTime)
		{
			//Warmup is over, start the game!
			DoEntFire("tapper_autotapper", "Enable", "", 0.0, null, null);
			SetButtonLockState("Unlock");
			SetTimerTextAll("TAP!", COLOR_GREEN);
			DoEntFire("tapper_start_sound", "PlaySound", "4", 0.0, null, null);
		}
		else if (TimeLeft > GameTime)
		{
			SetTimerTextAll(" " + (TimeLeft - GameTime).tostring() + "!", COLOR_RED);
			DoEntFire("tapper_warmup_sound", "PlaySound", "4", 0.0, null, null);
		}
		else
		{
			SetTimerSeconds(TimeLeft);
		}
	}
	else
	{
		SetTimerSeconds(TimeLeft);
		GameEndedAt = Time();
		EndGame(true);
	}
}

function EndGame(rankPlayers)
{
	TimerActive = false;
	SetButtonLockState("Lock");
	DoEntFire("tapper_autotapper", "Disable", "", 0.0, null, null);
	if (rankPlayers)
	{
		RankPlayers();
	}
}

function RankPlayers()
{
	
	local scoresCopy = [scores[0], scores[1], scores[2], scores[3]];
	local rankedBooths = {};
	rank<-[0,0,0,0];
	
	for (local rank = 0; rank < NUM_BOOTHS; rank++)
	{
		//debugprint("Starting rank " + rank);
		local currentMax = -1;
		currentBooths <- {};
		local boothsInRank = 0;
		for (local booth = 0; booth < NUM_BOOTHS; booth++)
		{
			if (scoresCopy[booth] > currentMax)
			{
				//debugprint("Booth " + booth + " has current max for this rank (" + scoresCopy[booth] + ">" + currentMax + ")");
				currentBooths.clear();
				currentBooths[0] <- booth;
				boothsInRank = 1;
				currentMax = scoresCopy[booth];
			}
			else if (scoresCopy[booth] == currentMax)
			{
				//debugprint("Booth " + booth + " ties current max for this rank (" + scoresCopy[booth] + "==" + currentMax + ")");
				currentBooths[boothsInRank] <- booth;
				boothsInRank++;
			}
		}
		rankedBooths[rank] <- currentBooths;
		//debugprint("boothsInRank: " + boothsInRank + ", currentBooths.len(): " + currentBooths.len());
		for (local boothIndex = 0; boothIndex < boothsInRank; boothIndex++)
		{
			local booth = rankedBooths[rank][boothIndex];
			scoresCopy[booth] = -999999
			debugprint("Booth " + booth + " has rank " + (rank + 1).tostring() + " with score " + scores[booth]);
			if (booth >= NUM_BOOTHS) continue;
			DisplayRank(booth, rank);
			MovePlatform(booth, rank);
			ranks[booth]=rank;
		}
	}
	
}

function DisplayRank(booth, rank)
{
	if (TapperRankText[booth] == null)
	{
		TapperRankText[booth] = Entities.FindByName(null, "tapper_rank_text" + booth);
	}
	local text = (rank < 0) ? "" : RANK_TEXTS[rank];
	TapperRankText[booth].__KeyValueFromString("message", text);
}

function ResetPlatforms()
{
	for (local booth = 0; booth < NUM_BOOTHS; booth++)
	{
		if (TapperPlatform[booth] == null)
		{
			TapperPlatform[booth] = Entities.FindByName(null, "tapper_platform" + booth);
		}
		EntFireByHandle(TapperPlatform[booth], "SetSpeed", "256", 0.0, null, null)
		MovePlatform(booth, 4);
		EntFireByHandle(TapperPlatform[booth], "SetSpeed", "64", 0.95, null, null)
	}
}

function MovePlatform(booth, rank)
{
	if (TapperPlatform[booth] == null)
	{
		TapperPlatform[booth] = Entities.FindByName(null, "tapper_platform" + booth);
	}
	TapperPlatform[booth].__KeyValueFromInt("movedistance", 192 - (rank * 64));
	EntFireByHandle(TapperPlatform[booth], "SetPosition", (1.0 - (rank.tofloat() / 4.0)).tostring(), 0.1, null, null)
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
	for (local i = 0; i < NUM_BOOTHS+1; i++)
	{
		SetTimerText(i, text, color);
	}
}

function SetTimerText(booth, text, color)
{
	if (TapperTimeText[booth] == null)
	{
		TapperTimeText[booth] = Entities.FindByName(null, "tapper_timer_text" + booth);
	}
	TapperTimeText[booth].__KeyValueFromString("message", text);
	TapperTimeText[booth].__KeyValueFromString("color", color);
}

function DisplayTapperScoreText(booth, text)
{
	//Cache entity
	if (TapperScoreText[booth] == null)
	{
		TapperScoreText[booth] = Entities.FindByName(null, "tapper_score" + booth);
	}
	if (TapperScoreTextOuter[booth] == null)
	{
		TapperScoreTextOuter[booth] = Entities.FindByName(null, "tapper_score_outer" + booth);
	}
	
	//Add commas
	local scoreWithCommas = "";
	local remainingScore = text.tostring();
	while (remainingScore.len() > 0)
	{
		if (remainingScore.len() < 3)
		{
			scoreWithCommas = remainingScore + scoreWithCommas;
			remainingScore = "";
		}
		else
		{
			scoreWithCommas = remainingScore.slice(remainingScore.len() - 3) + scoreWithCommas;
			remainingScore = remainingScore.slice(0, remainingScore.len() - 3);
		}
		if (remainingScore.len() > 0)
		{
			scoreWithCommas = "," + scoreWithCommas;
		}
		else
		{
			scoreWithCommas = "$" + scoreWithCommas;
		}
	}
	
	
	//Set Text
	TapperScoreText[booth].__KeyValueFromString("message", scoreWithCommas);
	TapperScoreTextOuter[booth].__KeyValueFromString("message", scoreWithCommas);
	score_text[booth] = scoreWithCommas;
	
	//Reposition (if necessary)
	local yoffset = (scoreWithCommas.len()) * 3;
	local scorePosition = Vector(SCORE_POSITIONS[booth].x, SCORE_POSITIONS[booth].y - yoffset, SCORE_POSITIONS[booth].z);
	TapperScoreText[booth].SetOrigin(scorePosition);
	scorePosition = Vector(SCORE_POSITIONS_OUTER[booth].x, scorePosition.y, SCORE_POSITIONS_OUTER[booth].z);
	TapperScoreTextOuter[booth].SetOrigin(scorePosition);
}


function DisplayUpgrade(booth,upgrade)
{
	//Update button texture
	textureindex <- upgrades[booth][upgrade] * 2 + (CanAffordUpgrade(booth,upgrade) ? 1 : 0)
	if (textureindex == upgrades_previous_texture[booth][upgrade]) return;
	upgrades_previous_texture[booth][upgrade] = textureindex
	texturetoggle <- Entities.FindByName(null,"tapper_texturetoggle_upgrade" + upgrade.tostring() + "_" + booth.tostring())
	EntFireByHandle(texturetoggle, "SetTextureIndex", textureindex.tostring(), 0, null, null)
}

function DisplayButtonUpgrade(booth,upgrade)
{
	//Update button texture
	textureindex <- button_upgrades[booth][upgrade] ? 2 : (CanAffordButtonUpgrade(booth,upgrade) ? 1 : 0)
	if (textureindex == button_upgrades_previous_texture[booth][upgrade]) return;
	button_upgrades_previous_texture[booth][upgrade] = textureindex
	texturetoggle <- Entities.FindByName(null,"tapper_texturetoggle_buttonupgrade" + upgrade.tostring() + "_" + booth.tostring())
	EntFireByHandle(texturetoggle, "SetTextureIndex", textureindex.tostring(), 0, null, null)
}

function IsPlayerInBooth(playerOrigin)
{
	return (playerOrigin.x >= BOOTH_AREA_MIN.x && playerOrigin.x <= BOOTH_AREA_MAX.x &&
			playerOrigin.y >= BOOTH_AREA_MIN.y && playerOrigin.y <= BOOTH_AREA_MAX.y &&
			playerOrigin.z >= BOOTH_AREA_MIN.z && playerOrigin.z < BOOTH_AREA_MAX.z);
}

function GetPlayerBooth(ply)
{
	local playerOrigin = ply.GetOrigin();
	local gameY = playerOrigin.y - BOOTH_AREA_MIN.y;
	local boothRatio = gameY / (BOOTH_AREA_MAX.y - BOOTH_AREA_MIN.y);
	local booth = boothRatio * 4.0;
	//debugprint("booth: " + booth.tointeger());
	return booth.tointeger();
}

function DisplayScoresHudText(ply)
{
	local text = "";
	local playerBooth = GetPlayerBooth(ply);
	for (local booth = 0; booth < 4; booth++)
	{
		if (scores[booth] == 0)
		{
			score_text[booth] = "$0";
		}
		
		if (booth == playerBooth)
		{
			text += "YOU - ";
		}
		else
		{
			text += "TEAM " + (booth + 1) + " - ";
		}
		text += score_text[booth] + " (";
		text += (RANK_TEXTS[ranks[booth]]) + ")\n";
	}
	DisplayText(ply, text);
}

function DisplayHelpText()
{
	if (TimerActive) return;
	local ply = null;
	while ((ply = Entities.FindByClassname(ply, "player")) != null)
	{
		local playerOrigin = ply.GetOrigin();
		if (ply.GetHealth() > 0 && IsPlayerInBooth(ply.GetOrigin()))
		{
			if (Time() < GameEndedAt + 20.0)
			{
				DisplayScoresHudText(ply);
			}
			else
			{
				DisplayText(ply, "Instructions\n1. Tap your use key while looking at the $ button to gain money.\n2. Buy upgrades on the left and right.\n3. Left upgrades tap for you.\n4. Right upgrades improve your own tapping.\n5. Whoever has the most money wins!");
			}
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

function RandomizePlayers()
{
	if (!BetweenGames) return;
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
	debugprint("NUM_TEAMS: " + NUM_TEAMS);

	local location = 0;
	while (players.len() > 0)
	{
		local playerIndex = RandomInt(0, players.len() - 1);
		local ply = players[playerIndex];
		players.remove(playerIndex);
		ply.SetOrigin(TAPPER_LOCATIONS[location++]);
		if (location >= NUM_TEAMS)
		{
			location = 0;
		}
	}
}

/*
function DisplayTapperScore(booth)
{
	remainingScore <- scores[booth]
	digits <- CountDigits(scores[booth])
	local yoffset = (digits - 1) * 5
	currentPosition <- Vector(SCORE_POSITIONS[booth].x, SCORE_POSITIONS[booth].y - yoffset, SCORE_POSITIONS[booth].z)
	dollar_sign <- false
	for (local digit = 0; digit < 7; digit++)
	{
		local currentDigit = remainingScore % 10
		local noRemainingDigits = (digit > 6 || (digit > 0 && remainingScore <= 0))
		if (noRemainingDigits && !dollar_sign)
		{
			dollar_sign = true
			currentDigit = 99 //dollar sign sprite code
		}
		DisplayDigitAt(currentDigit, 0.5, 255, 255, 255, currentPosition, noRemainingDigits)
		remainingScore = remainingScore / 10
		debugprint("Remaining Score " + remainingScore.tostring() + ", noRemainingDigits " + noRemainingDigits.tostring())
		currentPosition.y = currentPosition.y + 10
	}
}

function RemoveScore(booth)
{
	local position = Vector(SCORE_POSITIONS[booth].x, SCORE_POSITIONS[booth].y, SCORE_POSITIONS[booth].z)
	sprite <- null
	while ((sprite = Entities.FindByClassnameWithin(sprite, "env_sprite_oriented", position, 40.0)) != null)
	{
		debugprint("Deleting sprite " + sprite)
		EntFireByHandle(sprite, "kill", "", 0, null, null)
	}
}

function CountDigits(number)
{
	local digits = 0
	while (digits <= 6 && number > 0)
	{
		number = number / 10
		digits++
	}
	return digits + 1
}

function DeleteSprite(position)
{
	sprite <- null
	while ((sprite = Entities.FindByClassnameWithin(sprite, "env_sprite_oriented", position, 0.5)) != null)
	{
		EntFireByHandle(sprite, "kill", "", 0, null, null)
	}

}
function SpawnNumberSprite(position, size, r, g, b, number)
{
	env_entity_maker <- null
	env_entity_maker <- Entities.FindByName(env_entity_maker,"tapper_sprite_maker" + number.tostring())
	debugprint("Found entity maker " + env_entity_maker + " for tapper_sprite_maker" + number.tostring())
	env_entity_maker.SpawnEntityAtLocation(position,Vector(0,0,0));
	local sprite = Entities.FindByNameWithin(null,"tapper_sprite" + number.tostring(),position,0.5);
	debugprint("Created sprite " + "tapper_sprite" + number.tostring() + ":" + sprite + " at (" + position.x + "," + position.y + "," + position.z + ")")
	if (sprite != null)
	{
		sprite.__KeyValueFromFloat("scale", size);
		sprite.__KeyValueFromInt("rendermode",9);
		sprite.__KeyValueFromInt("renderamt",255);
		sprite.__KeyValueFromString("rendercolor","" + r + " " + g + " " + b);
	}
	return sprite
}

function DisplayDigitAt(number, size, r, g, b, position, noRemainingDigits)
{
	if (number > 0 || !noRemainingDigits)
	{
		SpawnNumberSprite(position, size, r, g, b, number)
	}
}
*/