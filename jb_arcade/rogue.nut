//===============================
//=====       ROGUE         =====
//=====       BY            =====
//=====       THORGOT       =====
//===============================

//Game constants
const GAME_SIZE = 64;
const GAME_HEIGHT = 7;
const DRAW_X = 15;
const DRAW_Y = 7;
const LASER_START_X = 26;
const LASER_END_X = 37;
TileTypeToChar <- {};
enum directions {
	up,
	down,
	left,
	right,
	none
}
enum TileType {
	player,
	wall,
	door_closed,
	door_open,
	door_and_player,
	trap,
	laser_firing,
	laser_fired,
	treasure
}
TRAP_PATTERN_0 <- [
	"^...^..",
	"^.^.^.^",
	"^.^.^.^",
	"^.^.^.^",
	"..^...^"
];
TRAP_PATTERN_1 <- [
	"..........",
	".^^^^^^^^.",
	".^$.......",
	".^^^^^^^^.",
	".........."
];
TRAP_PATTERNS <- [TRAP_PATTERN_0, TRAP_PATTERN_1];

//Entity cache
GameText <- array(GAME_HEIGHT);


//Game state
GameBoard <- array(GAME_SIZE);
PlayerX <- 3;
PlayerY <- 3;
GameWon <- false;

DEBUG<-true;
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function Setup() {
	PlayerX <- 3;
	PlayerY <- 3;
	for (local i = 0; i < GAME_SIZE; i++) {
		GameBoard[i] = array(GAME_HEIGHT, TileType.wall);
	}
	
	GenerateRoom(0, 6, 0, 6);
	GenerateRoom(11, 20, 0, 6);
	GenerateRoom(25, 38, 0, 6);
	GenerateRoom(45, 56, 0, 6);
	GenerateHallway(6, 11, 5);
	GenerateHallway(20, 25, 5);
	GenerateHallway(38, 45, 3);
	GenerateTraps(12, 0);
	GenerateTraps(46, 1);
	GameBoard[PlayerX][PlayerY] = TileType.player;
	
	TileTypeToChar[TileType.player] <- "@";
	TileTypeToChar[TileType.wall] <- "#";
	TileTypeToChar[TileType.door_closed] <- "+";
	TileTypeToChar[TileType.door_open] <- "'";
	TileTypeToChar[TileType.door_and_player] <- "@";
	TileTypeToChar[TileType.trap] <- "^";
	TileTypeToChar[TileType.laser_firing] <- "v";
	TileTypeToChar[TileType.laser_fired] <- "^";
	TileTypeToChar[TileType.treasure] <- "$";
	
	for (local i = 0; i < DRAW_Y; i++) {
		GameText[i] = Entities.FindByName(null, "rogue_text" + (i + 1));
	}
	
	LogGameBoard();
	DisplayGameBoard();
}

function GenerateRoom(xMin, xMax, yMin, yMax) {
	//Draw walls
	for (local x = xMin; x <= xMax; x++) {
		GameBoard[x][yMin] = TileType.wall;
		GameBoard[x][yMax] = TileType.wall;
	}
	for (local y = yMin+1; y < yMax; y++) {
		GameBoard[xMin][y] = TileType.wall;
		GameBoard[xMax][y] = TileType.wall;
	}
	//Draw floors
	for (local y = yMin+1; y < yMax; y++) {
		for (local x = xMin+1; x < xMax; x++) {
			GameBoard[x][y] = null;
		}
	}
}

function GenerateHallway(xMin, xMax, y) {
	for (local x = xMin; x <= xMax; x++) {
		GameBoard[x][y] = null;
	}
	GameBoard[xMin][y] = TileType.door_closed;
	GameBoard[xMax][y] = TileType.door_closed;
}

function GenerateTraps(xStart, pattern) {
	debugprint("TRAP_PATTERN[0].len() = " + TRAP_PATTERNS[pattern][0].len());
	for (local y = 0; y < GAME_HEIGHT - 2; y++) {
		for (local x = xStart; x < xStart + TRAP_PATTERNS[pattern][0].len(); x++) {
		
			switch (TRAP_PATTERNS[pattern][y][x - xStart]) {
				case '^':
					GameBoard[x][y+1] = TileType.trap;
					break;
				case '$':
					if (!GameWon) {
						GameBoard[x][y+1] = TileType.treasure;
					}
					break;
				case '.':
					GameBoard[x][y+1] = null;
					break;
				default:
					break;
			}
		}
	}
}

function LogGameBoard() {
	for (local y = 0; y < GAME_HEIGHT; y++) {
		local line = "";
		for (local x = 0; x < GAME_SIZE; x++) {
			if (GameBoard[x][y] == null) {
				line += ".";
			} else {
				line += TileTypeToChar[GameBoard[x][y]];
			}
		}
		debugprint(line);
	}
}

function DisplayGameBoard() {
	local yMin = PlayerY - DRAW_Y / 2; //TODO remove
	local yMax = PlayerY + DRAW_Y / 2; //TODO remove
	local xMin = PlayerX - DRAW_X / 2;
	local xMax = PlayerX + DRAW_X / 2;
	local line = 0;
	for (local y = 0; y < DRAW_Y; y++) {
		local text = "";
		for (local x = xMin; x < xMax; x++) {
			if (x < 0 || x >= GAME_SIZE || y < 0 || y >= GAME_HEIGHT) {
				text += TileTypeToChar[TileType.wall];
			} else if (GameBoard[x][y] == null) {
				text += ".";
			} else {
				text += TileTypeToChar[GameBoard[x][y]];
			}
		}
		debugprint("Line " + line + " is " + text);
		GameText[line++].__KeyValueFromString("message", text);
	}
}

function Move(direction) {
	switch (direction) {
		case directions.up:
			AttemptMoveTo(PlayerX, PlayerY - 1);
			break;
		case directions.down:
			AttemptMoveTo(PlayerX, PlayerY + 1);
			break;
		case directions.left:
			AttemptMoveTo(PlayerX - 1, PlayerY);
			break;
		case directions.right:
			AttemptMoveTo(PlayerX + 1, PlayerY);
			break;
		case directions.none:
			AttemptMoveTo(PlayerX, PlayerY);
			break;
	}
	LogGameBoard(); //TODO remove
	DisplayGameBoard();
}

function AttemptMoveTo(x, y) {
	if (GameBoard[x][y] == TileType.treasure) {
		EntFire("secret_teleportation_template", "ForceSpawn", "", 0.0, activator);
		GameWon = true;
	}

	if (GameBoard[x][y] == null || GameBoard[x][y] == TileType.door_open || GameBoard[x][y] == TileType.treasure || (x == PlayerX && y == PlayerY)) {
		if (GameBoard[PlayerX][PlayerY] == TileType.door_and_player) {
			GameBoard[PlayerX][PlayerY] = TileType.door_open;
		} else {
			GameBoard[PlayerX][PlayerY] = null;
		}
		PlayerX = x;
		PlayerY = y;
		if (GameBoard[PlayerX][PlayerY] == TileType.door_open) {
			GameBoard[PlayerX][PlayerY] = TileType.door_and_player;
		} else {
			GameBoard[PlayerX][PlayerY] = TileType.player;
		}
		AdvanceLasers()
	} else if (GameBoard[x][y] == TileType.door_closed) {
		GameBoard[x][y] = TileType.door_open;
		AdvanceLasers()
	} else if (GameBoard[x][y] == TileType.trap) {
		Setup();
	}
}

function AdvanceLasers() {
	//Build list of potential laser locations that are not next to fired or firing lasers
	local potentialLaserLocations = [];
	for (local x = LASER_START_X; x <= LASER_END_X; x++) {
		if (GameBoard[x][0] == TileType.wall && GameBoard[x-1][0] == TileType.wall && GameBoard[x+1][0] == TileType.wall) {
			potentialLaserLocations.push(x);
			debugprint("potentialLaserLocations: pushed " + x);
		}
	}
	debugprint("potentialLaserLocations.len(): " + potentialLaserLocations.len());
	
	//Remove old lasers and fire new ones
	for (local x = LASER_START_X; x <= LASER_END_X; x++) {
		if (GameBoard[x][0] == TileType.laser_fired) {
			GameBoard[x][0] = TileType.wall;
			for (local y = 1; y < GAME_HEIGHT-1; y++) {
				GameBoard[x][y] = null;
			}
		}
		if (GameBoard[x][0] == TileType.laser_firing) {
			GameBoard[x][0] = TileType.laser_fired;
			for (local y = 1; y < GAME_HEIGHT-1; y++) {
				if (GameBoard[x][y] == TileType.player) {
					Setup();
					return;
				}
				GameBoard[x][y] = TileType.trap;
			}
		}
	}
	
	//Setup next lasers
	if (potentialLaserLocations.len() > 0) {
		local laserLocations = [potentialLaserLocations[RandomInt(0, potentialLaserLocations.len() - 1)], potentialLaserLocations[RandomInt(0, potentialLaserLocations.len() - 1)]];
		//Prevent auto-lose scenario where two lasers at the end of the hallway fire at the same time
		if ((laserLocations[0] == LASER_END_X && laserLocations[1] == LASER_END_X - 1) || (laserLocations[1] == LASER_END_X && laserLocations[0] == LASER_END_X - 1)) {
			debugprint("preventing laserLocation " + laserLocations[0].tostring() + " and laserLocation " + laserLocations[1].tostring() + " from firing at the same time");
			laserLocations[1] = laserLocations[0];
		}
		
		foreach(laserLocation in laserLocations) {
			debugprint("Chose laser location " + laserLocation);
			GameBoard[laserLocation][0] = TileType.laser_firing;
		}
	}
	
}
