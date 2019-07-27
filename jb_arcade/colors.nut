//===============================
//=====       COLORS        =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

//Constants
ROUND_TIME <- [4.5, 4.0, 3.5];
const MIN_ROUND_TIME = 2.0;
const ROUND_END_TIME = 0.5;
const ROUNDS_PER_DIFFICULTY = 6;
GAME_MIN <- Vector(1232.0, 1440.0, -513.0);
GAME_MAX <- Vector(1616.0, 1824.0, -192.0);
const GAME_WIDTH = 384.0;
const GAME_WIDTH_THIRD = 128.0;
const PLAYER_WIDTH_HALF = 16.0;
const PLAYER_HEIGHT_CROUCHED = 54.0;
const PLAYER_JUMP_HEIGHT = 64.0;
LINE_WIDTH <- [64.0, 32.0, 16.0];
const NUM_COLORS = 9;
DIRECTIONS <- ["Face North", "Face East", "Face South", "Face West"];
DIRECTIONS_ABBREVIATED <- ["N", "E", "S", "W"];
SIDES <- ["Go North", "Go East", "Go South", "Go West"];
COLORS_NORTH <- {[6] = true, [7] = true, [8] = true};
COLORS_EAST <- {[2] = true, [5] = true, [8] = true};
COLORS_SOUTH <- {[0] = true, [1] = true, [2] = true};
COLORS_WEST <- {[0] = true, [3] = true, [6] = true};
SIDE_COLORS <- [COLORS_NORTH, COLORS_EAST, COLORS_SOUTH, COLORS_WEST];
COLORS <- ["Orange", "Purple", "Green", "White", "Red", "Black", "Blue", "Yellow", "Brown"];
COLORS_MIN <- [
	Vector(GAME_MIN.x, GAME_MIN.y, 0),
	Vector(GAME_MIN.x + GAME_WIDTH_THIRD, GAME_MIN.y, 0),
	Vector(GAME_MAX.x - GAME_WIDTH_THIRD, GAME_MIN.y, 0),
	Vector(GAME_MIN.x, GAME_MIN.y + GAME_WIDTH_THIRD, 0),
	Vector(GAME_MIN.x + GAME_WIDTH_THIRD, GAME_MIN.y + GAME_WIDTH_THIRD, 0),
	Vector(GAME_MAX.x - GAME_WIDTH_THIRD, GAME_MIN.y + GAME_WIDTH_THIRD, 0),
	Vector(GAME_MIN.x, GAME_MAX.y - GAME_WIDTH_THIRD, 0),
	Vector(GAME_MIN.x + GAME_WIDTH_THIRD, GAME_MAX.y - GAME_WIDTH_THIRD, 0),
	Vector(GAME_MAX.x - GAME_WIDTH_THIRD, GAME_MAX.y - GAME_WIDTH_THIRD, 0)
];
COLORS_MAX <- [
	Vector(GAME_MIN.x + GAME_WIDTH_THIRD, GAME_MIN.y + GAME_WIDTH_THIRD, 0),
	Vector(GAME_MAX.x - GAME_WIDTH_THIRD, GAME_MIN.y + GAME_WIDTH_THIRD, 0),
	Vector(GAME_MAX.x, GAME_MIN.y + GAME_WIDTH_THIRD, 0),
	Vector(GAME_MIN.x + GAME_WIDTH_THIRD, GAME_MAX.y - GAME_WIDTH_THIRD, 0),
	Vector(GAME_MAX.x - GAME_WIDTH_THIRD, GAME_MAX.y - GAME_WIDTH_THIRD, 0),
	Vector(GAME_MAX.x, GAME_MAX.y - GAME_WIDTH_THIRD, 0),
	Vector(GAME_MIN.x + GAME_WIDTH_THIRD, GAME_MAX.y, 0),
	Vector(GAME_MAX.x - GAME_WIDTH_THIRD, GAME_MAX.y, 0),
	Vector(GAME_MAX.x, GAME_MAX.y, 0)
];
enum COMMANDS {
	corners,
	side,
	colors,
	direction,
	line,
	circle,
	jump,
	crouch,
	ladders,
	walk,
	run
}
LADDER_ENTITY_NAMES <- ["colors_ladder_brush_easy", "colors_ladder_brush_medium", "colors_ladder_brush_hard"];
BUTTON_TEXTURE_NAMES <- ["colors_easy_tt", "colors_medium_tt", "colors_hard_tt"];
const MAX_DAMAGE_COLORS = 100;
const MIN_DAMAGE_COLORS = 0;
const WALKING_SPEED_SQUARED = 16900;
const RUNNING_SPEED_SQUARED = 62500;
const SPEED_LEEWAY = 25000;
DAMAGE_TO_TEXTURE <- {[0] = 0, [5] = 1, [10] = 2, [15] = 3, [20] = 4, [25] = 5, [50] = 6, [75] = 7, [100] = 8};
COMMAND_TO_TEXTURE <- {[COMMANDS.corners] = "4", [COMMANDS.side] = "-1", [COMMANDS.colors] = "-1", [COMMANDS.direction] = "-1", [COMMANDS.line] = "1", [COMMANDS.circle] = "2", [COMMANDS.jump] = "13", [COMMANDS.crouch] = "14", [COMMANDS.ladders] = "3", [COMMANDS.walk] = "24", [COMMANDS.run] = "25"};
GO_DIRECTION_TO_TEXTURE <- {[0] = "12", [1] = "10", [2] = "11", [3] = "9"}; // NESW
FACE_DIRECTION_TO_TEXTURE <- {[0] = "8", [1] = "6", [2] = "7", [3] = "5"}; // NESW
COLOR_TO_TEXTURE <- {[0] = "21", [1] = "15", [2] = "22", [3] = "20", [4] = "23", [5] = "19", [6] = "18", [7] = "16", [8] = "17"};
				  //["Orange",   "Purple",   "Green",    "White",    "Red",      "Black",    "Blue",     "Yellow",   "Brown"];

//Configuration
Damage<-50;
Difficulty<-0;
NextDifficulty<-0;

//State
GameOn <- false;
GameCount <- 0;
RoundNumber <- 0;
Auto <- true;
LastCommands <- null;
InstructionMiddleEntities <- {};
InstructionLeftEntities <- {};
InstructionRightEntities <- {};
LinePosition <- Vector(0.0, 0.0, 0.0);
LineHorizontal <- 0;
LineEntitiesHorizontal <- array(3);
LineEntitiesVertical <- array(3);
LineEntities <- [LineEntitiesHorizontal, LineEntitiesVertical];
Direction <- "";
Side <- -1;
CirclePosition <- Vector(0.0, 0.0, 0.0);
CircleEntities <- array(3);
CircleRadius <- [GAME_WIDTH / 4.0, GAME_WIDTH / 8.0, GAME_WIDTH / 16.0];
Colors <- null;
ColorString <- "";
SlowedPlayers <- {};
ExpectedPlayerSpeed <- 0;
DamageSignTT<-null;
GameTextEntities<-array(MAX_PLAYERS+1);

/*************
 ***General***
 *************/

DEBUG_PRINT<-true;
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function Setup() {
	LineEntitiesHorizontal[0] = Entities.FindByName(null, "colors_line_easy_horizontal");
	LineEntitiesHorizontal[1] = Entities.FindByName(null, "colors_line_medium_horizontal");
	LineEntitiesHorizontal[2] = Entities.FindByName(null, "colors_line_hard_horizontal");
	LineEntitiesVertical[0] = Entities.FindByName(null, "colors_line_easy_vertical");
	LineEntitiesVertical[1] = Entities.FindByName(null, "colors_line_medium_vertical");
	LineEntitiesVertical[2] = Entities.FindByName(null, "colors_line_hard_vertical");
	CircleEntities[0] = Entities.FindByName(null, "colors_circle_easy");
	CircleEntities[1] = Entities.FindByName(null, "colors_circle_medium");
	CircleEntities[2] = Entities.FindByName(null, "colors_circle_hard");
	for (local i = 0; i <= 2; i++) {
		EntFireByHandle(CircleEntities[i], "Disable", "", 0.0, null, CircleEntities[i]);
		EntFireByHandle(LineEntitiesHorizontal[i], "Disable", "", 0.0, null, LineEntitiesHorizontal[i]);
		EntFireByHandle(LineEntitiesVertical[i], "Disable", "", 0.0, null, LineEntitiesVertical[i]);
	}
	local instructionEntity = null;
	while ((instructionEntity = Entities.FindByName(instructionEntity, "colors_commands_middle_tt")) != null) {
		InstructionMiddleEntities[instructionEntity.entindex()] <- instructionEntity;
	}
	while ((instructionEntity = Entities.FindByName(instructionEntity, "colors_commands_left_tt")) != null) {
		InstructionLeftEntities[instructionEntity.entindex()] <- instructionEntity;
	}
	while ((instructionEntity = Entities.FindByName(instructionEntity, "colors_commands_right_tt")) != null) {
		InstructionRightEntities[instructionEntity.entindex()] <- instructionEntity;
	}
	
	EntFire("colors_ladder", "Disable", "", 0.0, null);
	EntFire("colors_ladder_brush_*" "Disable", "", 0.0, null);
	UpdateButtonTextures(difficulty)
	EntFire("colors_end_tt", "SetTextureIndex", "1", 0.0, null);
	EntFire("colors_commands_right_tt", "SetTextureIndex", "0", 0.0, null);
	EntFire("colors_commands_middle_tt", "SetTextureIndex", "0", 0.0, null);
	EntFire("colors_commands_left_tt", "SetTextureIndex", "0", 0.0, null);
	AddToDamage(0); //refresh damage sign
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		GameTextEntities[i] = Entities.FindByName(null,"display_score_" + i);
	}
	SetDifficulty(difficulty);
	
}

function SetInstructionsMiddle(text) {
	foreach (instructionEntity in InstructionMiddleEntities) {
		//instructionEntity.__KeyValueFromString("message", text);
		EntFireByHandle(instructionEntity, "SetTextureIndex", text, 0.0, self, self);
	}
	if (text != "0") {
		SetInstructionsLeft("0");
		SetInstructionsRight("0");
	}
	
}
function SetInstructionsLeft(text) {
	foreach (instructionEntity in InstructionLeftEntities) {
		//instructionEntity.__KeyValueFromString("message", text);
		EntFireByHandle(instructionEntity, "SetTextureIndex", text, 0.0, self, self);
	}
	if (text != "0") {
		SetInstructionsMiddle("0");
	}
}
function SetInstructionsRight(text) {
	foreach (instructionEntity in InstructionRightEntities) {
		//instructionEntity.__KeyValueFromString("message", text);
		EntFireByHandle(instructionEntity, "SetTextureIndex", text, 0.0, self, self);
	}
}

function GetGamePlayers() {
	return GetGamePlayersWithLeeway(PLAYER_WIDTH_HALF);
}

function GetGamePlayersWithLeeway(leeway) {
	gameplayers <- {};
	gameplayer <- null;
	while((gameplayer = Entities.FindByClassname(gameplayer,"player")) != null) {
		local playerOrigin = gameplayer.GetOrigin();
		if (playerOrigin.x >= GAME_MIN.x - leeway && playerOrigin.x <= GAME_MAX.x + leeway &&
		    playerOrigin.y >= GAME_MIN.y - leeway && playerOrigin.y <= GAME_MAX.y + leeway &&
		    playerOrigin.z >= GAME_MIN.z && playerOrigin.z < GAME_MAX.z)
		{
			gameplayers[gameplayer.entindex()] <- gameplayer;
		}
	}
	return gameplayers;
}

//Get the union of two sets
function Union(A, B) {
	union <- {};
	foreach (indexA, playerA in A) {
		union[indexA] <- playerA;
	}
	foreach (indexB, playerB in B) {
		union[indexB] <- playerB;
	}
	return union;
}

function UpdateButtonTextures(button) {
	EntFire(BUTTON_TEXTURE_NAMES[button], "SetTextureIndex", "1", 0.0, null);
	EntFire(BUTTON_TEXTURE_NAMES[(button + 1) % 3], "SetTextureIndex", "0", 0.0, null);
	EntFire(BUTTON_TEXTURE_NAMES[(button + 2) % 3], "SetTextureIndex", "0", 0.0, null);
}

function SetNextDifficulty(difficulty) {
	NextDifficulty = difficulty;
	UpdateButtonTextures(NextDifficulty);
	if (!GameOn) {
		SetDifficulty(difficulty);
	}
}

function SetTimer(timerTime) {
	EntFire("colors_timer", "RefireTime", (timerTime + 0.1).tostring(), 0.0, null)
}

function SetDifficulty(difficulty) {
	Difficulty = difficulty;
	SetTimer(ROUND_TIME[difficulty] + ROUND_END_TIME);
}

function PunishPlayers(gameplayers) {
	foreach (gameplayer in gameplayers) {
		EntFireByHandle(gameplayer, "SetHealth", (gameplayer.GetHealth() - Damage).tostring(), 0.0, null, gameplayer);
	}
}

function TeleportPlayers(gameplayers) {
	local gameCenter = Vector(((GAME_MAX.x + GAME_MIN.x) / 2), ((GAME_MAX.y + GAME_MIN.y) / 2), GAME_MIN.z + 4.0);
	foreach (gameplayer in gameplayers) {
		gameplayer.SetOrigin(gameCenter);
		gameplayer.SetVelocity(Vector(0, 0, 0));
	}
}

function StartGame() {
	if (GameOn) {
		return;
	}
	GameOn = true;
	GameCount++;
	EntFire("colors_timer", "Enable", "0.0", 0.0, null);
}

function EndRound() {
	if (GameOn) {
		SetInstructionsLeft("0");
		SetInstructionsMiddle("0");
		SetInstructionsRight("0");
	}
}
function EndGame() {
	if (!GameOn) {
		return;
	}
	GameOn = false;
	RoundNumber = 0;
	EntFire("colors_timer", "Disable", "0.0", 0.0, null);
	SetInstructionsLeft("0");
	SetInstructionsMiddle("0");
	SetInstructionsRight("0");
	
	if (LastCommands == null) {
		return;
	}
	foreach (command in LastCommands) {
		switch (command) {
			case COMMANDS.corners:
				ChooseCorners(false);
				break;
			case COMMANDS.direction:
				ChooseRandomDirection(false);
				break;
			case COMMANDS.line:
				ChooseRandomLinePosition(false);
				break;
			case COMMANDS.circle:
				ChooseRandomCirclePosition(false);
				break;
			case COMMANDS.side:
				ChooseRandomSide(false);
				break;
			case COMMANDS.colors:
				ChooseRandomColors(0);
				break;
			case COMMANDS.jump:
				SetJump(false);
				break;
			case COMMANDS.crouch:
				SetCrouch(false);
				break;
			case COMMANDS.ladders:
				SetLadders(false);
				TeleportPlayers(GetGamePlayersWithLeeway(96.0));
				break;
			case COMMANDS.walk:
				SetMovement(false);
				break;
			case COMMANDS.run:
				SetMovement(false);
				break;
			default:
				debugprint(" Selected command out of bounds in EndGame: " + command);
				break;
		}
	}
	LastCommands = null;
}

function ChooseRandomCommand() {
	local roundTime = ROUND_TIME[Difficulty];
	Colors = null;
	if (NextDifficulty != Difficulty) {
		SetDifficulty(NextDifficulty);
		RoundNumber = 0;
		return;
	}
	if (RoundNumber >= ROUNDS_PER_DIFFICULTY && Auto && Difficulty < 2) {
		debugprint("Setting Difficulty to " + (Difficulty+1));
		RoundNumber = 0;
		SetDifficulty(Difficulty+1);
		NextDifficulty = Difficulty;
		UpdateButtonTextures(Difficulty);
		return;
	}
	if (Difficulty == 2) {
		roundTime = ROUND_TIME[Difficulty] - (RoundNumber * 0.1);
		if (roundTime < MIN_ROUND_TIME) {
			roundTime = MIN_ROUND_TIME;
		} else {
			SetTimer(roundTime + ROUND_END_TIME);
		}
	}
	debugprint("Now on RoundNumber " + RoundNumber + " where roundTime = " + roundTime);
	
	if (Difficulty == 0) {
		local command = RandomInt(COMMANDS.corners, COMMANDS.run);
		LastCommands = [command];
		switch (command) {
			case COMMANDS.corners:
				ChooseCorners(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.corners]);
				DisplayTextToGamePlayers("Go to the corners");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnColors("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.side:
				ChooseRandomSide(true);
				SetInstructionsMiddle(GO_DIRECTION_TO_TEXTURE[Side]);
				DisplayTextToGamePlayers(SIDES[Side]);
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnColors("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.colors:
				ChooseRandomColors(2);
				local colorString = "Go to ";
				local first = true;
				foreach (color, val in Colors) {
					if (first) {
						first = false;
						SetInstructionsLeft(COLOR_TO_TEXTURE[color]);
						colorString += COLORS[color];
					} else {
						SetInstructionsRight(COLOR_TO_TEXTURE[color]);
						colorString += " OR " + COLORS[color];
					}
				}
				DisplayTextToGamePlayers(colorString);
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnColors("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.direction:
				ChooseRandomDirection(true);
				SetInstructionsMiddle(FACE_DIRECTION_TO_TEXTURE[Direction]);
				DisplayTextToGamePlayers(DIRECTIONS[Direction]);
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotFacingDirection("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.line:
				ChooseRandomLinePosition(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.line]);
				DisplayTextToGamePlayers("Go to the line");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnLine("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.circle:
				ChooseRandomCirclePosition(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.circle]);
				DisplayTextToGamePlayers("Go to the circle");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotInCircle("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.jump:
				SetJump(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.jump]);
				DisplayTextToGamePlayers("Jump");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersWhoDidNotJump("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.crouch:
				SetCrouch(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.crouch]);
				DisplayTextToGamePlayers("Crouch");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersWhoDidNotCrouch("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.ladders:
				SetLadders(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.ladders]);
				DisplayTextToGamePlayers("Go up a ladder");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnLadders("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.walk:
				ExpectedPlayerSpeed = WALKING_SPEED_SQUARED;
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.walk]);
				DisplayTextToGamePlayers("Shift walk around");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotAtSpeed("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.run:
				ExpectedPlayerSpeed = RUNNING_SPEED_SQUARED;
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.run]);
				DisplayTextToGamePlayers("Run around");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotAtSpeed("+GameCount+"))", roundTime, null, self);
				break;
			default:
				debugprint("Selected command out of bounds in ChooseRandomCommand: " + command);
				break;
		}
	} else if (Difficulty == 1) {
		local command = RandomInt(COMMANDS.colors, COMMANDS.ladders);
		switch (command) {
			case COMMANDS.colors:
				LastCommands = [COMMANDS.colors];
				ChooseRandomColors(1);
				foreach (color, val in Colors) {
					SetInstructionsMiddle(COLOR_TO_TEXTURE[color]);
					DisplayTextToGamePlayers("Go to " + COLORS[color]);
				}
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnColors("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.direction:
				LastCommands = [COMMANDS.direction, COMMANDS.side];
				ChooseRandomDirection(true);
				ChooseRandomSide(true);
				SetInstructionsLeft(GO_DIRECTION_TO_TEXTURE[Side]);
				SetInstructionsRight(FACE_DIRECTION_TO_TEXTURE[Direction]);
				DisplayTextToGamePlayers(SIDES[Side] + " AND " + DIRECTIONS[Direction]);
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(Union(GetPlayersNotFacingDirection("+GameCount+"), GetPlayersNotOnColors("+GameCount+")))", roundTime, null, self);
				break;
			case COMMANDS.line:
				LastCommands = [COMMANDS.line];
				ChooseRandomLinePosition(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.line]);
				DisplayTextToGamePlayers("Go to the line");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnLine("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.circle:
				LastCommands = [COMMANDS.circle];
				ChooseRandomCirclePosition(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.circle]);
				DisplayTextToGamePlayers("Go to the circle");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotInCircle("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.jump:
				LastCommands = [COMMANDS.jump, COMMANDS.side];
				SetJump(true);
				ChooseRandomSide(true);
				SetInstructionsLeft(GO_DIRECTION_TO_TEXTURE[Side]);
				SetInstructionsRight(COMMAND_TO_TEXTURE[COMMANDS.jump]);
				DisplayTextToGamePlayers(SIDES[Side] + " AND Jump");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(Union(GetPlayersWhoDidNotJump("+GameCount+"), GetPlayersNotOnColors("+GameCount+")))", roundTime, null, self);
				break;
			case COMMANDS.crouch:
				LastCommands = [COMMANDS.crouch, COMMANDS.side];
				SetCrouch(true);
				ChooseRandomSide(true);
				SetInstructionsLeft(GO_DIRECTION_TO_TEXTURE[Side]);
				SetInstructionsRight(COMMAND_TO_TEXTURE[COMMANDS.crouch]);
				DisplayTextToGamePlayers(SIDES[Side] + " AND Crouch");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(Union(GetPlayersWhoDidNotCrouch("+GameCount+"), GetPlayersNotOnColors("+GameCount+")))", roundTime, null, self);
				break;
			case COMMANDS.ladders:
				LastCommands = [COMMANDS.ladders];
				SetLadders(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.ladders]);
				DisplayTextToGamePlayers("Go up a ladder");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnLadders("+GameCount+"))", roundTime, null, self);
				break;
			default:
				debugprint("Selected command out of bounds in ChooseRandomCommand: " + command);
				break;
		} 
	} else if (Difficulty == 2) {
		local command = RandomInt(COMMANDS.direction, COMMANDS.ladders);
		switch (command) {
			case COMMANDS.direction:
				LastCommands = [COMMANDS.direction, COMMANDS.colors];
				ChooseRandomColors(1);
				ChooseRandomDirection(true);
				foreach (color, val in Colors) {
					SetInstructionsLeft(COLOR_TO_TEXTURE[color]);
					DisplayTextToGamePlayers("Go to " + COLORS[color] + " AND " + DIRECTIONS[Direction]);
				}
				SetInstructionsRight(FACE_DIRECTION_TO_TEXTURE[Direction]);
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(Union(GetPlayersNotFacingDirection("+GameCount+"), GetPlayersNotOnColors("+GameCount+")))", roundTime, null, self);
				break;
			case COMMANDS.line:
				LastCommands = [COMMANDS.line];
				ChooseRandomLinePosition(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.line]);
				DisplayTextToGamePlayers("Go to the line");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnLine("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.circle:
				LastCommands = [COMMANDS.circle];
				ChooseRandomCirclePosition(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.circle]);
				DisplayTextToGamePlayers("Go to the circle");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotInCircle("+GameCount+"))", roundTime, null, self);
				break;
			case COMMANDS.jump:
				LastCommands = [COMMANDS.jump, COMMANDS.colors];
				SetJump(true);
				ChooseRandomColors(1);
				foreach (color, val in Colors) {
					SetInstructionsLeft(COLOR_TO_TEXTURE[color]);
					DisplayTextToGamePlayers("Go to " + COLORS[color] + " AND Jump");
				}
				SetInstructionsRight(COMMAND_TO_TEXTURE[COMMANDS.jump]);
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(Union(GetPlayersWhoDidNotJump("+GameCount+"), GetPlayersNotOnColors("+GameCount+")))", roundTime, null, self);
				break;
			case COMMANDS.crouch:
				LastCommands = [COMMANDS.crouch, COMMANDS.colors];
				SetCrouch(true);
				ChooseRandomColors(1);
				foreach (color, val in Colors) {
					SetInstructionsLeft(COLOR_TO_TEXTURE[color]);
					DisplayTextToGamePlayers("Go to " + COLORS[color] + " AND Crouch");
				}
				SetInstructionsRight(COMMAND_TO_TEXTURE[COMMANDS.crouch]);
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(Union(GetPlayersWhoDidNotCrouch("+GameCount+"), GetPlayersNotOnColors("+GameCount+")))", roundTime, null, self);
				break;
			case COMMANDS.ladders:
				LastCommands = [COMMANDS.ladders];
				SetLadders(true);
				SetInstructionsMiddle(COMMAND_TO_TEXTURE[COMMANDS.ladders]);
				DisplayTextToGamePlayers("Go up a ladder");
				EntFireByHandle(self, "RunScriptCode", "PunishPlayers(GetPlayersNotOnLadders("+GameCount+"))", roundTime, null, self);
				break;
			default:
				debugprint("Selected command out of bounds in ChooseRandomCommand: " + command);
				break;
		}
	}
	RoundNumber++;
}

function ToggleAuto() {
	Auto = !Auto;
}

function SetAuto(newAuto) {
	Auto = newAuto;
}


function AddToDamage(toAdd)
{
	Damage += toAdd;
	if (Damage > MAX_DAMAGE_COLORS) Damage = MAX_DAMAGE_COLORS;
	if (Damage < MIN_DAMAGE_COLORS) Damage = MIN_DAMAGE_COLORS;

	if (DamageSignTT == null)
	{
		DamageSignTT = Entities.FindByName(null, "colors_damage_sign_tt");
	}
	EntFireByHandle(DamageSignTT, "SetTextureIndex", DAMAGE_TO_TEXTURE[Damage].tostring(), 0.0, null, self);
}

/**********************
 ***Direction Facing***
 **********************/
function ChooseRandomDirection(enabled) {
	if(enabled) {
		Direction = RandomInt(0, 3);
	} else {
		EndRound();
	}
}
 
function GetPlayersNotFacingDirection(startingGameCount) {
	failedPlayers <- {};
	if (!GameOn || GameCount != startingGameCount) return failedPlayers;
	local gameplayers = GetGamePlayers();
	foreach(gameplayer in gameplayers) {
		local correctDirection = false;
		
		
		local vector = gameplayer.GetForwardVector();
		if (vector.x > -0.85 && vector.x < 0.85) {
			if (vector.y > 0.6 && Direction == 0) {
				debugprint("Facing North");
				correctDirection = true;
			}
			else if (vector.y < -0.6 && Direction == 2) {
				debugprint("Facing South");
				correctDirection = true;
			}
		}
		if (vector.y > -0.85 && vector.y < 0.85) {
			if (vector.x > 0.6 && Direction == 1) {
				debugprint("Facing East");
				correctDirection = true;
			}
			else if (vector.x < -0.6 && Direction == 3) {
				debugprint("Facing West");
				correctDirection = true;
			}
		}
		if (!correctDirection) {
			failedPlayers[gameplayer.entindex()] <- gameplayer;
		}
	}
	EntFireByHandle(self, "RunScriptCode", "ChooseRandomDirection(false)", ROUND_END_TIME, null, self);
	return failedPlayers;
}

/***********
 ***Lines***
 ***********/
function ChooseRandomLinePosition(enabled) {
	if(enabled) {
		LineHorizontal = RandomInt(0, 1);
		if (LineHorizontal == 0) {
			LinePosition = Vector(GAME_MIN.x, RandomFloat(GAME_MIN.y, GAME_MAX.y - LINE_WIDTH[Difficulty]), GAME_MIN.z + 1.0);
		} else {
			LinePosition = Vector(RandomFloat(GAME_MIN.x, GAME_MAX.x - LINE_WIDTH[Difficulty]), GAME_MIN.y, GAME_MIN.z + 1.0);
		}
		debugprint("LineHorizontal: " + LineHorizontal);
		debugprint("LinePosition: " + LinePosition);
		debugprint("LineEntities[LineHorizontal][Difficulty]: " + LineEntities[LineHorizontal][Difficulty]);
		LineEntities[LineHorizontal][Difficulty].SetOrigin(LinePosition);
		EntFireByHandle(LineEntities[LineHorizontal][Difficulty], "Enable", "", 0.0, null, LineEntities[LineHorizontal][Difficulty]);
	} else {
		EntFireByHandle(LineEntities[LineHorizontal][Difficulty], "Disable", "", 0.0, null, LineEntities[LineHorizontal][Difficulty]);
		EndRound();
	}
}

function GetPlayersNotOnLine(startingGameCount) {
	failedPlayers <- {};
	if (!GameOn || GameCount != startingGameCount) return failedPlayers;
	local gameplayers = GetGamePlayers();
	local isLineHorizontal = LineHorizontal == 0;
	foreach(gameplayer in gameplayers) {
		local playerOrigin = gameplayer.GetOrigin();
		debugprint("x bounds: " + (LinePosition.x - PLAYER_WIDTH_HALF) + " to " + (LinePosition.x + (isLineHorizontal ? GAME_WIDTH : LINE_WIDTH[Difficulty]) + PLAYER_WIDTH_HALF));
		debugprint("y bounds: " + (LinePosition.y - PLAYER_WIDTH_HALF) + " to " + (LinePosition.y + (isLineHorizontal ? LINE_WIDTH[Difficulty] : GAME_WIDTH) + PLAYER_WIDTH_HALF));
		if (playerOrigin.x < LinePosition.x - PLAYER_WIDTH_HALF ||
			playerOrigin.x > LinePosition.x + (isLineHorizontal ? GAME_WIDTH : LINE_WIDTH[Difficulty]) + PLAYER_WIDTH_HALF ||
			playerOrigin.y < LinePosition.y - PLAYER_WIDTH_HALF ||
			playerOrigin.y > LinePosition.y + (isLineHorizontal ? LINE_WIDTH[Difficulty] : GAME_WIDTH) + PLAYER_WIDTH_HALF)
		{
			failedPlayers[gameplayer.entindex()] <- gameplayer;
			debugprint("Player not on line: " + gameplayer);
		}
		else 
			debugprint("Player on line: " + gameplayer);
	}
	EntFireByHandle(self, "RunScriptCode", "ChooseRandomLinePosition(false)", ROUND_END_TIME, null, self);
	return failedPlayers;
}

/************
 ***Circle***
 ************/
function ChooseRandomCirclePosition(enabled) {
	if(enabled) {
		local radius = CircleRadius[Difficulty];
		CirclePosition = Vector(RandomFloat(GAME_MIN.x + radius, GAME_MAX.x - radius), RandomFloat(GAME_MIN.y + radius, GAME_MAX.y - radius), GAME_MIN.z + 1.0);
		debugprint("CirclePosition: " + CirclePosition);
		CircleEntities[Difficulty].SetOrigin(CirclePosition);
		EntFireByHandle(CircleEntities[Difficulty], "Enable", "", 0.0, null, CircleEntities[Difficulty]);
	} else {
		EntFireByHandle(CircleEntities[Difficulty], "Disable", "", 0.0, null, CircleEntities[Difficulty]);
		EndRound();
	}
}

function GetPlayersNotInCircle(startingGameCount) {
	failedPlayers <- {};
	if (!GameOn || GameCount != startingGameCount) return failedPlayers;
	local gameplayers = GetGamePlayers();
	local radiusSquared = CircleRadius[Difficulty] * CircleRadius[Difficulty];
	foreach(gameplayer in gameplayers) {
		if (gameplayer != null) {
			local vectorToCenter = gameplayer.GetOrigin() - CirclePosition;
			if (vectorToCenter.Length2DSqr() > radiusSquared) {
				failedPlayers[gameplayer.entindex()] <- gameplayer;
				debugprint("Player not in circle: " + gameplayer);
			}
			else
				debugprint("Player in circle: " + gameplayer);
		}
	}
	EntFireByHandle(self, "RunScriptCode", "ChooseRandomCirclePosition(false)", ROUND_END_TIME, null, self);
	return failedPlayers;
}


/****************
 ***Side/Color***
 ****************/
function ChooseRandomSide(enabled) {
	if(enabled) {
		Side = RandomInt(0, 3);
		Colors = SIDE_COLORS[Side];
	} else {
		Colors = null;
		EndRound();
	}
}

function ChooseRandomColors(quantity) {
	if(quantity == false) {
		Colors = null;
		EndRound();
		return;
	}
	debugprint(COLORS_MIN[0]);
	Colors = {};
	local colorOptions = [0, 1, 2, 3, 4, 5, 6, 7, 8];
	ColorString = "";
	for (local i = 0; i < quantity; i++) {
		local colorIndex = RandomInt(0, colorOptions.len()-1);
		Colors[colorOptions[colorIndex]] <- true;
		debugprint("Color chosen: " + COLORS[colorOptions[colorIndex]] + " (" + colorIndex + ")");
		ColorString += COLORS[colorOptions[colorIndex]] + ((i == quantity - 1) ? "" : " or ");
		colorOptions.remove(colorIndex);
	}
	
}

function ChooseCorners(enabled) {
	if(!enabled) {
		Colors = null;
		EndRound();
		return;
	}
	Colors = {
		[0] = true, 
		[2] = true, 
		[6] = true, 
		[8] = true
	};
}

function IsPlayerOnColors(gameplayer) {
	if (Colors == null) return true;
	local playerOrigin = gameplayer.GetOrigin();
	foreach (color, val in Colors) {
		if (playerOrigin.x >= COLORS_MIN[color].x - PLAYER_WIDTH_HALF &&
			playerOrigin.x <= COLORS_MAX[color].x + PLAYER_WIDTH_HALF &&
			playerOrigin.y >= COLORS_MIN[color].y - PLAYER_WIDTH_HALF &&
			playerOrigin.y <= COLORS_MAX[color].y + PLAYER_WIDTH_HALF)
		{
			debugprint("Player on color " + COLORS[color] + ": " + gameplayer);
			return true;
		} else {
			debugprint("Player not on color " + COLORS[color] + ": " + gameplayer);
		}
	}
	return false;
}

function GetPlayersNotOnColors(startingGameCount) {
	failedPlayers <- {};
	if (!GameOn || GameCount != startingGameCount) return failedPlayers;
	local gameplayers = GetGamePlayers();
	foreach(gameplayer in gameplayers) {
		if (!IsPlayerOnColors(gameplayer)) {
			failedPlayers[gameplayer.entindex()] <- gameplayer;
		}
	}
	Colors = null;
	
	EntFireByHandle(self, "RunScriptCode", "EndRound()", ROUND_END_TIME, null, self);
	return failedPlayers;
}


/*****************
 ***Jump/Crouch***
 *****************/
function SetJump(enabled) {
	if (enabled) {
		EntFire("colors_jump_trigger", "Enable", "0.0", 0.0, null);
	} else {
		EndRound();
		EntFire("colors_jump_trigger", "Disable", "0.0", 0.0, null);
		foreach (gameplayer in SlowedPlayers) {
			if (gameplayer.IsValid() && gameplayer.GetHealth() > 0) {
				DoEntFire("speedmod", "ModifySpeed", "1.0", 0.0, gameplayer, gameplayer);
			}
		}
		SlowedPlayers = {};
	}
}

function PlayerJumped() {
	if (activator == null || !IsPlayerOnColors(activator)) {
		return;
	}
	
	SlowedPlayers[activator.entindex()] <- activator;
	DoEntFire("speedmod", "ModifySpeed", "0.0", 0.0, activator, activator);
	activator.SetVelocity(Vector(0, 0, 0));
}

function GetPlayersWhoDidNotJump(startingGameCount) {
	failedPlayers <- {};
	if (!GameOn || GameCount != startingGameCount) return failedPlayers;
	local gameplayers = GetGamePlayers();
	
	foreach(gameplayer in gameplayers) {
		local playerOrigin = gameplayer.GetOrigin();
		if (playerOrigin.z < GAME_MIN.z + 5)
		{
			failedPlayers[gameplayer.entindex()] <- gameplayer;
			debugprint("Player did not jump: " + gameplayer);
		}
		else 
			debugprint("Player jumped: " + gameplayer);
	}
	EntFireByHandle(self, "RunScriptCode", "SetJump(false)", ROUND_END_TIME, null, self);
	return failedPlayers;
}

function SetCrouch(enabled) {
	if (!enabled) {
		EndRound();
	}
}

function GetPlayersWhoDidNotCrouch(startingGameCount) {
	failedPlayers <- {};
	if (!GameOn || GameCount != startingGameCount) return failedPlayers;
	local gameplayers = GetGamePlayers();
	
	foreach(gameplayer in gameplayers) {
		if (gameplayer.GetBoundingMaxs().z > PLAYER_HEIGHT_CROUCHED + 1.0)
		{
			failedPlayers[gameplayer.entindex()] <- gameplayer;
			debugprint("Player did not crouch: " + gameplayer);
		}
		else 
			debugprint("Player crouched: " + gameplayer);
	}
	EntFireByHandle(self, "RunScriptCode", "SetCrouch(false)", ROUND_END_TIME, null, self);
	return failedPlayers;
}

/*************
 ***Ladders***
 *************/

function SetLadders(enabled) {
	if (enabled) {
		EntFire(LADDER_ENTITY_NAMES[Difficulty], "Enable", "0.0", 0.0, null);
		EntFire("colors_ladder", "Enable", "0.0", 0.0, null);
	} else {
		EntFire(LADDER_ENTITY_NAMES[Difficulty], "Disable", "0.0", 0.0, null);
		EntFire("colors_ladder", "Disable", "0.0", 0.0, null);
		EndRound();
	}
}

function GetPlayersNotOnLadders(startingGameCount) {
	failedPlayers <- {};
	if (!GameOn || GameCount != startingGameCount) return failedPlayers;
	local gameplayers = GetGamePlayers();
	
	local zMin = GAME_MIN.z + PLAYER_JUMP_HEIGHT + 1.0;
	foreach(gameplayer in gameplayers) {
		local playerOrigin = gameplayer.GetOrigin();
		if (playerOrigin.z < zMin)
		{
			failedPlayers[gameplayer.entindex()] <- gameplayer;
			debugprint("Player not on ladder: " + gameplayer);
		}
		else 
			debugprint("Player on ladder: " + gameplayer);
	}
	EntFireByHandle(self, "RunScriptCode", "SetLadders(false)", ROUND_END_TIME, null, self);
	return failedPlayers;
}

/*************
 ***Movement***
 *************/

function SetMovement(enabled) {
	if (enabled) {
	
	} else {
		ExpectedPlayerSpeed = 0;
		EndRound();
	}
}

function GetPlayersNotAtSpeed(startingGameCount) {
	failedPlayers <- {};
	if (!GameOn || GameCount != startingGameCount) return failedPlayers;
	local gameplayers = GetGamePlayers();
	
	local minSpeed = ExpectedPlayerSpeed - SPEED_LEEWAY;
	local maxSpeed = ExpectedPlayerSpeed + 1;
	foreach(gameplayer in gameplayers) {
		local playerSpeed = gameplayer.GetVelocity().Length2DSqr();
		if (playerSpeed < minSpeed || playerSpeed > maxSpeed)
		{
			failedPlayers[gameplayer.entindex()] <- gameplayer;
			debugprint("Player not going proper speed: " + gameplayer + "(" + playerSpeed.tostring() + " vs " + ExpectedPlayerSpeed.tostring() + ")");
		}
		else 
			debugprint("Player going proper speed: " + gameplayer + "(" + playerSpeed.tostring() + " vs " + ExpectedPlayerSpeed.tostring() + ")");
	}
	EntFireByHandle(self, "RunScriptCode", "SetMovement(false)", ROUND_END_TIME, null, self);
	return failedPlayers;
}

/**************
 *****Help*****
 **************/

function DisplayHelpText()
{
	if (GameOn) return;
	DisplayTextToGamePlayers("Instructions\n1. Follow the instruction(s) shown.\n2. If two instructions are shown, you must complete both.\n3. If you stop completing the instruction before it\ndisappears, you will take damage.");
}

function DisplayTextToGamePlayers(text)
{
	local gameplayers = GetGamePlayers();
	foreach (ply in gameplayers)
	{
		DisplayText(ply, text);
	}
}

function DisplayText(ply, text)
{
	local game_txt = GameTextEntities[ply.entindex()];
	if (game_txt != null)
	{
		game_txt.__KeyValueFromString("message", text);
		EntFireByHandle(game_txt,"Display","",0.01,ply,ply);
	}
}
