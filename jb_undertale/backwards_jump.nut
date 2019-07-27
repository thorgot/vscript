//Script by thorgot
function SetTargetName() {
	gameplayer <- null;
	while((gameplayer = Entities.FindByClassname(gameplayer,"player")) != null)
	{
		if (gameplayer.GetName() != "inbackwardsjumparea")
		{
			//printl("Skipping player");
			continue;
		}
		local vector = gameplayer.GetForwardVector();
		//printl(vector.x + " and " + vector.y);
		if ((vector.x > 0.5 || vector.x < -0.5) || vector.y > -0.5) {
			DoEntFire( "!self", "AddOutput", "targetname lookedforward", 0, null, gameplayer );
		}
	}
}