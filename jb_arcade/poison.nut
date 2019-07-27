DEBUG_PRINT <- false;
const MAX_PLAYERS = 64;
const POISON_TICKS = 5;
const POISON_DELAY = 1.0;
const POISON_COOLDOWN = 5.0;
specialItem<-null;
specialPlayer <- null;
hudtext<-null;
NextPoisonAvailable<-0.0;
PlayerIndexToPlayer<-array(MAX_PLAYERS+1, null);
PoisonCounterRemaining<-array(MAX_PLAYERS+1, 0);

debugprint<-function(text)
{
	if (DEBUG_PRINT) printl("*************" + text + "*************")
}

function PickUpSpecialItem() {
	specialItem = caller;
	specialPlayer = activator;
	if (hudtext == null) {
		hudtext = Entities.FindByName(null, "poison_text_instructions");
	}
	EntFireByHandle(hudtext,"Display","",0.01,activator,activator);
}

function TryPoison() {
	if (Time() < NextPoisonAvailable) {
		return;
	}
	
	if (specialItem != null && (!specialItem.IsValid() || specialItem.GetOwner() != specialPlayer)) {
		specialPlayer = null;
	}
	
	if (specialPlayer == null) {
		return;
	}
	
	local victim = GetClosestPlayers(specialPlayer.GetOrigin(), 1, 1024, specialPlayer, specialPlayer.GetTeam());
	debugprint("Poisoning victim: " + victim);
	if (victim.len() == 0) return;
	
	NextPoisonAvailable = Time() + POISON_COOLDOWN;

	PlayerIndexToPlayer[specialPlayer.entindex()] = specialPlayer;

	DoEntFire("hurt_script", "RunScriptCode", "setAttacker(HURTER_THREE)", 0.0, specialPlayer, specialPlayer);
	PoisonPlayer(victim[0].index);
}

function PoisonPlayer(entindex)
{
	local ply = PlayerIndexToPlayer[entindex];
	if (ply == null || !ply.IsValid() || ply.GetHealth() <= 0) {
		PlayerIndexToPlayer[entindex] = null;
		return;
	}
	
	if (PoisonCounterRemaining[entindex] > 0) {
		debugprint("resetting poison counter for " + entindex.tostring() + " to " + POISON_TICKS.tostring());
		PoisonCounterRemaining[entindex] = POISON_TICKS;
		return;
	}
	
	debugprint("starting new poison on " + entindex.tostring());
	PoisonCounterRemaining[entindex] = POISON_TICKS;
	EntFireByHandle(self, "RunScriptCode", "PoisonTick(" + entindex + ")", POISON_DELAY, ply, ply);
}

function PoisonTick(entindex)
{
	if (PoisonCounterRemaining[entindex] <= 0) {
		PoisonCounterRemaining[entindex] = 0;
		return;
	}
	
	PoisonCounterRemaining[entindex] = PoisonCounterRemaining[entindex] - 1;
	local ply = PlayerIndexToPlayer[entindex];
	if (ply == null || ply.GetHealth() <= 0) return;
	
	debugprint("Poison tick on " + ply.entindex().tostring() + " - " + PlayerIndexToPlayer[entindex].tostring());
	//ply.SetHealth(ply.GetHealth() - 5);
	DoEntFire("hurt_script", "RunScriptCode", "hurtActivator(HURTER_THREE)", 0.0, ply, ply);
	DisplayTextPoison(ply);
	EntFireByHandle(self, "RunScriptCode", "PoisonTick(" + entindex + ")", POISON_DELAY, ply, ply);
}

function DisplayTextPoison(ply)
{
	local game_txt = Entities.FindByName(null, "poison_text");
	if (game_txt != null)
	{
		//game_txt.__KeyValueFromString("message", text);
		EntFireByHandle(game_txt,"Display","",0.03,ply,ply);
	}
}

//Lower is better
function ComparePlayersByDistance(playerA,playerB)
{
	//debugprint("comparing player " + playerA.index + " with player " + playerB.index);
	//debugprint("distance: " +playerA.distance+" to "+playerB.distance);
	if      (playerA.distance > playerB.distance) return 1;
    else if (playerA.distance < playerB.distance) return -1;
	return 0;
}

function GetClosestPlayers(origin, maxPlayers, maxDistance, ignorePlayer, ignoreTeam)
{
	local nearbyPlayers = array(65);
	local numPlayers = 0;
	local ply = null;
	while ((ply = Entities.FindByClassnameWithin(ply, "player", origin, maxDistance)) != null)
	{
		if (ply == ignorePlayer || ply.GetTeam() == ignoreTeam || ply.GetHealth() <= 0) continue;
		
		PlayerIndexToPlayer[ply.entindex()] = ply;
		
		local distanceToOrigin = (ply.GetOrigin() - origin).Length();
		//debugprint("found nearby player " + ply + " at distance " + distanceToOrigin.tostring());
		if (distanceToOrigin > maxDistance) continue;
		local plyObject = {index = ply.entindex(), distance = distanceToOrigin};
		nearbyPlayers[numPlayers++] = plyObject;
	}
	
	nearbyPlayers = nearbyPlayers.slice(0, numPlayers);
	nearbyPlayers.sort(ComparePlayersByDistance);
	numPlayers = (maxPlayers < numPlayers) ? maxPlayers : numPlayers;
	
	/*
	local nearbyPlayersSliced = nearbyPlayers.slice(0, numPlayers);
	debugprint("GetClosestPlayers returning:");
	for (local i = 0; i < nearbyPlayersSliced.len(); i++) {
		debugprint("#" + i + ": " + PlayerIndexToPlayer[nearbyPlayersSliced[i].index]);
	}
	*/
	
	return nearbyPlayers.slice(0, numPlayers);
}