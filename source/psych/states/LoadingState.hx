package psych.states;

import flixel.util.typeLimit.NextState;
import flixel.FlxState;

import psych.backend.StageData;

class LoadingState extends MusicBeatState
{
	inline static public function loadAndSwitchState(target:NextState, stopMusic = false)
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;
		
		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
		
		if (stopMusic && FlxG.sound.music != null) FlxG.sound.music.stop();
		
		FlxG.switchState(target);
	}
}
