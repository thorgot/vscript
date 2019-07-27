//===============================
//=====       TIMER         =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

::DEBUG_PRINT<-true;
::debugprint<-function(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

::MAX_PLAYERS<-64;
::winners<-0;
::StartTime<-array(65);
::EndTime<-array(65);

::BestTimes<-[0.0, 0.0, 0.0];
::BestTimeTextEntities<-[null, null, null];
::BestTimeTextEntityOffset <- 3;
::difficulty<-0;
::BestTimePrefix <- "BEST_TIME_";
::MaxZ <- null;

::IsPlayerInGame<-array(65);
::playerEntities<-array(65);

GameTextEntities<-array(MAX_PLAYERS+1);

function Precache()
{
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		GameTextEntities[i] = Entities.FindByName(null,"display_score_" + i);
		StartTime[i] = 0.0;
	}
}

StartTimer<-function()
{
	if (activator != null)
	{
		StartTime[activator.entindex()] = Time();
		EndTime[activator.entindex()] = 0.0;
		debugprint("start time: " + StartTime[activator.entindex()]);
	}
}

EndTimer<-function()
{
	local playerIndex = activator.entindex();
	EndTime[playerIndex] = Time();
	if (activator != null && winners <= 2)
	{
		local totalTime = EndTime[playerIndex] - StartTime[playerIndex];
		debugprint("total time for winner " + winners + ": " + totalTime);
		
		//Set visual time for 1st, 2nd and 3rd place
		if (winners <= 2)
		{
			EntityGroup[winners].__KeyValueFromString("message", totalTime.tostring() + "s");
		}
		
		//Set overall record for map
		if (BestTimes[difficulty] < 0.1 || totalTime < BestTimes[difficulty])
		{
			BestTimes[difficulty] = totalTime;
			SaveString(BestTimePrefix + difficulty.tostring(), totalTime.tostring());
			debugprint("new record " + totalTime + " for difficulty " + difficulty);
			UpdateTimeTextEntity(difficulty);
		}
	}
	DisplayGameInformationToPlayer(playerIndex, true);
	winners++;
}

SetWinners<-function(val)
{
	winners = val;
}

SetDifficulty<-function(diff)
{
	difficulty = diff;
}

InitializeBestTimes<-function()
{
	for (local diff = 0; diff < 3; diff++)
	{
		BestTimeTextEntities[diff] = EntityGroup[BestTimeTextEntityOffset + diff];
		BestTimes[diff] = GetString(BestTimePrefix + diff.tostring()).tofloat();
		debugprint("retrieved time " + BestTimes[diff] + " for difficulty " + diff);
		if (BestTimes[diff] > 0.1)
		{
			UpdateTimeTextEntity(diff);
		}
	}
}

UpdateTimeTextEntity <- function(diff)
{
	if (EntityGroup[BestTimeTextEntityOffset + diff] != null)
	{
		EntityGroup[BestTimeTextEntityOffset + diff].__KeyValueFromString("message", BestTimes[diff].tostring() + "s");
	}
}

SaveString<-function(key, string)
{
	
	local script_scope=EntityGroup[10].GetScriptScope();
	script_scope[key]<-string;
}

GetString<-function(key)
{
	local script_scope=EntityGroup[10].GetScriptScope();
	if (key in script_scope)
	{
		return script_scope[key];
	}
	return "0.0";

}

DisplayGameInformation<-function()
{
	local players = 0;
	for (local playerIndex = 0; playerIndex <= MAX_PLAYERS; playerIndex++)
	{
		players += DisplayGameInformationToPlayer(playerIndex, false);
	}
	
	if (players == 0)
	{
		EntFire("surf_timer_timer", "Disable", "", 0.0, null);
	}
}

DisplayGameInformationToPlayer<-function(playerIndex, wonGame)
{
	if (playerEntities[playerIndex] == null ||
	    !playerEntities[playerIndex].IsValid() ||
	    playerEntities[playerIndex].GetHealth() <= 0 ||
	   (!wonGame && MaxZ != null && playerEntities[playerIndex].GetOrigin().z > MaxZ)) return 0;
	//debugprint("start time for player " + playerIndex + " is " + StartTime[playerIndex]);
	//debugprint("end time for player " + playerIndex + " is " + EndTime[playerIndex]);
	local endTime = (EndTime[playerIndex] > 0.0) ? (EndTime[playerIndex] - StartTime[playerIndex]) : (Time() - StartTime[playerIndex]).tointeger();

	
	score_text <- "Time: " + endTime.tostring() + "s";
	GameTextEntities[playerIndex].__KeyValueFromString("message", score_text);
	EntFireByHandle(GameTextEntities[playerIndex],"Display","",0.1,playerEntities[playerIndex],playerEntities[playerIndex]);

		
	return 1;
}

SetPlayerInGame<-function(inGame)
{
	local playerIndex = activator.entindex();
	IsPlayerInGame[playerIndex] = inGame;
	
	if (inGame)
	{
		playerEntities[playerIndex] = activator;
		DisplayGameInformationToPlayer(playerIndex, false);
		activator.GetScriptScope().inGame <- true;
	}
	else
	{
		activator.GetScriptScope().inGame <- false;
		playerEntities[playerIndex] = null;
	}
}

SetMaxZ<-function(z)
{
	MaxZ = z;
}