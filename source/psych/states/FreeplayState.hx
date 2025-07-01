package psych.states;

import haxe.Json;

import psych.backend.SongCreditMeta;

import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxStringUtil;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxContainer;

import psych.objects.GenerationsText;
import psych.psychlua.ModchartSprite;
import psych.backend.WeekData;
import psych.backend.Highscore;
import psych.backend.Song;
import psych.objects.HealthIcon;
import psych.objects.MusicPlayer;
import psych.substates.GameplayChangersSubstate;
import psych.substates.ResetScoreSubState;

import flixel.math.FlxMath;

class FreeplayState extends MusicBeatState
{
	private static var lastDifficultyName:String = Difficulty.getDefault();
	
	private static var curSelected:Int = 0;
	
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	
	private var curPlaying:Bool = false;
	
	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	
	var player:MusicPlayer;
	
	var albumCover:FlxSprite;
	
	var songGrp:FlxTypedContainer<SongMeta>;
	
	var albumDescBG:FlxSprite;
	var albumName:FlxText;
	
	var rank:ModchartSprite;
	var rankTxt:ModchartSprite;
	
	var composerText:GenerationsText;
	var charterText:GenerationsText;
	var diffButton:DiffButton;
	
	override function create()
	{
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		FlxG.sound.play(S3Meta.getActorLine('SelectASong'));
		
		songGrp = new FlxTypedContainer();
		
		var songIdx = 0;
		
		Difficulty.resetList(); // needed for hiding code
		
		for (i in 0...WeekData.weeksList.length)
		{
			#if !debug
			if (weekIsLocked(WeekData.weeksList[i])) continue;
			#end
			
			final leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			
			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var fuck = new SongMeta(song[0], i, song[1]);
				songGrp.add(fuck);
				fuck.targetY = songIdx;
				fuck.active = fuck.visible = false;
				
				var isHidden = true;
				
				if (Highscore.getScore(song[0], 1) != 0 || Highscore.getScore(song[0], 2) != 0)
				{
					isHidden = false;
				}
				
				// trace('song: ${song[0]}, Normal Score: ${Highscore.getScore(song[0], 0)}, Hard Score: ${Highscore.getScore(song[0], 1)}, is Hidden ? [$isHidden]');
				
				fuck.hidden = isHidden;
				
				songIdx++;
			}
		}
		Mods.loadTopMod();
		
		WeekData.setDirectoryFromWeek();
		
		if (curSelected >= songGrp.length) curSelected = 0;
		lerpSelected = curSelected;
		
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		
		player = new MusicPlayer(this);
		add(player);
		
		final grey = new ModchartSprite().makeScaledGraphic(FlxG.width, FlxG.height, 0xFF3D3D3D);
		add(grey);
		
		final spikesTop = new extensions.flixel.FlxRotatedBackdrop(Paths.image('menu/freeplay/spikesBottom'), X);
		add(spikesTop);
		spikesTop.rotation = -3.4;
		spikesTop.velocity.x = 25;
		spikesTop.antialiasing = true;
		
		final spikesBottom = new extensions.flixel.FlxRotatedBackdrop(Paths.image('menu/freeplay/spikesBottom'), X);
		spikesBottom.y = FlxG.height - spikesBottom.height;
		add(spikesBottom);
		spikesBottom.rotation = -3.6;
		spikesBottom.velocity.x = -25;
		spikesBottom.antialiasing = true;
		
		final bar = new ModchartSprite(Paths.image('menu/freeplay/bar'));
		add(bar);
		
		add(songGrp);
		
		final bottomBar = new ModchartSprite(Paths.image('menu/freeplay/bottom'));
		bottomBar.y = FlxG.height - bottomBar.height;
		add(bottomBar);
		
		albumCover = new ModchartSprite(919, 69, Paths.image('menu/freeplay/vol1cover'));
		add(albumCover);
		
		albumDescBG = new ModchartSprite(920, 355, Paths.image('menu/freeplay/albumDesc'));
		add(albumDescBG);
		
		albumName = new FlxText(albumDescBG.x, 0, albumDescBG.width, '', 20);
		albumName.setFormat(Paths.font('FOT-NewRodin Pro DB.otf'), 20, CENTER);
		add(albumName);
		
		albumName.y = albumDescBG.y + (albumDescBG.height - albumName.height) / 2;
		
		final creditsBG = new ModchartSprite(953, 414, Paths.image('menu/freeplay/creditBG'));
		add(creditsBG);
		
		final creditsTxt = new ModchartSprite(1010, 402, Paths.image('menu/freeplay/Credits'));
		add(creditsTxt);
		
		final creditsChartIcon = new ModchartSprite(982, 495, Paths.image('menu/freeplay/Charting Icon'));
		add(creditsChartIcon);
		
		final creditsComposerIcon = new ModchartSprite(979, 457, Paths.image('menu/freeplay/Music Icon'));
		add(creditsComposerIcon);
		
		composerText = new GenerationsText(creditsComposerIcon.x + creditsComposerIcon.width + 8, creditsComposerIcon.y + 2, 0, 'weener', 20);
		add(composerText);
		composerText.borderColor = 0xFF460202;
		composerText.color = 0xFFEB4B4B;
		composerText.shadow.visible = false;
		
		charterText = new GenerationsText(creditsChartIcon.x + creditsChartIcon.width + 8, creditsChartIcon.y + 1, 200, 'weener', 20);
		add(charterText);
		charterText.borderColor = 0xFF460202;
		charterText.color = 0xFFEB4B4B;
		charterText.shadow.visible = false;
		
		diffButton = new DiffButton();
		add(diffButton);
		
		rank = cast new ModchartSprite(141, 457).loadFunkinSparrow('menu/freeplay/ranks');
		for (i in ['E', 'D', 'C', 'B', 'S', 'A']) rank.animation.addByPrefix(i, i);
		rank.animation.play('E');
		
		add(rank);
		
		rankTxt = new ModchartSprite(176, 454, Paths.image('menu/freeplay/RANK'));
		add(rankTxt);
		
		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);
		
		changeSelection();
		updateTexts();
		
		addTouchPad("LEFT_FULL", "A_B_C_X_Y_Z");
		
		super.create();
	}
	
	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
		removeTouchPad();
		addTouchPad("LEFT_FULL", "A_B_C_X_Y_Z");
	}
	
	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
	
	var instPlaying:Int = -1;
	
	public static var vocals:FlxSound = null;
	
	var holdTime:Float = 0;
	
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		
		var shiftMult:Int = 1;
		if (FlxG.keys.pressed.SHIFT || touchPad.buttonZ.pressed) shiftMult = 3;
		
		if (!player.playingMusic)
		{
			if (songGrp.length > 1)
			{
				if (FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;
				}
				else if (FlxG.keys.justPressed.END)
				{
					curSelected = songGrp.length - 1;
					changeSelection();
					holdTime = 0;
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}
				
				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
					
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
				
				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}
			
			if (controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}
		}
		
		if (controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;
				
				player.playingMusic = false;
				player.switchPlayMusic();
				
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else
			{
				persistentUpdate = false;
				
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new MainMenuState());
			}
		}
		
		if ((FlxG.keys.justPressed.CONTROL || touchPad.buttonC.justPressed) && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
			removeTouchPad();
		}
		else if (FlxG.keys.justPressed.SPACE || touchPad.buttonX.justPressed)
		{
			if (instPlaying != curSelected && !player.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				
				Mods.currentModDirectory = songGrp.members[curSelected].directory;
				var poop:String = Highscore.formatSong(songGrp.members[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songGrp.members[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
				{
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
					FlxG.sound.list.add(vocals);
					vocals.persist = true;
					vocals.looped = true;
				}
				else if (vocals != null)
				{
					vocals.stop();
					vocals.destroy();
					vocals = null;
				}
				
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.8);
				if (vocals != null) // Sync vocals to Inst
				{
					vocals.play();
					vocals.volume = 0.8;
				}
				instPlaying = curSelected;
				
				player.playingMusic = true;
				player.curTime = 0;
				player.switchPlayMusic();
			}
			else if (instPlaying == curSelected && player.playingMusic)
			{
				player.pauseOrResume(player.paused);
			}
		}
		else if (controls.ACCEPT && !player.playingMusic)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songGrp.members[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			
			try
			{
				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
			}
			catch (e:Dynamic)
			{
				trace('ERROR! $e');
				
				var errorStr:String = Std.string(e);
				if (errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(34, errorStr.length - 1); // Missing chart
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				
				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}
			LoadingState.loadAndSwitchState(() -> new PlayState());
			
			FlxG.sound.music.volume = 0;
			
			destroyFreeplayVocals();
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else if (controls.RESET || touchPad.buttonY.justPressed && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songGrp.members[curSelected].songName, curDifficulty, songGrp.members[curSelected].icon.getCharacter()));
			removeTouchPad();
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		
		rank.updateHitbox();
		rank.x = rankTxt.x + (rankTxt.width - rank.width) / 2;
		updateTexts(elapsed);
		super.update(elapsed);
	}
	
	public static function destroyFreeplayVocals()
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}
	
	function changeDiff(change:Int = 0)
	{
		if (player.playingMusic) return;
		
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);
		
		var previousRank = S3Meta.queryRank(intendedRating);
		intendedScore = Highscore.getScore(songGrp.members[curSelected].songName, curDifficulty);
		
		intendedRating = Highscore.getRating(songGrp.members[curSelected].songName, curDifficulty);
		
		// trace(songGrp.members[curSelected].songName);
		// trace(intendedRating);
		// trace(curDifficulty);
		// trace(Difficulty.getString(curDifficulty));
		// trace(S3Meta.queryRank(intendedRating));
		
		rank.animation.play(S3Meta.queryRank(intendedRating), true);
		
		if (previousRank != S3Meta.queryRank(intendedRating))
		{
			FlxTween.cancelTweensOf(rank, ['y']);
			
			rank.y -= 5;
			FlxTween.tween(rank, {y: 457}, 0.05);
		}
		
		lastDifficultyName = Difficulty.getString(curDifficulty);
		
		if (change != 0) diffButton.changed(change > 0);
		diffButton.diffText.text = lastDifficultyName;
		
		updateMeta();
		
		missingText.visible = false;
		missingTextBG.visible = false;
	}
	
	function updateMeta(reparseM:Bool = false)
	{
		inline function reparse()
		{
			final formattedPath = Paths.formatToSongPath(songGrp.members[curSelected].songName);
			final metaString:Null<String> = Paths.getTextFromFile('data/$formattedPath/meta.json');
			if (metaString != null) _weekMeta = Json.parse(metaString);
		}
		
		if (_weekMeta == null || reparseM) reparse();
		
		var baseMeta = lastDifficultyName.toLowerCase() == 'hard' ? _weekMeta.hard : _weekMeta.def;
		
		charterText.text = baseMeta?.charter ?? '???';
		composerText.text = baseMeta?.composer ?? '???';
	}
	
	var _weekMeta:Null<SongCreditMeta> = null;
	
	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic) return;
		
		_updateSongLastDifficulty();
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		var lastList:Array<String> = Difficulty.list;
		var lastSong = songGrp.members[curSelected].songName;
		
		curSelected = FlxMath.wrap(curSelected + change, 0, songGrp.members.length - 1);
		
		for (item in songGrp.members)
		{
			item.selected = item.targetY == curSelected;
		}
		
		Mods.currentModDirectory = songGrp.members[curSelected].directory;
		PlayState.storyWeek = songGrp.members[curSelected].week;
		Difficulty.loadFromWeek();
		
		if (songGrp.members[curSelected].songName != lastSong)
		{
			updateMeta(true);
		}
		
		diffButton.parent = songGrp.members[curSelected];
		// albumName.text = FlxStringUtil.toTitleCase(WeekData.getWeekFileName().replace('-', ' '));
		if (change != 0)
		{
			FlxTween.cancelTweensOf(albumName, ['x']);
			albumName.x = albumDescBG.x + (change > 0 ? -10 : 10);
			
			FlxTween.tween(albumName, {x: albumDescBG.x}, 0.05);
		}
		
		albumName.text = songGrp.members[curSelected].songName;
		
		var savedDiff:String = songGrp.members[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if (savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff)) curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if (lastDiff > -1) curDifficulty = lastDiff;
		else if (Difficulty.list.contains(Difficulty.getDefault())) curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else curDifficulty = 0;
		
		changeDiff();
		_updateSongLastDifficulty();
	}
	
	inline private function _updateSongLastDifficulty()
	{
		songGrp.members[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}
	
	var _drawDistance:Int = 8;
	var _lastVisibles:Array<Int> = [];
	
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(lerpSelected, FlxMath.bound(curSelected, Math.NEGATIVE_INFINITY, songGrp.length - (_drawDistance - 1)), FlxMath.getElapsedLerp(0.3, elapsed));
		
		for (i in _lastVisibles)
		{
			songGrp.members[i].visible = songGrp.members[i].active = false;
		}
		_lastVisibles.resize(0);
		
		var min:Int = Math.round(Math.max(0, Math.min(songGrp.members.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songGrp.members.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var song = songGrp.members[i];
			song.visible = song.active = true;
			song.x = ((song.targetY - lerpSelected) * song.distancePerItem.x) + song.startPosition.x;
			song.y = ((song.targetY - lerpSelected) * 1.3 * song.distancePerItem.y) + song.startPosition.y;
			
			song.x = Math.round(song.x);
			song.y = Math.round(song.y);
			
			_lastVisibles.push(i);
		}
	}
	
	override function destroy():Void
	{
		super.destroy();
		
		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing) FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}
	
	override function draw()
	{
		// super.draw();
		// return;
		
		//
		@:privateAccess
		if (persistentDraw || subState == null)
		{
			final oldDefaultCameras = FlxCamera._defaultCameras;
			if (_cameras != null)
			{
				FlxCamera._defaultCameras = _cameras;
			}
			
			for (basic in members)
			{
				if (basic != null && basic.exists && basic.visible)
				{
					if (basic == songGrp)
					{
						for (i in songGrp)
						{
							if (i.visible) i.defaultDraw();
						}
						for (i in songGrp)
						{
							if (i.visible) i.text.draw();
						}
						for (i in songGrp)
						{
							if (i.visible) i.icon.draw();
						}
					}
					else
					{
						basic.draw();
					}
				}
			}
			
			FlxCamera._defaultCameras = oldDefaultCameras;
		}
		
		if (subState != null) subState.draw();
	}
}

private class DiffButton extends FlxSprite
{
	public var parent:Null<FlxSprite> = null;
	
	public final leftArrow:FlxSprite;
	public final rightArrow:FlxSprite;
	
	public final diffText:GenerationsText;
	
	public function new()
	{
		super(Paths.image('menu/freeplay/diff'));
		
		leftArrow = new FlxSprite(Paths.image('menu/freeplay/diffArrow'));
		leftArrow.flipX = true;
		rightArrow = new FlxSprite(Paths.image('menu/freeplay/diffArrow'));
		
		diffText = new GenerationsText(0, 0, width, 'Normal', 14);
		diffText.color = FlxColor.YELLOW;
		diffText.borderColor = FlxColor.BLACK;
		diffText.borderSize = 1;
		
		diffText.shadow.visible = false;
		
		diffText.alignment = CENTER;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (parent != null)
		{
			x = parent.x + 370;
			y = parent.y - 17;
		}
		
		diffText.x = x + diffX;
		diffText.y = y + (height - diffText.height) / 2;
		diffText.update(elapsed);
		
		leftArrow.x = x + -13;
		leftArrow.y = y + (height - leftArrow.height) / 2;
		rightArrow.x = x + 70;
		rightArrow.y = y + (height - rightArrow.height) / 2;
		
		final clickScale = Controls.instance.UI_LEFT ? 0.9 : 1;
		leftArrow.scale.set(clickScale, clickScale);
		
		final clickScale = Controls.instance.UI_RIGHT ? 0.9 : 1;
		rightArrow.scale.set(clickScale, clickScale);
	}
	
	var diffX:Float = 0;
	var xTween:FlxTween;
	
	public function changed(moveLeft:Bool = false)
	{
		xTween?.cancel();
		diffX = moveLeft ? -5 : 5;
		xTween = FlxTween.num(diffX, 0, 0.05, {}, f -> diffX = f);
	}
	
	override function draw()
	{
		super.draw();
		
		diffText.draw();
		leftArrow.draw();
		rightArrow.draw();
	}
	
	override function destroy()
	{
		super.destroy();
		
		FlxDestroyUtil.destroy(diffText);
		FlxDestroyUtil.destroy(leftArrow);
		FlxDestroyUtil.destroy(rightArrow);
	}
}

class SongMeta extends FlxSprite
{
	public var selected:Bool = false;
	
	// meta
	public var songName:String = '';
	public var directory:String = '';
	public var week:Int = 0;
	public var lastDifficulty:Null<String> = null;
	public var healthIcon:String;
	
	public final text:GenerationsText;
	public final icon:HealthIcon;
	
	public var targetY:Int = 0;
	public var distancePerItem:FlxPoint = new FlxPoint(76, 65);
	public var startPosition:FlxPoint = new FlxPoint(32, 64); // for the calculations
	
	public function new(song:String, week:Int, healthIcon:String)
	{
		this.week = week;
		this.songName = song;
		this.directory = Mods.currentModDirectory ?? '';
		this.healthIcon = healthIcon;
		
		super();
		
		frames = Paths.getSparrowAtlas('menu/freeplay/box');
		animation.frameIndex = 0;
		
		var textSize = song.length > 15 ? 22 : 28;
		text = new GenerationsText(0, 0, 0, song, textSize);
		
		icon = new HealthIcon(healthIcon);
		icon.setGraphicSize(0, 76);
		icon.updateHitbox();
		icon.centerOffsets();
	}
	
	public function defaultDraw()
	{
		super.draw();
	}
	
	override function draw()
	{
		super.draw();
		icon.draw();
		text.draw();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		animation.frameIndex = selected ? 0 : 1;
		
		text.color = selected ? FlxColor.YELLOW : FlxColor.WHITE;
		
		text.x = x + 110;
		text.y = y - (5 * (text.size / 28));
		// text.y = y;
		text.update(elapsed);
		
		icon.x = text.x - icon.width;
		icon.y = y - 25;
	}
	
	public var hidden(default, set):Bool = false;
	
	override function destroy()
	{
		super.destroy();
		FlxDestroyUtil.destroy(text);
		FlxDestroyUtil.destroy(icon);
	}
	
	function set_hidden(value:Bool):Bool
	{
		icon.changeIcon(value ? '' : healthIcon);
		icon.centerOffsets();
		return (hidden = value);
	}
}
