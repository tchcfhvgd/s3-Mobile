import psych.cutscenes.DialogueBoxPsych;

var seenCutscene:Bool = false;

function onCreate()
{
	dadGroup.visible = false;
	
	if (PlayState.isStoryMode)
	{
		seenCutscene = PlayState.seenCutscene;
		if (!seenCutscene) game.startCallback = storyStart;
	}
}

function storyStart()
{
	if (FunkinDefines.defines.exists('VIDEOS_ALLOWED'))
	{
		FlxG.camera.visible = false;
		camHUD.visible = false;
		
		video = new FlxVideo();
		video.load(Paths.video('act0Intro'));
		FlxG.addChildBelowMouse(video);
		
		video.play();
		video.onEndReached.add(() -> {
			FlxG.camera.flash(FlxColor.BLACK, 0.5);
			FlxG.camera.visible = true;
			camHUD.visible = true;
			FlxG.removeChild(video);
			video.dispose();
			startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')), 'cutscenes/act0');
		}, true);
	}
	else
	{
		startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')), 'cutscenes/act0');
	}
}

function onMoveCamera(char)
{
	defaultCamZoomMult = (char == 'gf' ? 1.2 : 1);
}
