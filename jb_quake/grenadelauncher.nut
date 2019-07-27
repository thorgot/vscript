
::GRENADE_DEBUG<-false

::grenade_player<-null
::grenade_origin<-null
::grenade_last_shot<-0
::grenade_launched<-false
::GRENADE_DISTANCE<-256
::GRENADE_COOLDOWN<-1.8

::debugprintg<-function(text)
{
	if (GRENADE_DEBUG) printl("*************" + text + "*************")
}

//Scales a vector
::Scale<-function(v, scalar)
{
	local len = v.Length();
	if (len == 0)
	{
		return v;
	}
	return Vector(v.x*scalar/len,v.y*scalar/len,v.z*scalar/len);
}

::SetGrenadeLauncher<-function()
{
	//Kill all existing grenades if someone else picks up the launcher
	ent<-null
	while((ent= Entities.FindByName(ent,"grenadelauncher_grenade_primed")) != null)
	{
		EntFireByHandle(ent,"Kill","",0.0,grenade_player,grenade_player);
	}
	
	grenade_player=activator
	if (grenade_origin == null)
	{
		grenade_origin = Entities.FindByName(null,"grenadelauncher_origin")
		//debugprintg("Found grenade origin: " + grenade_origin)
	}
	//debugprintg("grenade_player is now " + grenade_player)
}

::UpdateGrenades<-function()
{
	if (!grenade_launched) return;
	ent <- null;
	while((ent= Entities.FindByName(ent,"grenadelauncher_grenade_primed")) != null)
	{
		if (ent.ValidateScriptScope())
		{
			local script_scope=ent.GetScriptScope()
			if(!("spawn_time" in script_scope))
			{
				script_scope.spawn_time <- Time()
				//debugprintg("Grenade spawned at " + script_scope.spawn_time)
			}
			else if (Time() >= script_scope.spawn_time + 1.5 && !("exploded" in script_scope))
			{
				script_scope.exploded <- true
				//debugprintg("BOOM at " + ent.GetOrigin())
				if (grenade_player != null && grenade_player.IsValid && grenade_player.GetTeam() == 2 || grenade_player.GetTeam() == 3)
				{
					HurtNear(ent.GetOrigin())
				}
				grenade_launched = false
			}
			else
			{
				//debugprintg("Grenade found with age " + (Time() - script_scope.spawn_time))
			}
		}
	}

}

::HurtNear<-function(position)
{
	protected_team<-grenade_player.GetTeam()
	env_entity_maker <- null
	env_entity_maker <- Entities.FindByName(env_entity_maker,"grenadelauncher_entity_maker")
	env_entity_maker.SpawnEntityAtLocation(position,Vector(0,0,0));
	local hurt= Entities.FindByName(null,"grenadelauncher_hurt")
	//debugprintg("Created hurt:" + hurt + " at (" + position.x + "," + position.y + "," + position.z + ")")
	
	
	ent<-null
	while ((ent = Entities.FindByClassnameWithin(ent, "player", position, GRENADE_DISTANCE)) != null)
	{
		//debugprintg("player " + ent + " within blast radius")
		if (ent.GetTeam() != protected_team)
		{
			//EntFireByHandle(ent,"SetDamageFilter","damage_filter_no_blast",0.0,grenade_player,grenade_player);
			EntFireByHandle(ent,"AddOutput","targetname hurtbygrenade",0.0,self,self);
			EntFireByHandle(ent,"AddOutput","targetname default",0.12,self,self);
		}
	}
	
	if(GRENADE_DEBUG) {
		ent<-null
		while ((ent = Entities.FindByClassnameWithin(ent, "cs_bot", position, GRENADE_DISTANCE)) != null)
		{
			//debugprintg("player " + ent + " within blast radius")
			if (ent.GetTeam() != protected_team)
			{
				//EntFireByHandle(ent,"SetDamageFilter","damage_filter_no_blast",0.0,grenade_player,grenade_player);
				EntFireByHandle(ent,"AddOutput","targetname hurtbygrenade",0.0,self,self);
				EntFireByHandle(ent,"AddOutput","targetname default",0.12,self,self);
			}
		}
	}
	
	
	if (hurt != null)
	{
		hurt.__KeyValueFromInt("DamageRadius",GRENADE_DISTANCE);
		hurt.__KeyValueFromInt("damagetype",64);
		hurt.__KeyValueFromInt("damage",50);
		hurt.__KeyValueFromString("damagetarget", "hurtbygrenade");
		EntFireByHandle(hurt,"AddOutput","targetname grenadelauncher_hurt_primed",0.0,hurt,hurt);
		EntFireByHandle(hurt, "AddOutput", "classname hegrenade", 0.0, self, self);
		hurt.SetOrigin(position)
		EntFireByHandle(hurt,"Hurt","",0.05,grenade_player,self);
		EntFireByHandle(hurt,"Kill","",0.12,grenade_player,grenade_player);
	}
	
	ent<-null
	while ((ent = Entities.FindByClassnameWithin(ent, "player", position, GRENADE_DISTANCE)) != null)
	{
		if (ent.GetTeam() != protected_team)
		{
			//EntFireByHandle(ent,"SetDamageFilter","",0.0,grenade_player,grenade_player);
		}
	}
}

::GrenadeLaunch<-function()
{
	if (activator == null) return;
	//debugprintg(params.weapon + " fired by user #" + params.userid + " player " + player + " and grenade_player is " + grenade_player)
	
	//If the grenade launcher was thrown or stripped, don't launch a grenade
	if((Entities.FindByName(null,"grenadelauncher_tracker")) == null){
		return
	}
	
	if (activator == grenade_player && (Time() > grenade_last_shot + GRENADE_COOLDOWN))
	{
		grenade_launched = true
		grenade_last_shot<-Time()
		DoEntFire("grenadelauncher_template","ForceSpawn","",0.0,null,null)
		DoEntFire("grenadelauncher_grenade","InitializeSpawnFromWorld","",0.01,null,null)
		DoEntFire("grenadelauncher_script", "RunScriptCode","SetGrenadeVectors()",0.01,activator,activator)
	}
}

::SetGrenadeVectors<-function()
{
	grenade <- Entities.FindByName(null,"grenadelauncher_grenade")
	if (grenade != null && grenade_player != null && grenade_player.IsValid() && grenade_player.GetHealth() > 0)
	{
		EntFireByHandle(grenade,"AddOutput","targetname grenadelauncher_grenade_primed",0.0,grenade,grenade);
		grenade.SetOrigin(grenade_player.EyePosition() + Scale(grenade_origin.GetForwardVector(), 32.0))
		//debugprintg("forward vector " + grenade_origin.GetForwardVector())
		grenade.SetVelocity(Scale(grenade_origin.GetForwardVector(), 1000.0))
		angles<-grenade_player.GetAngles()
		grenade.SetAngles(angles.x, angles.y, angles.z)
		if(grenade_origin != null)
		{
			//debugprintg("grenade_origin forward vector: " + grenade_origin.GetForwardVector())
		}
	}
}