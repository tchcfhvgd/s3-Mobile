package psych.states;

import haxe.Json;

import flixel.math.FlxRect;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxContainer;
import flixel.group.FlxSpriteContainer;
import flixel.group.FlxContainer.FlxTypedContainer;

import psych.psychlua.ModchartSprite;
import psych.backend.WeekData;
import psych.backend.Highscore;
import psych.backend.Song;

import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;

import psych.objects.MenuItem;
import psych.objects.MenuCharacter;
import psych.substates.GameplayChangersSubstate;
import psych.substates.ResetScoreSubState;

private typedef MenuCharData =
{
	var ?scale:Float;
	var ?offsets:Array<Float>;
}

private class MenuChar extends FlxSprite
{
	public var char:String;
	
	function getPng(char:String, isLocked:Bool = false)
	{
		return (isLocked && char.split(',')[1] != null) ? char.split(',')[1] : char.split(',')[0];
	}
	
	public function new(x:Float = 0, y:Float = 0, char:String)
	{
		super();
		antialiasing = ClientPrefs.data.antialiasing;
		loadChar(char);
	}
	
	public function loadChar(char:String, isLocked:Bool = false)
	{
		visible = false;
		this.char = char;
		
		var ch = char.split(',')[0];
		
		if (Paths.fileExists('images/menu/story/chars/$ch.png', IMAGE))
		{
			loadGraphic(Paths.image('menu/story/chars/${getPng(char, isLocked)}'));
			visible = true;
			scale.set(1, 1);
			updateHitbox();
			centerOffsets();
			if (Paths.fileExists('images/menu/story/chars/$ch.json', TEXT)) // actually i dont like hthis
			{
				var json:MenuCharData = Json.parse(Paths.getTextFromFile('images/menu/story/chars/$ch.json'));
				var _scale = json.scale ?? 1.0;
				var _offsets = json.offsets ?? [0, 0];
				
				offset.x += _offsets[0];
				offset.y += _offsets[1];
				scale.set(_scale, _scale);
			}
		}
	}
}

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();
	
	private static var lastDifficultyName:String = '';
	
	private static var curWeek:Int = 0;
	
	var loadedWeeks:Array<WeekData> = [];
	
	var curDifficulty:Int = 1;
	
	var charGrp:FlxTypedContainer<MenuChar>;
	var grpWeekText:FlxTypedGroup<MenuItem>;
	
	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxText;
	var diffBG:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	
	var banner:FlxSprite;
	
	var trackList:FlxTypedContainer<ModchartSprite>;
	var trackSpr:FlxSprite;
	
	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		FlxG.sound.play(S3Meta.getActorLine('ChooseAZone'));
		
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if (curWeek >= WeekData.weeksList.length) curWeek = 0;
		persistentUpdate = persistentDraw = true;
		
		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.screenCenter(X);
		
		grpWeekText = new FlxTypedGroup<MenuItem>();
		
		charGrp = new FlxTypedContainer();
		
		var num:Int = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if (!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);
				var weekThing:MenuItem = new MenuItem(0, 56 + 396, WeekData.weeksList[i]);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.targetY = num;
				grpWeekText.add(weekThing);
				
				weekThing.screenCenter(X);
				
				num++;
			}
		}
		
		WeekData.setDirectoryFromWeek(loadedWeeks[0]);
		var charArray:Array<String> = loadedWeeks[0].weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuChar = new MenuChar((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			charGrp.add(weekCharacterThing);
		}
		
		Difficulty.resetList();
		if (lastDifficultyName == '')
		{
			lastDifficultyName = Difficulty.getDefault();
		}
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		
		difficultySelectors = new FlxGroup();
		
		leftArrow = new ModchartSprite(1022, 463, Paths.image('menu/story/diffArrow'));
		leftArrow.flipX = true;
		
		sprDifficulty = new FlxText(0, 0, 178, 'Hard', 24);
		sprDifficulty.font = Paths.font('FOT-NewRodin Pro DB.otf');
		sprDifficulty.alignment = CENTER;
		
		difficultySelectors.add(sprDifficulty);
		difficultySelectors.add(leftArrow);
		
		rightArrow = new ModchartSprite(1181, 463, Paths.image('menu/story/diffArrow'));
		difficultySelectors.add(rightArrow);
		
		banner = new ModchartSprite(0, 25, Paths.image('menu/story/banner'));
		add(banner);
		banner.color = FlxColor.WHITE;
		
		final top = new FlxBackdrop(Paths.image('menu/story/top'), X, -1);
		add(top);
		top.velocity.x = 25;
		
		add(charGrp);
		
		final bottom = new FlxBackdrop(Paths.image('menu/story/bottom'), X, -1);
		bottom.y = FlxG.height - bottom.height;
		add(bottom);
		bottom.velocity.x = -25;
		
		final bottom2 = new FlxBackdrop(Paths.image('menu/story/bottom2'), X, -1);
		bottom2.y = bottom.y;
		
		bottom2.velocity.x = -25;
		
		insert(members.indexOf(charGrp), bottom2);
		
		add(grpWeekText);
		
		final bottomB = new ModchartSprite(Paths.image('menu/story/bottom bar'));
		bottomB.y = FlxG.height - bottomB.height;
		add(bottomB);
		
		final vs = new ModchartSprite(508, 174, Paths.image('menu/story/Vs_'));
		add(vs);
		
		diffBG = new ModchartSprite(1024, 466, Paths.image('menu/story/diffBG'));
		add(diffBG);
		
		sprDifficulty.x = diffBG.x;
		sprDifficulty.y = diffBG.y + (diffBG.height - sprDifficulty.height) / 2;
		
		add(difficultySelectors);
		
		final tracksBG = new ModchartSprite(14, 442, Paths.image('menu/story/trackBG'));
		add(tracksBG);
		
		trackSpr = new ModchartSprite(67, 463, Paths.image('menu/story/Tracks'));
		add(trackSpr);
		
		trackList = new FlxTypedContainer();
		add(trackList);
		
		changeWeek();
		changeDifficulty();
		
		super.create();
		
		addTouchPad("LEFT_FULL", "A_B_X_Y");
	}
	
	override function closeSubState()
	{
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
		removeTouchPad();
		addTouchPad("LEFT_FULL", "A_B_X_Y");
	}
	
	final topBound:Float = 440;
	final bottomBound:Float = FlxG.height;
	
	function bindText(spr:FlxSprite)
	{
		if (spr.clipRect == null) spr.clipRect = new FlxRect(0, 0, spr.width, spr.height);
		
		if (spr.y < topBound)
		{
			var yDiff = topBound - spr.y;
			
			spr.clipRect.set(0, yDiff, spr.width, spr.height - yDiff);
		}
		else if (spr.y + spr.height > bottomBound)
		{
			var yDiff = spr.y + spr.height - bottomBound;
			
			spr.clipRect.set(0, 0, spr.width, spr.height - yDiff);
		}
		else
		{
			spr.clipRect.set(0, 0, spr.width, spr.height);
		}
		
		spr.clipRect = spr.clipRect;
	}
	
	override function update(elapsed:Float)
	{
		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
		if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
		
		if (!movedBack && !selectedWeek)
		{
			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;
			if (upP)
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			
			if (downP)
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			
			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}
			
			inline function click(arrow:FlxSprite)
			{
				arrow.scale.set(0.9, 0.9);
				arrow.colorTransform.redOffset = 255;
			}
			
			inline function release(arrow:FlxSprite)
			{
				arrow.scale.set(1, 1);
				arrow.colorTransform.redOffset = 0;
			}
			
			if (controls.UI_RIGHT) click(rightArrow);
			else release(rightArrow);
			
			if (controls.UI_LEFT) click(leftArrow);
			else release(leftArrow);
			
			if (controls.UI_RIGHT_P) changeDifficulty(1);
			else if (controls.UI_LEFT_P) changeDifficulty(-1);
			else if (upP || downP) changeDifficulty();
			
			if (FlxG.keys.justPressed.CONTROL || touchPad.buttonX.justPressed)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
				removeTouchPad();
			}
			else if (controls.RESET || touchPad.buttonY.justPressed)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				removeTouchPad();
				// FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if (controls.ACCEPT)
			{
				selectWeek();
			}
		}
		
		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(() -> new MainMenuState());
		}
		
		super.update(elapsed);
		
		banner.color = FlxColor.interpolate(banner.color, bannerColour, FlxMath.getElapsedLerp(0.2, elapsed));
		
		grpWeekText.forEach(t -> {
			bindText(t);
			@:privateAccess
			bindText(t.selectedSpr);
		});
	}
	
	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;
	
	function selectWeek()
	{
		if (!weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length)
			{
				songArray.push(leWeek[i][0]);
			}
			
			// Nevermind that's stupid lmao
			try
			{
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedWeek = true;
				
				var diffic = Difficulty.getFilePath(curDifficulty);
				if (diffic == null) diffic = '';
				
				PlayState.storyDifficulty = curDifficulty;
				
				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = 0;
				PlayState.campaignMisses = 0;
			}
			catch (e:Dynamic)
			{
				trace('ERROR! $e');
				return;
			}
			
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				
				grpWeekText.members[curWeek].isFlashing = true;
				
				stopspamming = true;
			}
			
			new FlxTimer().start(1, function(tmr:FlxTimer) {
				LoadingState.loadAndSwitchState(() -> new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});
			
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else FlxG.sound.play(Paths.sound('cancelMenu'));
	}
	
	var tweenDifficulty:FlxTween;
	
	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length - 1);
		
		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);
		
		final diff:String = Difficulty.getString(curDifficulty);
		
		if (sprDifficulty.text != diff)
		{
			sprDifficulty.text = diff;
			
			if (tweenDifficulty != null) tweenDifficulty.cancel();
			sprDifficulty.x = diffBG.x + (change > 0 ? -5 : 5);
			tweenDifficulty = FlxTween.tween(sprDifficulty, {x: diffBG.x}, 0.07,
				{
					onComplete: function(twn:FlxTween) {
						tweenDifficulty = null;
					}
				});
		}
		lastDifficultyName = diff;
		
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
	}
	
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	
	var bannerColour:FlxColor = FlxColor.WHITE;
	
	function changeWeek(change:Int = 0):Void
	{
		curWeek = FlxMath.wrap(curWeek + change, 0, loadedWeeks.length - 1);
		
		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);
		
		var leName:String = leWeek.storyName;
		
		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		for (k => item in grpWeekText.members)
		{
			item.targetY = k - curWeek;
			item.color = item.targetY == Std.int(0) && unlocked ? FlxColor.WHITE : FlxColor.GRAY;
			item.selected = (item.targetY == Std.int(0) && unlocked);
		}
		
		bannerColour = FlxColor.fromString(leWeek.storyColour);
		PlayState.storyWeek = curWeek;
		
		Difficulty.loadFromWeek();
		difficultySelectors.visible = unlocked;
		
		if (Difficulty.list.contains(Difficulty.getDefault())) curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else curDifficulty = 0;
		
		var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
	}
	
	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}
	
	function updateText()
	{
		final weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		for (i in 0...charGrp.length)
		{
			if (weekArray[i] != charGrp.members[i].char)
			{
				FlxTween.completeTweensOf(charGrp.members[i], ['y']);
				charGrp.members[i].y += 20;
				FlxTween.tween(charGrp.members[i], {y: 70}, 0.05);
			}
			charGrp.members[i].loadChar(weekArray[i], weekIsLocked(loadedWeeks[curWeek].fileName));
		}
		
		final leWeek:WeekData = loadedWeeks[curWeek];
		final stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length)
		{
			stringThing.push(leWeek.songs[i][0]);
		}
		
		for (i in trackList)
		{
			i.kill();
		}
		
		var trackY = trackSpr.y + trackSpr.height + 35;
		
		for (i in 0...stringThing.length)
		{
			var spr = trackList.recycle(ModchartSprite, () -> new ModchartSprite());
			spr.loadGraphic(Paths.image('menu/story/${loadedWeeks[curWeek].fileName}/${Paths.formatToSongPath(stringThing[i])}')); // maybe replace this with generations text later cuz this was before i had the lcass
			
			spr.x = trackSpr.x + (trackSpr.width - spr.width) / 2;
			
			spr.y = trackY;
			trackY += 24;
			
			trackList.add(spr);
		}
		
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
	}
	
	override function beatHit()
	{
		super.beatHit();
	}
}
