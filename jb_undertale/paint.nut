//===============================
//=====       PAINT         =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================
//=====Adapted from eyetrace=====
//=====by FlyguyDev         =====
//===============================

::MAXDRAWLIMIT<-192; /*
				   * this is the limit per canvas with an empty server. 
				   * every player takes up 2 edicts and each weapon uses 2, so with a 40 person server with
				   * everybody equipped with four weapons this would go down to 192-(2*40+4*2*40)/2 = -8.
				   * however, most rounds only the guards and a few rebellers spawn weapons, so on a full server
				   * this will be closer to 80.
				   */
::DrawLimitPerCanvas<-MAXDRAWLIMIT;
::DRAWTIME<-0.1;
::DrawColor<-{};
::DrawColor[0]<-[255,1,1];
::DrawColor[1]<-[255,1,1];
::DrawCount<-{};
::DrawCount[0]<-0;
::DrawCount[1]<-0;
::DrawSize<-{};
::DrawSize[0]<-2;
::DrawSize[1]<-5;
::DrawSizeToPixelRadius<-[0.0, 2.0, 4.0, 8.0, 2.0, 4.0, 8.0]
::EraseSizes<-[0.0, 8.0, 16.0, 32.0, 8.0, 16.0, 32.0]
//Eye trace variables
::DrawPlayer <- [null,null]; //The player entity
LastSprite<-[0,0];
LastLimitCheck<-0.0;
LIMITCHECKTIME<-5.0;

DEBUG<-false;
::debugprint<-function(text)
{
	if (DEBUG) printl("*************" + text + "*************")
}

function OnPostSpawn() //Called after the logic_script spawns
{
	DoIncludeScript("custom/Util.nut",null); //Include the utility functions/classes from Util.nut in this script
}

function Think()
{
	for (local canvas = 0; canvas <= 1; canvas++)
	{
		if (EntityGroup[canvas] == null) continue
		if(DrawPlayer[canvas] != null && DrawPlayer[canvas].IsValid() && DrawPlayer[canvas].GetHealth() > 0)
		{
			//Cast a ray from the player's eyes in the direction they are looking
			Hit <- TraceDir(DrawPlayer[canvas].EyePosition(),EntityGroup[canvas].GetForwardVector(),46341.0,DrawPlayer[canvas]).Hit;
			
			//DrawAxis(Hit,32.0,false,0.1); //Draw a cross showing the X/Y/Z axes at the current hit position
			
			if (Time() >= LastSprite[canvas] + DRAWTIME)
			{
				//Only draw sprites at most 2 times per second
				LastSprite[canvas] = Time()
				DrawCanvas <- GetDrawCanvas(Hit.x, Hit.y, Hit.z)
				if (canvas == DrawCanvas)
				{
					SpawnSprite(Hit.x, Hit.y, Hit.z, DrawCanvas)
				}
				//debugprint("Printing sprite at " + LastSprite[canvas] + " (" + Hit.x + "," + Hit.y + "," + Hit.z + ")")
			}
		}
	}
	if (Time() >= LastLimitCheck + LIMITCHECKTIME)
	{
		LastLimitCheck = Time()
		//debugprint("Recalibrating paint limit at " + LastLimitCheck)
		edicts<-0
		ent<-null
		while((ent = Entities.FindByClassname(ent,"player")) != null){
			//debugprint("Found player: " + ent)
			edicts+=2
		}
		ent<-null
		while((ent = Entities.FindByClassname(ent,"weapon_*")) != null){
			//debugprint("Found weapon: " + ent)
			edicts+=2
		}
		DrawLimitPerCanvas = MAXDRAWLIMIT - (edicts / 2)
		//debugprint("Total edicts found: " + edicts)
		//debugprint("Setting DrawLimitPerCanvas: " + DrawLimitPerCanvas)
	}
}

::SpawnSprite<-function(x,y,z, canvas)
{
	if (canvas == -1)
	{
		return
	}
	pos <- Vector(x,y,z)
	if (::DrawColor[canvas][0] == -1)
	{
		EraseSprites(pos, canvas)
		return
	}
	
	//Turn off canvas if drawcount is reached. Always allow erasing.
	if (DrawCount[canvas] >= DrawLimitPerCanvas)
	{
		RegisterCanvasDrawer(null, canvas)
		return
	}
	local existingSprite = Entities.FindByClassnameWithin(null,"env_sprite_oriented",pos,DrawSizeToPixelRadius[::DrawSize[canvas]]);
	if (existingSprite != null)
	{
		//debugprint("Found sprite near cursor, not drawing.")
		return
	}
	
	DrawCount[canvas]++
	env_entity_maker <- null
	env_entity_maker <- Entities.FindByName(env_entity_maker,"draw_entity_maker" + ::DrawSize[canvas])
	env_entity_maker.SpawnEntityAtLocation(pos,Vector(0,0,0));
	local sprite = Entities.FindByClassnameWithin(null,"env_sprite_oriented",pos,0.5);
	//debugprint("Created sprite  " + sprite + " at " + pos + "(" + pos.x + "," + pos.y + "," + pos.z + ")")
	//sprite.__KeyValueFromInt("scale",::DrawSize[canvas]);
	sprite.__KeyValueFromInt("rendermode",9);
	sprite.__KeyValueFromInt("renderamt",255);
	//EntFireByHandle(sprite, "AddOutput", "targetname draw_sprite_" + canvas, 0, null, null)
	sprite.__KeyValueFromString("rendercolor","" + ::DrawColor[canvas][0] + " " + ::DrawColor[canvas][1] + " " + ::DrawColor[canvas][2]);
}

::EraseSprites<-function(pos,canvas)
{
	sprite <- null
	while ((sprite = Entities.FindByClassnameWithin(sprite, "env_sprite_oriented", pos, EraseSizes[DrawSize[canvas]])) != null)
	{
		EntFireByHandle(sprite, "kill", "", 0, null, null)
		DrawCount[canvas]--
	}
}

::GetDrawCanvas<-function(x,y,z)
{
	if (z > 504.0 || z < 248.0 || y > 4090.0 || y < 4088.0)
	{
		return -1
	}
	else if (x > 576.0 && x < 832.0)
	{
		return 1
	}
	else if (x > 936.0 && x < 1192.0)
	{
		return 0
	}
	return -1
}

::SetDrawColor<-function(canvas,r,g,b)
{
	::DrawColor[canvas] <- [r,g,b]
}

::SetDrawSize<-function(canvas, size)
{
	::DrawSize[canvas] <- size
}

::ResetDrawCanvas<-function(canvas)
{
	DrawCount[canvas] <- 0
}

::RegisterCanvasDrawerFromName <- function(canvas)
{
	ent <- null
	ent <- Entities.FindByName(ent,"draw_player_" + canvas)
	if (ent == null)
	{
		//debugprint("Error: trying to register artist for canvas " + canvas + " but draw_player_" + canvas + " not found.")
		return
	}
	RegisterCanvasDrawer(ent, canvas)
}

::RegisterCanvasDrawer <- function(ent, canvas) //Global function called to get the player entity
{
	if (canvas == -1) return
	//TODO can dead drawers still draw?
	
	if (ent == DrawPlayer[canvas] || ent == null)
	{
		//Player is toggling off their drawing
		DrawPlayer[canvas] = null
		if (DrawPlayer[canvas] != null)
		{
			EntFireByHandle(DrawPlayer[canvas], "AddOutput", "targetname default", 0.0, null, null)
		}
		DoEntFire("draw_measure", "SetMeasureTarget", "draw_spn" + canvas, 0.0, null, null)
		//debugprint("Unregistered Player: "+ent);
	}
	else
	{
		//Player is toggling on their drawing
		DrawPlayer[canvas] = ent;
		DoEntFire("draw_measure" + canvas, "SetMeasureTarget", "draw_player_"+canvas, 0.2, null, null)
		//debugprint("Registered Player: "+ent);
	}
}