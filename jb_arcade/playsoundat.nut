//===============================
//=====    PLAY_SOUND_AT    =====
//=====         BY          =====
//=====       THORGOT       =====
//===============================

//EntityGroup[0]: info_target
//EntityGroup[1]: ambient_generic which is set to play at the info_target (required)
//EntityGroup[2-15]: more ambient_generics (optional)

sounds<-null;

function Setup() {
	if (sounds == null) {
		sounds = [];
		for (local i = 1; i < 16; i++) {
			if (i in EntityGroup && EntityGroup[i] != null) {
				sounds.push(EntityGroup[i]);
			}
		}
	}
}

function PlaySound() {
	Setup();

	if (activator != null && activator.IsValid()) {
		EntityGroup[0].SetOrigin(activator.GetOrigin());
		EntFireByHandle(EntityGroup[RandomInt(1, sounds.len())], "PlaySound", "", 0.05, activator, null);
	}
}

function PlaySoundAtVolume(volume) {
	Setup();

	if (activator != null && activator.IsValid()) {
		EntityGroup[0].SetOrigin(activator.GetOrigin());
		EntFireByHandle(EntityGroup[RandomInt(1, sounds.len())], "Volume", volume.tostring(), 0.05, activator, null);
	}
}