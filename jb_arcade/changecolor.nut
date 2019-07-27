//===============================
//=====       CHANGECOLOR   =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================



DEBUG_PRINT<-true
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

COLOR_STRINGS<-["0 123 123", "255 0 0", "0 255 0", "0 0 255", "255 255 0", "255 0 255", "0 255 255", "123 0 123", "123 123 0", "0 0 0", "64 64 64", "128 128 128", "192 192 192", "255 255 255"];
const NUM_COLORS = 14;
const MAX_PLAYERS = 64;
ColorIndex<-array(MAX_PLAYERS+1);
FirstPress<-array(MAX_PLAYERS+1);
GameTextEntities<-array(MAX_PLAYERS+1);

function OnPostSpawn() //Called after the logic_script spawns
{
	EntFireByHandle(self, "RunScriptCode", "Setup()", 0.5, null, null)
}

function Setup()
{
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		GameTextEntities[i] = Entities.FindByName(null,"display_score_" + i);
		ColorIndex[i] = GetString(i.tostring() + "_color").tointeger();
		FirstPress[i] = true;
		SetGameTextColor(i);
	}
}

function SetGameTextColor(playerIndex) {
	local game_txt = GameTextEntities[playerIndex];
	if (game_txt != null) {
		game_txt.__KeyValueFromString("color", COLOR_STRINGS[ColorIndex[playerIndex]]);
	}
}

function ChangeColorActivator()
{
	ChangeColor(activator);
}

function ChangeColor(ply)
{
	if (ply == null || !(ply.IsValid())) return;
	local entindex = ply.entindex();
	local game_txt = GameTextEntities[entindex];
	if (game_txt != null)
	{
		if (!FirstPress[entindex]) {
			ColorIndex[entindex]++;
			if (ColorIndex[entindex] >= NUM_COLORS) {
				ColorIndex[entindex] = 0;
			}
			SaveString(entindex.tostring() + "_color", ColorIndex[entindex].tostring());
		}
		FirstPress[entindex] = false;
		game_txt.__KeyValueFromString("color", COLOR_STRINGS[ColorIndex[entindex]]);
		DisplayTextHelper(ply, "New color: " + COLOR_STRINGS[ColorIndex[entindex]] + " (" + (ColorIndex[entindex] + 1).tostring() + "/" + NUM_COLORS.tostring() + ")", game_txt);
	}
}

function DisplayText(ply, text)
{
	local game_txt = GameTextEntities[ply.entindex()];
	if (game_txt != null)
	{
		DisplayTextHelper(ply, text, game_txt);
	}
}

function DisplayTextHelper(ply, text, game_txt)
{
	game_txt.__KeyValueFromString("message", text);
	EntFireByHandle(game_txt,"Display","",0.01,ply,ply);
}

stringbrush <- null;
SaveString<-function(key, string)
{
	if (stringbrush == null) {
		stringbrush = Entities.FindByName(stringbrush,"surf_times");
	}
	local script_scope=stringbrush.GetScriptScope();
	script_scope[key]<-string;
}

GetString<-function(key)
{
	if (stringbrush == null) {
		stringbrush = Entities.FindByName(stringbrush,"surf_times");
	}
	local script_scope=stringbrush.GetScriptScope();
	if (key in script_scope)
	{
		return script_scope[key];
	}
	return "0";

}
