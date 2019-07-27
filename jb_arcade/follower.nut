//===============================
//=====      FOLLOWER       =====
//=====      BY             =====
//=====      THORGOT        =====
//===============================

NextTickTime<-0.0;
TIME_BETWEEN_TICKS<-0.5;
CurrentTarget <- null;
Stopped <- true;

TrainEntity <- null;
TrackEntityA <- null;
TrackEntityB <- null;

const MAX_DISTANCE_TO_FOLLOW = 128.0;
const TEAM_TERRORIST = 2;
const TEAM_CT = 3;

DEBUG_PRINT<-true;
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function Think()
{
	if (Time() < NextTickTime) return;
	NextTickTime = Time() + TIME_BETWEEN_TICKS;
	
	
	if (CurrentTarget == null || !CurrentTarget.IsValid() || CurrentTarget.GetHealth() <= 0) {
		debugprint("Setting new target");
		setNewRandomTarget();
		if (TrainEntity == null || !TrainEntity.IsValid()) return;
		EntFireByHandle(TrainEntity, "Stop", "", 0.0, TrainEntity, TrainEntity);
		Stopped = true;
		return;
	}
	if (Stopped ) {
		if (TrainEntity == null || !TrainEntity.IsValid()) return;
		if (GetDistanceFromTrainToTarget() < MAX_DISTANCE_TO_FOLLOW) return;
		EntFireByHandle(TrainEntity, "StartForward", "", 0.0, TrainEntity, TrainEntity);
		Stopped = false;
	}
	
	if (TrainEntity == null || !TrainEntity.IsValid()) return;
	//debugprint("moving train to target " + CurrentTarget);
	moveTrack(CurrentTarget);
}

function chooseRandomFollower() {
	local random = RandomInt(1, 2).tostring();
	EntFire("follower_sprite" + random, "Kill", "", 0.0, null);
}

function setNewRandomTarget() {
	if (TrainEntity == null) {
		TrainEntity = Entities.FindByName(null, "follower_train");
	}
	if (TrackEntityA == null) {
		TrackEntityA = Entities.FindByName(null, "follower_track1");
	}
	if (TrackEntityB == null) {
		TrackEntityB = Entities.FindByName(null, "follower_track2");
	}
	
	CurrentTarget = getRandomLivingPlayer();
	debugprint("new target: " + CurrentTarget);
}

function getRandomLivingPlayer() {
	local plys = [];
	local ply = null;
	while((ply = Entities.FindByClassname(ply, "player")) != null) {
		if (ply.GetHealth() <= 0) continue;
		if (ply.GetTeam() != TEAM_CT && ply.GetTeam() != TEAM_TERRORIST) continue;
		
		plys.push(ply);
	}
	
	if (plys.len() == 0) return null;
	
	local plysIndex = RandomInt(0, plys.len()-1);
	//debugprint("Returning otherplys[" + otherplysIndex + "] which is " + otherplys[otherplysIndex]);
	return plys[plysIndex];
	
}

//For testing
function moveTrackActivator() {
	moveTrack(activator);
}

function GetDistanceFromTrainToTarget() {
	if (CurrentTarget == null || TrainEntity == null) return 0.0;
	
	local vectorDifference = TrainEntity.GetOrigin() - CurrentTarget.GetOrigin();
	return vectorDifference.Length();
}

function moveTrack(target) {
	if (target == null) return;
	
	if (TrainEntity == null || !TrainEntity.IsValid()) return;
	
	if (GetDistanceFromTrainToTarget() < MAX_DISTANCE_TO_FOLLOW) {
		EntFireByHandle(TrainEntity, "Stop", "", 0.0, TrainEntity, TrainEntity);
		Stopped = true;
		return;
	}
	
	local targetOrigin = target.GetOrigin();
	TrackEntityA.SetOrigin(TrainEntity.GetOrigin());
	TrackEntityB.SetOrigin(Vector(targetOrigin.x, targetOrigin.y, targetOrigin.z+30.0));

}