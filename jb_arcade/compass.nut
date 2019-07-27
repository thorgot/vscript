//===============================
//=====      COMPASS SECRET =====
//=====      BY             =====
//=====      THORGOT        =====
//===============================

item<-null;
needle<-null;
compass<-null;
hudtext<-null;
DEBUG<-false;
MAIN_LOBBY<-[Vector(1152.0, -612.0, 0.0), Vector(3648.0, 800.0, 0.0)];
CELLS_AREA<-[Vector(-564.0, -564.0, 0.0), Vector(448.0, 504.0, 0.0)];
SPRITE_ROOM<-[Vector(1536.0, -2287.0, 0.0), Vector(3072.0, -800.0, 0.0)];
DISCO<-[Vector(3712.0, -736.0, 0.0), Vector(5760.0, 800.0, 0.0)];
TAPPER<-[Vector(4000.0, 864.0, 0.0), Vector(4736.0, 2400.0, 0.0)];
DECATHLON<-[Vector(1152.0, 2528.0, 0.0), Vector(3136.0, 4512.0, 0.0)];
BEE<-[Vector(1152.0, 864.0, 0.0), Vector(3936.0, 2400.0, 0.0)];
CLIMB_A<-[Vector(3712.0, -2848.0, 0.0), Vector(4672.0, -800.0, 0.0)];
CLIMB_B<-[Vector(4672.0, -1824.0, 0.0), Vector(5760.0, -800.0, 0.0)];
ROOMS<-[MAIN_LOBBY, CELLS_AREA, SPRITE_ROOM, DISCO, TAPPER, DECATHLON, BEE, CLIMB_A, CLIMB_B];
currentTarget<-null;
currentTargetRoom<-9999;
atTarget<-false;
targetsInspected<-0;
questOver<-false;
TOTAL_TARGETS <- 1;
PI<-3.14;
secondsAtTarget <- 0;

DEBUG_PRINT<-false;
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function registerItem()
{
	if (item == null)
	{
		item = Entities.FindByName(null, "secret_compass_c4");
		debugprint("Found item: " + item)
	}
	if (needle == null)
	{
		needle = Entities.FindByName(null, "secret_compass_needle");
		debugprint("Found needle: " + needle)
	}
	if (compass == null)
	{
		compass = Entities.FindByName(null, "secret_compass_base");
		debugprint("Found compass: " + compass)
	}
	
	if (currentTarget == null)
	{
		chooseNewTarget();
	}
	hudtext = Entities.FindByName(null, "secret_compass_text");
	
}

function chooseNewTarget()
{
	local roomNumber = RandomInt(0, ROOMS.len() - 2);
	if (roomNumber >= currentTargetRoom) roomNumber++; //ignore current room
	currentTargetRoom = roomNumber;
	currentTarget = Vector(RandomFloat(ROOMS[currentTargetRoom][0].x, ROOMS[currentTargetRoom][1].x), RandomFloat(ROOMS[currentTargetRoom][0].y, ROOMS[currentTargetRoom][1].y), 0.0);
	debugprint("Set target to " + currentTarget + ", a point in room " + roomNumber);
}

function triggerLocation()
{
	if (item == null || !item.IsValid() || item.GetOwner() == null || !atTarget || questOver) return;
	targetsInspected++;
	debugprint("Compass holder inspected their weapon at the target, targetsInspected = " + targetsInspected);
	if (targetsInspected >= TOTAL_TARGETS)
	{
		questOver = true;
		compass.__KeyValueFromInt("skin", 0);
		DoEntFire("secret_compass_timer", "Kill", "", 0, null, self);
		DoEntFire("secret_compass_needle", "Kill", "", 0, null, self);
		local env_entity_maker = Entities.FindByName(null, "rocketjump_entity_maker");
		local spawnLocation = item.GetOwner().GetOrigin();
		spawnLocation.z += 32.0;
		env_entity_maker.SpawnEntityAtLocation(spawnLocation,Vector(0,0,0));
		debugprint("spawning rocketjump shotgun at " + spawnLocation);
	}
	else
	{
		chooseNewTarget();
	}
}

function checkIfAtTarget()
{
	if (compass == null || item == null || item.GetOwner() == null) return;
	local originXY = compass.GetOrigin();
	originXY.z = 0;
	//debugprint("Distance is " + (originXY - currentTarget).LengthSqr());
	if ((originXY - currentTarget).LengthSqr() <= 4096.0) //64^2
	{
		if (!atTarget) {
			atTarget = true;
			//debugprint("Now at target!");
			compass.__KeyValueFromInt("skin", 1);
		}
		secondsAtTarget += 0.1;
	}
	else
	{
		secondsAtTarget = 0;
		if (atTarget) {
			compass.__KeyValueFromInt("skin", 0);
			//debugprint("Left target!");
			atTarget = false;
		}
	}
	
}

function pickup()
{
	if (!questOver) {
		EntFireByHandle(hudtext,"Display","",0.01,activator,activator);
	}
}

function yawFromVector(vector)
{
	return atan2(vector.x, -vector.y);
}

function getYawBetweenPoints(start, end)
{
	//debugprint("start location " + start);
	//debugprint("target location " + end);
	local yawInRads = yawFromVector(start - end) + (PI/2.0);
	//debugprint("yawInRads " + yawInRads);
	local targetYawInDegrees = yawInRads/PI*180.0
	//debugprint("target yaw: " + targetYawInDegrees);
	local yawInDegrees = targetYawInDegrees - compass.GetAngles().y;
	//debugprint("yawInDegrees: " + yawInDegrees);
	return yawInDegrees;
}

function adjustNeedle()
{
	if (item != null && item.GetOwner() != null)
	{
		local yawInDegrees = getYawBetweenPoints(needle.GetOrigin(), currentTarget);
		needle.SetAngles(0.0, yawInDegrees, 0.0);
		checkIfAtTarget();
		if (secondsAtTarget >= 3) {
			secondsAtTarget = 0;
			triggerLocation();
		}
	}
	
}

function setNeedle(yaw)
{
	if (needle != null)
	{
		//debugprint("Set needle yaw to " + yaw)
		needle.SetAngles(0.0, yaw, 0.0)
	}
}