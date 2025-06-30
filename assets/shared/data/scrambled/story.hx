package assets.shared.data.scrambled;

import psych.cutscenes.DialogueBoxPsych;

function onCreate()
{
	if (PlayState.isStoryMode)
	{
		seenCutscene = PlayState.seenCutscene;
		if (!seenCutscene) game.startCallback = storyStart;
	}
}

function storyStart()
{
	startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')), 'cutscenes/scrambled');
}
