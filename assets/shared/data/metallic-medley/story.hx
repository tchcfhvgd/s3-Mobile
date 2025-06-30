import psych.cutscenes.DialogueBoxPsych;

var seen = false;

function onCreate()
{
	if (PlayState.isStoryMode && !PlayState.seenCutscene)
	{
		game.startCallback = () -> {
			startDialogue(DialogueBoxPsych.parseDialogue(Paths.json('metallic-medley' + '/dialogue')), 'cutscenes/metallic');
		}
	}
}

function onEndSong()
{
	if (!seen && PlayState.isStoryMode)
	{
		seen = true;
		startDialogue(DialogueBoxPsych.parseDialogue(Paths.json('stardust-shutdown' + '/dialogue')), 'cutscenes/stardust');
		
		FlxTween.tween(uiGroup, {alpha: 0}, 1);
		for (i in strumLineNotes.members)
		{
			FlxTween.tween(i, {alpha: 0}, 1);
		}
		return Function_Stop;
	}
	
	return Function_Continue;
}
