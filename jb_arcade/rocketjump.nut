
DEBUG<-false

item_ent<-null;
special_player<-null
shot_direction_ent<-null
player_last_shot<-0
sound_ent<-null;

LastShot<-0;
LastRocket<-0;

const BOOST = 600.0;

ROCKET_DEBUG <- false;

debugprint<-function(text)
{
	if (ROCKET_DEBUG) printl("*************" + text + "*************")
}

//Scales a vector
Scale<-function(v, scalar)
{
	local len = v.Length();
	if (len == 0)
	{
		return v;
	}
	return Vector(v.x*scalar/len,v.y*scalar/len,v.z*scalar/len);
}

SetRocketJumper<-function()
{
	item_ent = caller;
	
	special_player=activator
	if (shot_direction_ent == null)
	{
		shot_direction_ent = Entities.FindByName(null,"rocketjump_origin")
		//debugprint("Found shot direction entity: " + shot_direction_ent)
	}
	if (sound_ent == null)
	{
		sound_ent = Entities.FindByName(null,"rocketjump_sound")
	}
	//debugprint("special_player is now " + special_player)
}


RocketJump<-function()
{
	if (activator == null) return;
	
	//If the shotgun was thrown or stripped, don't do anything
	if(activator == null || item_ent == null || !item_ent.IsValid() || item_ent.GetOwner() != activator){
		return
	}
	
	if (special_player != activator){
		//debugprint("special player is not activator");
		return null;
	}
	local time = Time();
	if (time < LastRocket + 0.7)
	{
		//debugprint("Skipping shot at " + Time() + " (last rocket jump at " + LastRocket + ")")
		return;
	}

	sound_ent.SetOrigin(item_ent.GetOrigin());
	EntFireByHandle(sound_ent,"Volume","3",0.0,sound_ent,sound_ent);
	LastRocket=time
	local directionFacing = shot_direction_ent.GetForwardVector();
	local directionOfMovement = Vector(-directionFacing.x, -directionFacing.y, -directionFacing.z)
	local speedboost=Scale(directionOfMovement, BOOST)
	activator.SetVelocity(activator.GetVelocity()+speedboost)
}