package psych.substates;

import psych.objects.GenerationsText;
import psych.psychlua.ModchartSprite;
import psych.backend.WeekData;
import psych.backend.Highscore;
import psych.backend.Song;

import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxStringUtil;

import psych.states.StoryMenuState;
import psych.states.FreeplayState;
import psych.options.OptionsState;

// menu coded bad im sorry
class PauseSubState extends MusicBeatSubstate
{
	public static var songName:String = null;
	
	var grpMenuShit:FlxTypedGroup<GenerationsText>;
	
	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to Menu'];
	var difficultyChoices = [];
	var curSelected:Int = 0;
	
	var pauseMusic:FlxSound;
	var skipTimeText:FlxText;
	var skipTimeTracker:GenerationsText;
	var curTime:Float = Math.max(0, Conductor.songPosition);
	
	var amy:FlxSprite;
	
	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	
	var bgSpr:FlxSprite;
	var bars:Array<FlxSprite> = [];
	var star:FlxSprite;
	
	override function create()
	{
		if (Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty'); // No need to change difficulty if there is only one!
		
		if (PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			
			var num:Int = 0;
			if (!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}
		menuItems = menuItemsOG;
		
		for (i in 0...Difficulty.list.length)
		{
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');
		
		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if (pauseSong != null) pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		
		FlxG.sound.list.add(pauseMusic);
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		
		amy = new FlxSprite().loadFromSheet('menu/pause/AmyMoraca', 'amy moraca');
		amy.antialiasing = ClientPrefs.data.antialiasing;
		amy.scale.set(0.7, 0.7);
		amy.updateHitbox();
		// amy.x = FlxG.width - amy.width;
		amy.y = FlxG.height - amy.height;
		amy.alpha = 0;
		add(amy);
		
		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		
		var _members = []; // shit code im sorry im so  tired rn man
		
		bgSpr = new ModchartSprite(Paths.image('menu/pause/bg'));
		bgSpr.x = FlxG.width - bgSpr.width;
		add(bgSpr);
		_members.push(bgSpr);
		
		final spikes = new ModchartSprite(bgSpr.x + 31, 6, Paths.image('menu/pause/spikes'));
		add(spikes);
		_members.push(spikes);
		
		final pauseTxt = new ModchartSprite(bgSpr.x + 76, 25, Paths.image('menu/pause/Paused'));
		add(pauseTxt);
		_members.push(pauseTxt);
		
		final bar = new ModchartSprite(0, 139, Paths.image('menu/pause/Layer_5'));
		bar.x = FlxG.width - bar.width;
		bar.alpha = 0.6;
		add(bar);
		bars.push(bar);
		_members.push(bar);
		
		final bar = new ModchartSprite(0, 257, Paths.image('menu/pause/Layer_4'));
		bar.x = FlxG.width - bar.width;
		bar.alpha = 0.6;
		add(bar);
		bars.push(bar);
		_members.push(bar);
		
		final bar = new ModchartSprite(0, 380, Paths.image('menu/pause/Layer_3'));
		bar.x = FlxG.width - bar.width;
		bar.alpha = 0.6;
		add(bar);
		bars.push(bar);
		_members.push(bar);
		
		final bar = new ModchartSprite(0, 497, Paths.image('menu/pause/Layer_2'));
		bar.x = FlxG.width - bar.width;
		bar.alpha = 0.6;
		add(bar);
		bars.push(bar);
		_members.push(bar);
		
		final bar = new ModchartSprite(0, 614, Paths.image('menu/pause/Layer_1'));
		bar.x = FlxG.width - bar.width;
		bar.alpha = 0.6;
		add(bar);
		bars.push(bar);
		_members.push(bar);
		
		star = new ModchartSprite(1132);
		star.loadRotatedGraphic(Paths.image('menu/pause/star'), 60, -1, ClientPrefs.data.antialiasing);
		add(star);
		star.centerOrigin();
		_members.push(star);
		
		grpMenuShit = new FlxTypedGroup();
		add(grpMenuShit);
		
		missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		missingTextBG.scale.set(FlxG.width, FlxG.height);
		missingTextBG.updateHitbox();
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);
		
		regenMenu();
		
		// shitty !
		for (i in grpMenuShit.members) _members.push(i);
		for (i in _members)
		{
			i.x += FlxG.width;
			
			FlxTween.tween(i, {x: i.x - FlxG.width}, 0.2, {ease: FlxEase.cubeOut});
		}
		
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		
		super.create();
	}
	
	function getPauseSong()
	{
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if (formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none')) return null;
		
		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}
	
	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5) pauseMusic.volume += 0.01 * elapsed;
		
		star.angle += elapsed * 80;
		
		super.update(elapsed);
		
		if (cantUnpause <= -20 && amy.alpha == 0)
		{
			FlxTween.tween(amy, {alpha: 1}, 5);
		}
		
		if (controls.BACK)
		{
			close();
			return;
		}
		
		updateSkipTextStuff();
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}
		
		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}
				
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if (holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}
					
					if (curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if (curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}
		
		if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode))
		{
			if (menuItems == difficultyChoices)
			{
				try
				{
					if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
					{
						var name:String = PlayState.SONG.song;
						var poop = Highscore.formatSong(name, curSelected);
						PlayState.SONG = Song.loadFromJson(poop, name);
						PlayState.storyDifficulty = curSelected;
						FlxG.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
						return;
					}
				}
				catch (e:Dynamic)
				{
					trace('ERROR! $e');
					
					var errorStr:String = e.toString();
					if (errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length - 1); // Missing chart
					missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
					missingText.screenCenter(Y);
					missingText.visible = true;
					missingTextBG.visible = true;
					FlxG.sound.play(Paths.sound('cancelMenu'));
					
					super.update(elapsed);
					return;
				}
				
				menuItems = menuItemsOG;
				regenMenu();
			}
			
			switch (daSelected)
			{
				case "Resume":
					close();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					deleteSkipTimeText();
					regenMenu();
				case 'Toggle Practice Mode':
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.changedDifficulty = true;
				case "Restart Song":
					restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				case 'Skip Time':
					if (curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
						close();
					}
				case 'End Song':
					close();
					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.finishSong(true);
				case 'Toggle Botplay':
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.changedDifficulty = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				case 'Options':
					PlayState.instance.paused = true; // For lua
					PlayState.instance.vocals.volume = 0;
					FlxG.switchState(() -> new OptionsState());
					if (ClientPrefs.data.pauseMusic != 'None')
					{
						FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
						FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
						FlxG.sound.music.time = pauseMusic.time;
					}
					OptionsState.onPlayState = true;
				case "Exit to Menu":
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;
					
					Mods.loadTopMod();
					if (PlayState.isStoryMode) FlxG.switchState(() -> new StoryMenuState());
					else FlxG.switchState(() -> new FreeplayState());
					
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
			}
		}
	}
	
	function deleteSkipTimeText()
	{
		if (skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}
		skipTimeText = null;
		skipTimeTracker = null;
	}
	
	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;
		
		if (noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		FlxG.resetState();
	}
	
	override function destroy()
	{
		pauseMusic.destroy();
		
		super.destroy();
	}
	
	function changeSelection(change:Int = 0):Void
	{
		grpMenuShit.members[curSelected].color = FlxColor.WHITE;
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		final prevSel = curSelected;
		
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);
		
		grpMenuShit.members[curSelected].color = FlxColor.YELLOW;
		
		missingText.visible = false;
		missingTextBG.visible = false;
		
		if (curSelected > (bars.length - 1)) return;
		
		if (bars[prevSel] != null)
		{
			bars[prevSel].alpha = 0.6;
			FlxTween.cancelTweensOf(bars[prevSel], ['alpha']);
		}
		
		FlxTween.tween(bars[curSelected], {alpha: 1}, 0.1);
		
		star.y = bars[curSelected].y + (bars[curSelected].height - star.height) / 2;
	}
	
	function regenMenu():Void
	{
		for (i in 0...grpMenuShit.members.length)
		{
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}
		
		for (i in bars)
		{
			i.alpha = 0.6;
			FlxTween.cancelTweensOf(i, ['alpha']);
		}
		
		for (i in 0...menuItems.length)
		{
			var item = new GenerationsText(0, 153 + (i * 88), 0, menuItems[i], 36);
			
			item.x = bgSpr.x + bgSpr.width - item.width - 47;
			// s.color = FlxColor.YELLOW;
			grpMenuShit.add(item);
			if (menuItems[i] == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 32);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);
				
				updateSkipTextStuff();
				updateSkipTimeText();
			}
			
			if (i > bars.length - 1)
			{
				item.x = 100;
				item.y = 153 + ((i - 3) * 88);
				continue;
			}
			
			item.y = bars[i].y + (bars[i].height - item.height) / 2;
		}
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if (skipTimeText == null || skipTimeTracker == null) return;
		
		skipTimeText.x = skipTimeTracker.x + -skipTimeText.width;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}
	
	function updateSkipTimeText()
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false)
			+ ' / '
			+ FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}
