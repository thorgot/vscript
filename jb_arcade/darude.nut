

const LETTER_D = "D";
const LETTER_A = "A";
const LETTER_R = "R";
const LETTER_U = "U";
const LETTER_E = "E";

currentInput <- "";
spawned <- false;

function EnterCode(letter) {
	if (spawned) return;
	currentInput += letter;
	
	if (currentInput == "DARUDE") {
		printl("DARUDE DONE");
		EntFire("disco_button7_template", "ForceSpawn", "", 0.0, null);
		spawned = true;
		
		return;
	}
	if (!(currentInput == "D" || currentInput == "DA" || currentInput == "DAR" || currentInput == "DARU" || currentInput == "DARUD")) {
		currentInput = letter;
	}
	printl(currentInput);
}