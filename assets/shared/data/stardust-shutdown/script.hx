import psych.cutscenes.DialogueBoxPsych;

function onCreate()
{
	dadGroup.visible = false;
}

function onCreatePost()
{
	var subs = Subtitles.fromSong('stardust-shutdown');
	if (subs != null)
	{
		add(subs);
		subs.cameras = [camHUD];
	}
}

var seenCutscene:Bool = false;

function onEndSong()
{
	if (PlayState.isStoryMode && !seenCutscene)
	{
		seenCutscene = true;
		if (!FunkinDefines.defines.exists('VIDEOS_ALLOWED'))
		{
			ClientPrefs.data.canAccessFreeplay = true;
			ClientPrefs.data.canAccessCredits = true;
			ClientPrefs.saveSettings();
			
			return Function_Continue;
		}
		
		video = new FlxVideo();
		video.load(Paths.video('Stardust-End'));
		FlxG.addChildBelowMouse(video);
		
		video.onEndReached.add(() -> {
			FlxG.camera.flash(FlxColor.BLACK, 0.5);
			FlxG.camera.alpha = 1;
			FlxG.removeChild(video);
			video.dispose();
			
			// im sorry i wanted to make this in game but time consuming
			if (!ClientPrefs.data.canAccessFreeplay)
			{
				FlxG.camera.alpha = 0;
				
				ClientPrefs.data.canAccessFreeplay = true;
				ClientPrefs.data.canAccessCredits = true;
				ClientPrefs.saveSettings();
				
				var vid = new FlxVideo();
				vid.load(Paths.video('freeplay'));
				FlxG.addChildBelowMouse(vid);
				
				vid.onEndReached.add(() -> {
					FlxG.removeChild(vid);
					vid.dispose();
					startAndEnd();
					FlxG.camera._fxFadeColor = 0;
				}, true);
				vid.play();
			}
			else
			{
				startAndEnd();
			}
		}, true);
		
		FlxTween.tween(camHUD, {alpha: 0}, 1);
		FlxG.camera._fxFadeColor = FlxColor.BLACK;
		FlxTween.tween(FlxG.camera, {_fxFadeAlpha: 1}, 1,
			{
				onComplete: Void -> {
					video.play();
				}
			});
			
		return Function_Stop;
	}
	
	return Function_Continue;
}
