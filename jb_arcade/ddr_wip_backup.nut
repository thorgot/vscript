
const MAX_PLAYERS = 64;
const ASCII_NEWLINE = 10;
const ASCII_COMMA = 44;
const ASCII_ZERO = 48;
const ASCII_ONE = 49;
const ASCII_TWO = 50;
const ASCII_THREE = 51;
DIRECTION_TEXT<-["LEFT", "DOWN", "UP", "RIGHT"];
const DIRECTION_LEFT = 0;
const DIRECTION_DOWN = 1;
const DIRECTION_UP = 2;
const DIRECTION_RIGHT = 3;

const POINTS_PER_BEAT = 10;

GAME_MIN <- Vector(1243.0, -1728.0, -482.0);
GAME_MAX <- Vector(1755.0, -1472.0, -128.0);

GameActive <- false;
SongStart <- 0.0;
songNumber <- 0;
currentIndex <- -1;
currentBeatsPerMeasure <- 0;
drawnBeatsPerMeasure <- 0;
line <- "";
measure <- 0;
beat <- 0;
beatDisplayed <- 0;
currentDirections<-[false, false, false, false];
directionHeld<-[false, false, false, false];
displayHold<-[false, false, false, false];
scores<-array(MAX_PLAYERS+1);
scoredThisBeat<-array(MAX_PLAYERS+1);
holdingLeft<-array(MAX_PLAYERS+1);
holdingDown<-array(MAX_PLAYERS+1);
holdingUp<-array(MAX_PLAYERS+1);
holdingRight<-array(MAX_PLAYERS+1);
holding<-[holdingLeft, holdingDown, holdingUp, holdingRight];
playerEntities<-{};
GameTextEntities<-array(MAX_PLAYERS+1);
SpeedEntity<-null;

const NUM_SONGS = 4;
songNotes<-array(NUM_SONGS);
songLines<-array(NUM_SONGS);
songTimeNoteDisplayed<-array(NUM_SONGS);
songTimeNotePlayed<-array(NUM_SONGS);
songMinBeatTime<-array(NUM_SONGS);
songSecondsPerBeat<-array(NUM_SONGS);
songBeatsPerMeasure<-array(NUM_SONGS);
songVolume<-array(NUM_SONGS);
songOffset<-array(NUM_SONGS, 0.0);
songDisplayOffset<-array(NUM_SONGS, 0.0);
const BASE_NOTE_MOVEMENT_SPEED = 96;
songNoteMovementSpeed<-null;
const BASE_BEATS_PER_MEASURE = 4;


DEBUG_PRINT<-true
function debugprint(text)
{
	if (!DEBUG_PRINT || GetDeveloperLevel()	== 0) return;
	printl("*************" + text + "*************")
}

function OnPostSpawn() { //Called after the logic_script spawns
	//EntFireByHandle(self, "RunScriptCode", "Setup()", 0.5, null, null)
}

function Setup() {
	for (local i = 1; i < MAX_PLAYERS+1; i++) {
		GameTextEntities[i] = Entities.FindByName(null,"display_score_" + i);
	}
	SpeedEntity = Entities.FindByName(null, "blob_speed");
	
	for (local i = 0; i < 4; i++) { 
		EntityGroup[i].__KeyValueFromString("message", "");
	}
	
	local noteIndex = 0;
	local noteLine = "";
	for (songNumber = 1; songNumber <= 1 ; songNumber++) {
		local beatsPerMeasure = getBeatsPerMeasure(0) + 1;
		debugprint("=SONG " + songNumber + "=");
		local measureNumber = 0;
		local lineNumber = 0;
		local previousTimeNotePlayed = 0.0;
		songLines[songNumber] = array(512, 0.0);
		songTimeNotePlayed[songNumber] = array(512, 0.0);
		songTimeNoteDisplayed[songNumber] = array(512, 0.0);
		songBeatsPerMeasure[songNumber] = array(512, 0.0);
		songMinBeatTime[songNumber] = 2.0;
		while (noteIndex <= songNotes[songNumber].len()) {
			noteLine = getNextLine(songNotes[songNumber], noteIndex, 1);
			songLines[songNumber][lineNumber] = noteLine;
			local timeForNote = songSecondsPerBeat[songNumber] * 4 / beatsPerMeasure;
			if (timeForNote < songMinBeatTime[songNumber]) songMinBeatTime[songNumber] = timeForNote;
			songTimeNotePlayed[songNumber][lineNumber] = previousTimeNotePlayed + timeForNote;
			songTimeNoteDisplayed[songNumber][lineNumber] = songTimeNotePlayed[songNumber][lineNumber] - (timeForNote * 2);// - songDisplayOffset[songNumber];
			previousTimeNotePlayed = songTimeNotePlayed[songNumber][lineNumber];
			songBeatsPerMeasure[songNumber][lineNumber] = beatsPerMeasure;
			debugprint("Line " + lineNumber + ": " + noteLine + " (" + beatsPerMeasure + " bpm, " + timeForNote + "s) to be displayed at " + songTimeNoteDisplayed[songNumber][lineNumber] + " and played at " + songTimeNotePlayed[songNumber][lineNumber]);
			lineNumber ++;
			noteIndex += noteLine.len() + 1;
			if (noteIndex >= songNotes[songNumber].len()) continue;
			if (songNotes[songNumber][noteIndex] == ASCII_COMMA) {
				beatsPerMeasure = getBeatsPerMeasure(noteIndex);
				debugprint("number of beats in the next measure: " + beatsPerMeasure);
				
				noteIndex = songNotes[songNumber].find("\n", noteIndex) + 1;
				measureNumber++;
				debugprint("==MEASURE " + measureNumber + "==");
			}
		}
		debugprint("songMinBeatTime: " + songMinBeatTime[songNumber]);
	}
	songNumber = 0;
}

function DisplayText(ply, text) {
	local game_txt = GameTextEntities[ply.entindex()];
	if (game_txt != null)
	{
		game_txt.__KeyValueFromString("message", text);
		EntFireByHandle(game_txt,"Display","",0.01,ply,ply);
	}
}
function testFunction() {
	local lineStart = -1;
	local line = "";
	while (line != null) {
		lineStart += line.len() + 1;
		debugprint("new lineStart: " + lineStart);
		line = getNextLine(songNotes[songNumber], lineStart, 1);
		debugprint(line);
	}
}

function addActivator() {
	addPlayer(activator);
}

function addPlayer(ply) {
	if (ply == null || !ply.IsValid()) return;
	
	local playerOrigin = ply.GetOrigin();
	if (playerOrigin.x >= GAME_MIN.x && playerOrigin.x <= GAME_MAX.x &&
		playerOrigin.y >= GAME_MIN.y && playerOrigin.y <= GAME_MAX.y &&
		playerOrigin.z >= GAME_MIN.z && playerOrigin.z < GAME_MAX.z) {
		
		playerEntities[ply.entindex()] <- ply;
		EntFire("ddr_game" + ply.entindex(), "Activate", "", 0.0, ply);
		EntFireByHandle(SpeedEntity, "ModifySpeed", ".99", 0, ply, null);
	}
}

function removeAllPlayers() {
	for (local i = 0; i < MAX_PLAYERS+1; i++) {
		if (i in playerEntities && playerEntities[i].IsValid()) {
			removePlayer(i);
		}
	}
}

function removePlayer(index) {
	DoEntFire("ddr_game"+index, "Deactivate", "", 0.00, self, null) //CRASHES GAME WITH NO ACTIVATOR
	EntFireByHandle(SpeedEntity, "ModifySpeed", "1.0", 0, playerEntities[index], null);
	delete playerEntities[index];
}

function displayScore(index) {
	DisplayText(playerEntities[index], "Score: " + scores[index]);
}

function displayScores() {
	//TODO limit to players in the game
	for (local i = 0; i < MAX_PLAYERS+1; i++) {
		if (i in playerEntities && playerEntities[i].IsValid()) {
			displayScore(i);
		}
	}
}

function startSong(num) {
	if (GameActive) return;
	currentBeatsPerMeasure = 4;
	SongStart = Time();
	songNumber = num;
	songNoteMovementSpeed = (BASE_NOTE_MOVEMENT_SPEED / songSecondsPerBeat[songNumber]);
	GameActive = true;
	beat = 0;
	beatDisplayed = 3;
	measure = 1;
	playerEntities = {};
	local gameplayer = null;
	while((gameplayer = Entities.FindByClassname(gameplayer,"player")) != null) {
		addPlayer(gameplayer);
	}
	line = "";
	currentIndex = 0;
	for (local i = 0; i < MAX_PLAYERS+1; i++) {
		scores[i] = 0;
		scoredThisBeat[i] = array(4, false);
		for (local j = 0; j < 4; j++) {
			holding[j][i] = false;
		}
	}
	directionHeld = [false, false, false, false];
	currentDirections = [false, false, false, false];
	
	EntFire("ddr_song" + songNumber, "Volume", songVolume[songNumber], songOffset[songNumber], self);
	EntFireByHandle(self, "RunScriptCode", "playNextBeat()", 0.0, self, self);
}

function getPlayerEntity(entindex) {
	if (entindex in playerEntities) {
		return playerEntities[entindex];
	}
	return null;
}

function stopSong() {
	EntFire("ddr_song" + songNumber, "Volume", "0", 0.0, self);
	line = null;
	removeAllPlayers();
	GameActive = false;
	EntFire("ddr_arrow0", "Kill", "", 0.0, self);
	EntFire("ddr_arrow1", "Kill", "", 0.0, self);
	EntFire("ddr_arrow2", "Kill", "", 0.0, self);
	EntFire("ddr_arrow3", "Kill", "", 0.0, self);
	EntFire("ddr_arrow_hold0", "Kill", "", 0.0, self);
	EntFire("ddr_arrow_hold1", "Kill", "", 0.0, self);
	EntFire("ddr_arrow_hold2", "Kill", "", 0.0, self);
	EntFire("ddr_arrow_hold3", "Kill", "", 0.0, self);
}

function getBeatsPerMeasure(index) {
	local nextComma = songNotes[songNumber].find(",", index+1);
	if (nextComma == null) {
		return 4;
	}
	//debugprint("nextComma at " + nextComma);
	local nextMeasure = songNotes[songNumber].slice(index, nextComma-1);
	//debugprint("nextMeasure: " + nextMeasure);
	return count(nextMeasure, "\n");
}

function playNextBeat() {
	//Song ended
	if (line == null) {
		return;
	}
	
	
	
	//Award points for holds
	for (local j = 0; j < MAX_PLAYERS+1; j++) {
		scoredThisBeat[j] = array(4, false);
		for (local i = 0; i < 4; i++) {
			if (holding[i][j]) {
				local ply = getPlayerEntity(j);
				if (directionHeld[i]) {
					scores[j] += POINTS_PER_BEAT;
					if (ply != null) EntFire("ddr_text_success","Display","",0.0,ply);
				} else {
					scores[j] -= POINTS_PER_BEAT;
					if (ply != null) EntFire("ddr_text_fail","Display","",0.0,ply);
				}
				debugprint("new score: " + scores[j]);
			}
		}
	}
	
	
	//Get next line
	local timeIntoSong = Time() - SongStart;
	local drift = timeIntoSong - songTimeNotePlayed[songNumber][beat];
	debugprint("drift on line " + beat + ": " + drift);
	if (timeIntoSong >= songTimeNotePlayed[songNumber][beat]) {
		currentIndex += line.len() + 1;
		if (currentIndex >= songNotes[songNumber].len()) return;
		if (songNotes[songNumber][currentIndex] == ASCII_COMMA) {
			currentBeatsPerMeasure = getBeatsPerMeasure(currentIndex);
			debugprint("number of beats in the next measure: " + currentBeatsPerMeasure);
			
			currentIndex = songNotes[songNumber].find("\n", currentIndex) + 1;
			measure++;
			debugprint("==MEASURE " + measure + "==");
		}
		if (currentIndex >= songNotes[songNumber].len()) return;
		line = getNextLine(songNotes[songNumber], currentIndex, 1);
		beat++;
		
		local timeToNextBeat = songSecondsPerBeat[songNumber] * 4 / currentBeatsPerMeasure;
		debugprint("beat " + beat + ": at mp3 time " + timeIntoSong);
		
		//Turn on next beat
		for (local i = 0; i < 4; i++) {
			if (line == null || line[i] == ASCII_ZERO) {
				debugprint("direction " + DIRECTION_TEXT[i] + " off");
				EntityGroup[i].__KeyValueFromString("message", "");
				currentDirections[i] = false;
			} else if (line[i] == ASCII_ONE) {
				debugprint("direction " + DIRECTION_TEXT[i] + " on");
				EntityGroup[i].__KeyValueFromString("message", DIRECTION_TEXT[i]);
				EntityGroup[i].__KeyValueFromString("color", "255 255 255");
				currentDirections[i] = true;
			} else if (line[i] == ASCII_TWO) {
				debugprint("direction " + DIRECTION_TEXT[i] + " start hold");
				EntityGroup[i].__KeyValueFromString("message", DIRECTION_TEXT[i]);
				EntityGroup[i].__KeyValueFromString("color", "1 255 1");
				currentDirections[i] = false;
				directionHeld[i] = true;
			} else if (line[i] == ASCII_THREE) {
				debugprint("direction " + DIRECTION_TEXT[i] + " end hold");
				EntityGroup[i].__KeyValueFromString("message", DIRECTION_TEXT[i]);
				EntityGroup[i].__KeyValueFromString("color", "255 1 1");
				currentDirections[i] = false;
				EntFireByHandle(self, "RunScriptCode", "turnOffDirectionHeld(" + i + ")", timeToNextBeat, self, self);
			}
		}
	}
	

	
	//seed drawnBeatsPerMeasure
	if (drawnBeatsPerMeasure == 0 ) getNextLine(songNotes[songNumber], currentIndex, 3);
	
	//Draw future beats
	if (timeIntoSong >= songTimeNoteDisplayed[songNumber][beatDisplayed]) {

		local lineToDraw = songLines[songNumber][beatDisplayed];
		local spawnTime = 0.02;
		local moveTime = spawnTime + 0.02;
		local noteMovementSpeed = (songNoteMovementSpeed * (songBeatsPerMeasure[songNumber][beatDisplayed] / 4)).tostring();
		debugprint("displaying beatDisplayed #" + beatDisplayed + " : " + lineToDraw + " (timeIntoSong: " + timeIntoSong + ", noteMovementSpeed: " + noteMovementSpeed + ")");
		for (local i = 0; i < 4; i++) {
			if (lineToDraw == null || lineToDraw == 0 || lineToDraw[i] == ASCII_ZERO) {
				if (displayHold[i]) {
					EntFire("ddr_arrow_hold" + i + "_template", "ForceSpawn", "", spawnTime, null);
					EntFire("ddr_arrow_hold" + i, "Open", "", moveTime, null);
					EntFire("ddr_arrow_hold" + i, "SetSpeed", noteMovementSpeed, moveTime, null);
					EntFire("ddr_arrow_hold" + i, "AddOutput", "targetname ddr_arrow_hold_moving" + i, moveTime + 0.02, null);
				}
			} else if (lineToDraw[i] == ASCII_ONE) {
				debugprint("direction " + DIRECTION_TEXT[i] + " drawing");
				EntFire("ddr_arrow" + i + "_template", "ForceSpawn", "", spawnTime, null);
				EntFire("ddr_arrow" + i, "Open", "", moveTime, null);
				EntFire("ddr_arrow" + i, "SetSpeed", noteMovementSpeed, moveTime, null);
				EntFire("ddr_arrow" + i, "AddOutput", "targetname ddr_arrow_moving" + i, moveTime + 0.02, null);
			} else if (lineToDraw[i] == ASCII_TWO) {
				debugprint("hold " + DIRECTION_TEXT[i] + " drawing");
				EntFire("ddr_arrow_hold" + i + "_template", "ForceSpawn", "", spawnTime, null);
				EntFire("ddr_arrow_hold" + i, "Open", "", moveTime, null);
				EntFire("ddr_arrow_hold" + i, "SetSpeed", noteMovementSpeed, moveTime, null);
				EntFire("ddr_arrow_hold" + i, "AddOutput", "targetname ddr_arrow_hold_moving" + i, moveTime + 0.02, null);
				displayHold[i] = true;
			} else if (lineToDraw[i] == ASCII_THREE) {
				EntFire("ddr_arrow" + i + "_template", "ForceSpawn", "", spawnTime, null);
				EntFire("ddr_arrow" + i, "Open", "", moveTime, null);
				EntFire("ddr_arrow" + i, "SetSpeed", noteMovementSpeed, moveTime, null);
				EntFire("ddr_arrow" + i, "AddOutput", "targetname ddr_arrow_moving" + i, moveTime + 0.02, null);
				displayHold[i] = false;
			}
		}
		beatDisplayed++;
	}
	
	displayScores();
	EntFireByHandle(self, "RunScriptCode", "playNextBeat()", songMinBeatTime[songNumber] - drift, self, self);
}

function turnOffDirectionHeld(direction) {
	directionHeld[direction] = false;
}

function getNextLine(str, start, numberOfLinesAhead) {
	//debugprint("Called getNextLine with params " + start + "," + numberOfLinesAhead);
	local nextLine = null;
	local index = start;
	for (local i = 0; i < numberOfLinesAhead; i++) {
		//if (str[index] == ASCII_NEWLINE) index++;
		if (numberOfLinesAhead > 1 && index < str.len() && str[index] == ASCII_COMMA) {
			i--;
			drawnBeatsPerMeasure = getBeatsPerMeasure(index);
			debugprint("number of beats in the drawn measure: " + drawnBeatsPerMeasure);
		}
		local eol = str.find("\n", index);
		//debugprint("eol: " + eol);
		if (eol == null) return str.slice(index);
		nextLine = str.slice(index, eol);
		//debugprint("nextLine " + nextLine + " index: " + index + " eol: " + eol + "(numberOfLinesAhead: " + numberOfLinesAhead + ")");
		index += nextLine.len() + 1;
		//debugprint("index: " + index);
	}
	return nextLine;
}

function SetDirection(direction) {
	if (activator == null || !(activator.IsValid())) return;
	
	local entindex = activator.entindex();
	debugprint(entindex + " pressed direction " + direction + ": " + currentDirections[direction]);
	holding[direction][entindex] = true;
	if (!scoredThisBeat[entindex][direction]) {
		if (currentDirections[direction]) {
			scoredThisBeat[entindex][direction] = true;
			scores[entindex] += POINTS_PER_BEAT;
			holding[direction][entindex] = false;
			EntFire("ddr_text_success","Display","",0.0,activator);
			displayScore(entindex);
		} else if (!directionHeld[direction]) {
			scores[entindex] -= POINTS_PER_BEAT;
			EntFire("ddr_text_fail","Display","",0.0,activator);
			displayScore(entindex);
		}
	}
	debugprint("new score: " + scores[entindex]);
}

function StopDirection(direction) {
	if (activator == null || !(activator.IsValid())) return;
	
	holding[direction][activator.entindex()] = false;
}

function count(str, characterToMatch) {
	if (str == null) return 0;
	local charInt = characterToMatch[0];
	local total = 0;
	foreach (char in str) {
		if (char == charInt) {
			total++;
		}
	}
	//debugprint("string contains " + total + " occurences of " + charInt);
	return total;
}

//supermassive black hole
songVolume[0] = "2";
songSecondsPerBeat[0] = 0.5;
// EASY
songNotes[0] = @"0000
0000
0000
0000
,  // measure 2
0000
0000
0000
0000
,  // measure 3
0000
0000
0000
0000
,  // measure 4
0000
0000
0000
0000
,  // measure 5
0000
1000
0000
1000
,  // measure 4
0000
0000
0000
0000
,  // measure 6
0000
1000
0000
1000
,  // measure 7
0000
0001
0000
0001
,  // measure 8
0000
0002
0000
0000
,  // measure 9
0003
0001
0000
0001
,  // measure 10
0000
0010
0000
0010
,  // measure 11
0000
0100
0000
0100
,  // measure 12
0000
1000
0000
1000
,  // measure 13
0000
0001
0000
0001
,  // measure 14
0000
0100
0000
0100
,  // measure 15
0000
0010
0000
0010
,  // measure 16
0000
2000
0000
0000
,  // measure 17
3000
1001
0000
0000
,  // measure 18
0000
1001
0000
0000
,  // measure 19
0000
0110
0000
0000
,  // measure 20
0000
0110
0000
0000
,  // measure 21
0000
1100
0000
0000
,  // measure 22
0000
0011
0000
0000
,  // measure 23
0000
0101
0000
0000
,  // measure 24
0000
2020
0000
0000
,  // measure 25
3030
0001
0000
0100
,  // measure 26
0000
1000
0000
0010
,  // measure 27
0000
0001
0000
1000
,  // measure 28
0000
0001
0000
1000
,  // measure 29
0000
0001
0000
0010
,  // measure 30
0000
1000
0000
0100
,  // measure 31
0000
0001
0000
1000
,  // measure 32
0000
0002
0000
0000
,  // measure 33
0003
1000
0000
0010
,  // measure 34
0000
0001
0000
0100
,  // measure 35
0000
1000
0000
0001
,  // measure 36
0000
1000
0000
0001
,  // measure 37
0000
1000
0000
0100
,  // measure 38
0000
0001
0000
0010
,  // measure 39
0000
1000
0000
0001
,  // measure 40
0000
1000
0000
0000
,  // measure 41
0001
0000
0000
0000
,  // measure 42
1001
0000
0000
0000
,  // measure 43
1000
0000
0000
0000
,  // measure 44
1001
0000
0000
0000
,  // measure 45
0001
0000
0000
0000
,  // measure 46
1001
0000
0000
0000
,  // measure 47
1000
0000
0000
0000
,  // measure 48
2002
0000
3003
0000";

//born this way
songVolume[1] = "5";
songSecondsPerBeat[1] = 0.483871;
songOffset[1] = songSecondsPerBeat[1];
/* BEGINNER
songNotes[1] = @"0000
0000
0000
0000
,
0001
0000
0000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
1000
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
0001
0000
0000
0000
,
0001
0000
1000
0000
,
0001
0000
0000
0000
,
0100
0000
0010
0000
,
0100
0000
0000
0000
,
1000
0000
0000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
0001
0000
,
1000
0000
0000
0000
,
0001
0000
0010
0000
,
0001
0000
0000
0000
,
1000
0000
0000
0000
,
0010
0000
0000
0000
,
0001
0000
0000
0000
,
0100
0000
0000
0000
,
0100
0000
0010
0000
,
0001
0000
0000
0000
,
0001
0000
0010
0000
,
1000
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
0000
0000
,
0010
0000
1000
0000
,
0001
0000
0000
0000
,
0001
0000
0010
0000
,
1000
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
0001
0000
0100
0000
,
1000
0000
0000
0000
,
0100
0000
1000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
0100
0000
0000
0000
,
0010
0000
0000
0000
,
0010
0000
0000
0000
,
1000
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
0001
0000
0000
0000"
*/
//EASY
songNotes[1] = @"1000
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
0100
0000
1000
0000
,
0001
0000
0100
0000
,
0010
0000
0001
0000
,
1000
0100
0010
0000
,
0100
0000
1000
0000
,
0001
0000
1000
0000
,
0100
0000
1000
0000
,
2000
3001
0002
1003
,
1000
0000
0001
0000
,
1000
0000
0001
0000
,
0010
0100
1000
0000
,
0100
0000
1000
0000
,
0001
0000
1000
0000
,
0001
0000
0010
0000
,
0001
0010
0100
1000
,
0200
0300
0000
1000
,
0010
0100
0001
0000
,
0010
1000
0100
0000
,
0100
0001
0100
0000
,
1001
0001
1000
0000
,
0010
0100
0001
0000
,
0100
0010
1000
0000
,
1000
0001
0010
0000
,
0110
0010
0010
0000
,
0001
1000
0002
0003
,
1000
0001
2000
3000
,
0010
0000
0100
0000
,
0010
0000
0001
0000
,
0010
0100
0020
0030
,
0100
0010
0200
0300
,
0100
1000
0001
0000
,
1000
0000
0001
0000
,
1000
0100
0010
0000
,
0001
0010
0100
0000
,
1000
0000
0010
0000
,
0100
0000
0001
0000
,
0001
1000
0001
0000
,
1000
0001
1000
0000
,
0100
0000
0010
0000
,
0100
0000
0010
0000
,
2000
0000
3000
0000
,
0001
0000
0000
0000
,
0002
0000
0003
0000
,
1000
0000
0000
0000
,
0200
0000
0300
0000
,
0010
0000
0000
0000
,
0020
0000
0030
0000
,
0100
0000
0000
0001";

//through the fire and flames
songVolume[2] = "5";
songSecondsPerBeat[2] = 0.3;
songOffset[2] = 0.55;
songNotes[2] = @"0000
0000
0000
0000
,
0000
0000
0000
0000
,
0000
0000
0000
0000
,
0000
0000
0000
0000
,
1000
0000
0000
0000
,
0000
0000
0000
0000
,
0100
0000
0000
0000
,
0010
0000
0000
0000
,
0001
0000
0000
0000
,
0000
0000
0000
0000
,
0100
0000
0000
0000
,
0000
0000
0000
0000
,
0010
0000
0000
0000
,
0000
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0001
0001
0000
,
1000
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
0001
0000
0000
0000
,
0010
0000
0000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
0100
0000
0000
0000
,
1000
0000
0000
0000
,
1000
0000
0000
0000
,
0010
0000
0000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
0100
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
1000
0000
,
1000
0000
0000
0000
,
0000
0000
0000
0000
,
0010
0000
0000
0000
,
0000
0000
0000
0000
,
1000
0000
0000
0000
,
0000
0000
0000
0000
,
0001
0000
0000
0000
,
0010
0000
0001
0000
,
1000
0000
1000
0000
,
1000
0000
1000
0000
,
0001
0000
0001
0000
,
0001
0000
0001
0000
,
0100
0000
0100
0000
,
0100
0000
0100
0000
,
0010
0000
0010
0000
,
0010
0000
0000
0000
,
0100
0000
1000
0000
,
0010
0000
0001
0000
,
0100
0000
0001
0000
,
0010
0000
1000
0000
,
0010
0000
0001
0000
,
0100
0000
1000
0000
,
0100
0000
0000
0000
,
0010
0000
0010
0000
,
0100
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
0000
0000
,
0010
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
0100
0000
0000
0000
,
0100
0000
0000
0000
,
0010
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
0000
0000
,
0100
0000
0000
0000
,
0100
0000
1000
0000
,
0010
0000
0000
0000
,
0100
0000
0001
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
0010
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
1000
0000
,
1000
0000
1000
0000
,
0010
0000
0010
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
0000
0000
0000
0000
,
0001
0000
0000
0000
,
0000
0000
0000
0000
,
1000
0000
1000
0000
,
0010
0000
0010
0000
,
1000
0000
0000
0000
,
0001
0000
0010
0000
,
0100
0000
0000
0000
,
1000
0000
0100
0000
,
0010
0000
0000
0000
,
1000
0000
0001
0000
,
0100
0000
1000
0000
,
0010
0000
0000
0000
,
0100
0000
0100
0000
,
0100
0000
0100
0000
,
0010
0000
0010
0000
,
0010
0000
0000
0000
,
1000
0000
1000
0000
,
1000
0000
1000
0000
,
0001
0000
0001
0000
,
0001
0000
0000
0000
,
0010
0000
0000
0000
,
1000
0000
0001
0000
,
0100
0000
0000
0000
,
0001
0000
0000
0000
,
0000
1000
0000
1000
,
0000
0001
0000
0010
,
0000
0001
0000
0100
,
0100
0000
0010
0000
,
1001
0000
0000
0000";

songVolume[3] = "8";
songSecondsPerBeat[3] = 0.4411765;
songDisplayOffset[3] = 0.4411765;
songNotes[3] = @"0000
0000
0000
0000
,
0000
0000
0000
0000
,
1000
0000
0000
0000
,
0000
0000
0001
0000
,
0000
0000
0000
0000
,
1000
0000
0000
0000
,
1001
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
0110
0000
0000
0000
,
0100
0000
0000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
1001
0000
0000
0000
,
0000
0000
0000
0000
,
0001
0000
0000
0000
,
0000
0000
0000
0000
,
1000
0000
1000
0000
,
0001
0000
0001
0000
,
1000
0000
0000
0000
,
0010
0000
0000
0000
,
0110
0000
0000
0000
,
0100
0000
0000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
1001
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
1001
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
0000
0000
,
0110
0000
0000
0000
,
0010
0000
0000
0000
,
0010
0000
0000
0000
,
0000
0000
0000
0000
,
0100
0000
0000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
0010
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
1001
0000
0000
0000
,
0000
0000
0000
0000
,
0001
0000
0000
0000
,
0000
0000
0000
0000
,
1000
0000
0000
0000
,
0001
0000
0000
0000
,
1001
0000
0000
0000
,
0000
0000
0000
0000
,
0100
0000
0000
0000
,
0100
0000
0000
0000
,
0010
0000
0000
0000
,
0010
0000
0000
0000
,
0100
0000
0000
0000
,
0100
0000
0000
0000
,
0010
0000
0000
0000
,
0010
0000
0000
0000
,
1001
0000
0000
0000";