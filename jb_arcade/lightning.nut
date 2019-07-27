


DEBUG_PRINT <- false;
const MAX_PLAYERS = 64;
const LIGHTNING_LIFETIME = 3.0;
const LIGHTNING_BRANCHES = 5;
const LIGHTNING_COOLDOWN = 10.0;
specialItem<-null;
specialPlayer <- null;
hudtext<-null;
UsedLightningBeamStarts<-{};
NextLightningAvailable<-0.0;
LightningTargetnameTrigger<-null;
PlayerIndexToPlayer<-array(MAX_PLAYERS+1);

debugprint<-function(text)
{
	if (DEBUG_PRINT) printl("*************" + text + "*************")
}

function PickUpSpecialItem() {
	specialItem = caller;
	specialPlayer = activator;
	EntFire("lightning_tesla", "TurnOn", "", 0.0, self);
	if (hudtext == null) {
		hudtext = Entities.FindByName(null, "lightning_text_instructions");
	}
	EntFireByHandle(hudtext,"Display","",0.01,activator,activator);
}

function TryLightning() {
	if (Time() < NextLightningAvailable) {
		return;
	}
	
	if (specialItem != null && (!specialItem.IsValid() || specialItem.GetOwner() != specialPlayer)) {
		specialPlayer = null;
	}
	
	if (specialPlayer == null) {
		return;
	}
	
	local victim = GetClosestPlayers(specialPlayer.GetOrigin(), 1, 1024, specialPlayer, specialPlayer.GetTeam());
	if (victim.len() == 0) return;
	
	NextLightningAvailable = Time() + LIGHTNING_COOLDOWN;

	PlayerIndexToPlayer[specialPlayer.entindex()] = specialPlayer;

	StartLightning(specialPlayer.entindex(), victim[0].index);
}


function StartLightning(startIndex, endIndex)
{
	if (PlayerIndexToPlayer[startIndex] == null || PlayerIndexToPlayer[endIndex] == null) return;
	EntFire("hurt_script", "RunScriptCode", "setAttacker(HURTER_FOUR)", 0.0, PlayerIndexToPlayer[startIndex]);
	EntFire("hurt_script", "RunScriptCode", "setAttacker(HURTER_FIVE)", 0.0, PlayerIndexToPlayer[startIndex]);
	
	EntFire("lightning_template", "ForceSpawn", "", 0.0, null);
	EntFireByHandle(self, "RunScriptCode", "LightningBeam(" + startIndex.tostring() + "," + endIndex.tostring() + ")", 0.05, self, self);
	EntFire("hurt_script", "RunScriptCode", "hurtActivator(HURTER_FOUR)", 0.5, PlayerIndexToPlayer[endIndex]);
	EntFire("lightning_sound_script1", "RunScriptCode", "PlaySoundAtVolume(2)", 0.0, PlayerIndexToPlayer[startIndex]);
	EntFire("lightning_sound_script2", "RunScriptCode", "PlaySoundAtVolume(2)", 0.0, PlayerIndexToPlayer[endIndex]);
	debugprint("Creating lightning between #" + startIndex + " and #" + endIndex);
	
	local playerTeam = PlayerIndexToPlayer[startIndex].GetTeam();
	local endPlayerOrigin = PlayerIndexToPlayer[endIndex].GetOrigin();
	local playersHit = 1;
	local delay = 0.05; //So damage targetnames don't get hosed
	local closestPlayers = GetClosestPlayers(endPlayerOrigin, 4, 512.0, PlayerIndexToPlayer[endIndex], playerTeam);
	foreach (i,playerObject in closestPlayers)
	{
		local ply = PlayerIndexToPlayer[playerObject.index];
		
		debugprint("#" + i + "Creating lightning between #" + endIndex + " and #" + ply.entindex());
		EntFire("lightning_template", "ForceSpawn", "", 0.0, null);
		EntFireByHandle(self, "RunScriptCode", "LightningBeam(" + endIndex + "," + ply.entindex().tostring() + ")", delay, self, self);
		EntFire("hurt_script", "RunScriptCode", "hurtActivator(HURTER_FIVE)", delay+0.1, ply);
		
		delay += 0.05;
		playersHit++;
		if (playersHit >= LIGHTNING_BRANCHES) break;
	}
	DisplayTextLightning(PlayerIndexToPlayer[startIndex], playersHit);
}


function LightningBeam(startIndex, endIndex){
	//find first unused lightning bolt
	beamStart <- null;
	beamEnd <- null;
	while((beamStart = Entities.FindByName(beamStart,"lightning_start*")) != null)
	{
		if (!(beamStart.GetName() in UsedLightningBeamStarts))
		{
			UsedLightningBeamStarts[beamStart.GetName()] <- true;
			//debugprint("beamStart name: " + beamStart.GetName());
			local suffix = beamStart.GetName().slice(15);
			//debugprint("suffix: " + suffix);
			beamEnd = Entities.FindByName(null,"lightning_stop" + suffix);
			//debugprint("beamEnd: " + beamEnd);
			
			if (beamEnd != null) EntFireByHandle(beamEnd, "Kill", "", LIGHTNING_LIFETIME + 0.05, beamEnd, null);
			if (beamStart != null) EntFireByHandle(beamStart, "Kill", "", LIGHTNING_LIFETIME + 0.05, beamStart, null);
			EntFire("lightning_beam", "Kill", "", LIGHTNING_LIFETIME + 0.05, null);
			break;
		}
	}
	if (beamStart == null || beamEnd == null) return;

	local startPlayer = PlayerIndexToPlayer[startIndex];
	local endPlayer = PlayerIndexToPlayer[endIndex];
	if (startPlayer == null || endPlayer == null || !startPlayer.IsValid() || !endPlayer.IsValid()) return;
	local startPlayerOrigin = startPlayer.GetOrigin();
	local endPlayerOrigin = endPlayer.GetOrigin();

	
	DisplayTextLightning(endPlayer, 0);
	
	beamStart.SetOrigin(Vector(startPlayerOrigin.x, startPlayerOrigin.y, startPlayerOrigin.z+50.0));
	EntFireByHandle(beamStart, "SetParent", "!activator", 0.0, startPlayer, null);
	
	beamEnd.SetOrigin(Vector(endPlayerOrigin.x, endPlayerOrigin.y, endPlayerOrigin.z+50.0));
	EntFireByHandle(beamEnd, "SetParent", "!activator", 0.0, endPlayer, null);
}


function DisplayTextLightning(ply, victims)
{
	local game_txt = (victims > 0) ? Entities.FindByName(null, "lightning_text") : Entities.FindByName(null, "lightning_text_attacker");
	if (game_txt != null)
	{
		if (victims > 0) game_txt.__KeyValueFromString("message", "You hit " + victims.tostring() + " players with lightning!");
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