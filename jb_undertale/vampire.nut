item_ent<-null;
special_player<-null

DEBUG <- false;

debugprint<-function(text)
{
	if (DEBUG) printl("*************" + text + "*************")
}

SetVampire<-function()
{
	item_ent = caller;
	
	special_player=activator
	//debugprint("special_player is now " + special_player)
}


KillPlayer<-function()
{
	if (activator == null || special_player == null || special_player != activator) return;
	
	//If the item was thrown or stripped, don't do anything
	if(activator == null || item_ent == null || !item_ent.IsValid() || item_ent.GetOwner() != activator){
		return;
	}
	
	if (special_player.GetHealth() > 100) return;
	local healed = 25;
	local newhealth = special_player.GetHealth() + healed;
	
	if (newhealth > 100) newhealth = 100;
	special_player.SetHealth(newhealth);
	
}