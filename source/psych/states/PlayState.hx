package psych.states;

import flixel.util.FlxDestroyUtil;

import psych.cutscenes.DialogueBoxS3;
import psych.substates.MissionClearSubstate;

import flixel.group.FlxContainer.FlxTypedContainer;

import psych.backend.SongCreditMeta;

import flixel.system.FlxBGSprite;

import psych.backend.PsychSound;
import psych.backend.Highscore;
import psych.backend.StageData;
import psych.backend.WeekData;
import psych.backend.Song;
import psych.backend.Section;
import psych.backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;

import lime.utils.Assets;

import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;

import haxe.Json;

import psych.cutscenes.CutsceneHandler;
import psych.cutscenes.DialogueBoxPsych;
import psych.states.StoryMenuState;
import psych.states.FreeplayState;
import psych.states.editors.ChartingState;
import psych.states.editors.CharacterEditorState;
import psych.substates.PauseSubState;
import psych.substates.GameOverSubstate;

#if !flash
import flixel.addons.display.FlxRuntimeShader;

import openfl.filters.ShaderFilter;
#end

import psych.objects.Note.EventNote;
import psych.objects.*;
import psych.states.stages.objects.*;
#if LUA_ALLOWED
import psych.psychlua.*;
#else
import psych.psychlua.LuaUtils;
import psych.psychlua.HScript;
#end
#if HSCRIPT_ALLOWED
import psych.psychlua.HScript.HScriptInfos;

import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

@:structInit class S3Meta
{
	// constants
	public static final HIT_CAP:Int = 100;
	public static final DEFAULT_LIVES:Int = 2;
	public static final LIVES_CAP:Int = 10;
	
	public var lives:Int = DEFAULT_LIVES;
	public var noteHits:Int = 0;
	
	public function resetLives()
	{
		lives = DEFAULT_LIVES;
		ClientPrefs.data.heldLives = lives;
	}
	
	public function gainLife()
	{
		noteHits = 0;
		if (lives >= LIVES_CAP)
		{
			lives = LIVES_CAP;
			return;
		}
		
		FlxG.sound.play(Paths.sound('S3 Extra Life'), 0.5);
		lives++;
		ClientPrefs.data.heldLives = lives;
	}
	
	public function loseLife()
	{
		FlxG.sound.play(Paths.sound('gameOver'));
		noteHits = 0;
		lives--;
		ClientPrefs.data.heldLives = lives;
	}
	
	public function resetHits(livesToo:Bool = false)
	{
		noteHits = 0;
		if (livesToo) lives = DEFAULT_LIVES;
	}
	
	public static function queryRank(percent:Float) // use 0-1
	{
		if (percent >= 0.91) return 'S';
		else if (percent >= 0.85) return 'A';
		else if (percent >= 0.81) return 'B';
		else if (percent >= 0.78) return 'C';
		else if (percent >= 0.70) return 'D';
		else return 'E';
	}
	
	public static inline function getActorLine(line:String)
	{
		return Paths.sound('actors/$line-$MENU_ANNOUNCER');
	}
	
	public static final MENU_ANNOUNCER:String = FlxG.random.bool(50) ? FlxG.random.bool(50) ? 'eggman' : 'amy' : 'sonic';
	
	public static function ifFreeplay() {}
}

/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/
class PlayState extends MusicBeatState
{
	public static var gameMeta:S3Meta = {};
	
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
	
	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];
	
	// event variables
	private var isCameraOnForcedPos:Bool = false;
	
	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	#end
	
	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#end
	
	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;
	
	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	public var playbackRate(default, set):Float = 1;
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	
	public static var curStage:String = '';
	public static var stageUI:String = "normal";
	public static var isPixelStage(get, never):Bool;
	
	@:noCompletion
	static function get_isPixelStage():Bool return stageUI == "pixel" || stageUI.endsWith("-pixel");
	
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	
	public var spawnTime:Float = 2000;
	
	public var inst:FlxSound;
	public var vocals:PsychSound;
	public var opponentVocals:PsychSound;
	
	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;
	
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	
	public var camFollow:FlxObject;
	
	private static var prevCamFollow:FlxObject;
	
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	
	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	
	private var curSong:String = "";
	
	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var combo:Int = 0;
	public var highestCombo:Int = 0;
	
	public var healthBar:Bar;
	
	var songPercent:Float = 0;
	
	public var ratingsData:Array<Rating> = Rating.loadDefault();
	
	private var generatedMusic:Bool = false;
	
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	
	private var updateTime:Bool = true;
	
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;
	public static var qqqeb:Bool = false;
	
	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	
	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	
	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var luaTpadCam:FlxCamera;
	public var cameraSpeed:Float = 2;
	
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	
	var scoreTxtTween:FlxTween;
	
	public var livesIcon:FlxSprite;
	public var livesTxt:FlxText;
	
	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;
	
	public var defaultCamZoom:Float = 1.05;
	public var defaultCamZoomMult:Float = 1;
	
	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
	
	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	
	var songLength:Float = 0;
	
	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;
	
	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end
	
	// Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;
	
	// Lua shit
	public static var instance:PlayState;
	
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end
	
	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psych.psychlua.DebugLuaText>;
	#end
	
	public var introSoundsSuffix:String = '';
	
	// Less laggy controls
	private var keysArray:Array<String>;
	
	public var songName:String;
	
	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;
	
	public var luaTouchPad:TouchPad;
	
	#if FLX_DEBUG
	inline function addFlxWatches()
	{
		FlxG.watch.addFunction('curStep', () -> curStep);
		FlxG.watch.addFunction('curBeat', () -> curBeat);
		FlxG.watch.addFunction('curSection', () -> curSection);
		
		FlxG.watch.addFunction('Song Time', () -> Std.string(FlxStringUtil.formatTime(FlxG.sound.music.time / 1000) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000)));
		FlxG.watch.addFunction('Conductor Position', () -> Std.int(Conductor.songPosition));
	}
	#end
	
	override public function create()
	{
		// trace('Playback Rate: ' + playbackRate);
		Paths.clearStoredMemory();
		
		startCallback = startCard;
		endCallback = endSong;
		
		// for lua
		instance = this;
		
		PauseSubState.songName = null; // Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');
		
		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
		];
		
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		
		#if FLX_DEBUG
		addFlxWatches();
		#end
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		
		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		luaTpadCam = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		luaTpadCam.bgColor.alpha = 0;
		
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(luaTpadCam, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();
		
		if (isStoryMode) detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else detailsText = "Freeplay";
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if (SONG.stage == null || SONG.stage.length < 1)
		{
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;
		
		var stageData:StageFile = StageData.getStageFile(curStage);
		if (stageData == null)
		{ // Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}
		
		defaultCamZoom = stageData.defaultZoom;
		
		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0) stageUI = stageData.stageUI;
		else
		{
			if (stageData.isPixelStage) stageUI = "pixel";
		}
		
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];
			
		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null) opponentCameraOffset = [0, 0];
		
		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null) girlfriendCameraOffset = [0, 0];
		
		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		
		switch (curStage)
		{
			case 'stage':
				new psych.states.stages.StageWeek1(); // Week 1
			case 'greenhill':
				new psych.states.stages.GreenHill(); // Green Hill
		}
		
		trace('current stage: $curStage');
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		add(gfGroup);
		add(dadGroup);
		add(boyfriendGroup);
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<psych.psychlua.DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end
		
		// "GLOBAL" SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/')) for (file in FileSystem.readDirectory(folder))
		{
			#if LUA_ALLOWED
			if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
			#end
			
			#if HSCRIPT_ALLOWED
			if (file.toLowerCase().endsWith('.hx')) initHScript(folder + file);
			#end
		}
		#end
		
		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end
		
		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end
		
		if (!stageData.hide_girlfriend)
		{
			if (SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; // Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter);
		}
		
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter);
		
		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);
		
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		
		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);
			if (gf != null) gf.visible = false;
		}
		stagesFunc(function(stage:BaseStage) stage.createPost());
		
		comboGroup = new FlxSpriteGroup();
		add(comboGroup);
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(noteGroup);
		uiGroup = new FlxSpriteGroup();
		add(uiGroup);
		
		Conductor.songPosition = -5000 / Conductor.songPosition;
		
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		noteGroup.add(strumLineNotes);
		
		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; // cant make it invisible or it won't allow precaching
		
		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		
		generateSong(SONG.song);
		
		noteGroup.add(grpNoteSplashes);
		
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();
		
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);
		
		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();
		
		healthBar = new Bar(0, 0, 'healthBar', function() return health, 0, 2);
		healthBar.y = ClientPrefs.data.downScroll ? 50 : (FlxG.height - healthBar.height - 50);
		healthBar.barOffset.set(38 - 2, 27 - 2);
		healthBar.barWidth = 441 + 4;
		healthBar.barHeight = 6 + 4;
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);
		
		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 55;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);
		
		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 55;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);
		
		scoreTxt = new FlxText(0, healthBar.y + 65, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("SeuratPro.otf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW_XY(3, 3), 0x98000000);
		scoreTxt.scrollFactor.set();
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		scoreTxt.antialiasing = ClientPrefs.data.antialiasing;
		updateScore(false);
		uiGroup.add(scoreTxt);
		
		livesIcon = new psych.psychlua.ModchartSprite(0, 0, Paths.image('life'));
		livesIcon.scale.set(0.3, 0.3);
		livesIcon.updateHitbox();
		livesIcon.setPosition(25, healthBar.y + (healthBar.height - livesIcon.height) / 2);
		uiGroup.add(livesIcon);
		
		livesTxt = new FlxText(livesIcon.x + livesIcon.width, livesIcon.y + livesIcon.height - 32 + -2, 0, 'x${gameMeta.lives}', 32);
		livesTxt.setFormat(Paths.font('SeuratPro.otf'), 32, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		uiGroup.add(livesTxt);
		
		botplayTxt = new FlxText(400, 475, FlxG.width - 800, "Botplay", 32);
		botplayTxt.setFormat(Paths.font("SeuratPro.otf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		botplayTxt.antialiasing = ClientPrefs.data.antialiasing;
		
		uiGroup.add(botplayTxt);
		// if (ClientPrefs.data.downScroll) botplayTxt.y = FlxG.height - 78;
		
		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		comboGroup.cameras = [camHUD];
		
		startingSong = true;
		
		#if LUA_ALLOWED
		for (notetype in noteTypes) startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed) startLuasNamed('custom_events/' + event + '.lua');
		#end
		
		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes) startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed) startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;
		
		if (eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}
		
		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/')) for (file in FileSystem.readDirectory(folder))
		{
			#if LUA_ALLOWED
			if (file.toLowerCase().endsWith('.lua')) new FunkinLua(folder + file);
			#end
			
			#if HSCRIPT_ALLOWED
			if (file.toLowerCase().endsWith('.hx')) initHScript(folder + file);
			#end
		}
		#end
		
		switch(Paths.formatToSongPath(SONG.song))
		{
		case 'scrambled':
		qqqeb = true;
		}
		
		addMobileControls();
		mobileControls.instance.visible = false;
		mobileControls.onButtonDown.add(onButtonPress);
		mobileControls.onButtonUp.add(onButtonRelease);
		
		startCallback();
		RecalculateRating();
		
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		// PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if (ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');
		
		if (PauseSubState.songName != null) Paths.music(PauseSubState.songName);
		else if (Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none') Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));
		
		resetRPC();
		
		callOnScripts('onCreatePost');
		
		cacheCountdown();
		cachePopUpScore();
		
		#if (!android)
		addTouchPad("NONE", "P");
 		addTouchPadCamera();
		#end
		
		super.create();
		Paths.clearUnusedMemory();
		
		if (eventNotes.length < 1) checkEventNote();
	}
	
	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			if (ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}
	
	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if (generatedMusic)
		{
			vocals.pitch = value;
			opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;
			
			var ratio:Float = playbackRate / value; // funny word huh
			if (ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}
	
	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor)
	{
		var newText:psych.psychlua.DebugLuaText = luaDebugGroup.recycle(psych.psychlua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);
		
		luaDebugGroup.forEachAlive(function(spr:psych.psychlua.DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);
		
		Sys.println(text);
	}
	#end
	
	public function reloadHealthBarColors()
	{
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}
	
	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}
				
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}
				
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}
	
	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if (FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if (FileSystem.exists(luaFile)) doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if (Assets.exists(luaFile)) doPush = true;
		#end
		
		if (doPush)
		{
			for (script in luaArray)
			{
				if (script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if (doPush) new FunkinLua(luaFile);
		}
		#end
		
		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if (FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if (FileSystem.exists(scriptFile)) doPush = true;
		}
		
		if (doPush)
		{
			if (Iris.instances.exists(scriptFile)) doPush = false;
			
			if (doPush) initHScript(scriptFile);
		}
		#end
	}
	
	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		#if LUA_ALLOWED
		if (modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if (variables.exists(tag)) return variables.get(tag);
		#end
		return null;
	}
	
	function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}
	
	#if VIDEOS_ALLOWED
	var video:FlxVideo = null;
	#end
	
	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;
		
		var filepath:String = Paths.video(name);
		#if sys
		if (!FileSystem.exists(filepath))
		#else
		if (!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}
		
		video = new FlxVideo();
		video.load(filepath);
		FlxG.addChildBelowMouse(video);
		
		video.play();
		video.onEndReached.add(function() {
			FlxG.removeChild(video);
			video.dispose();
			startAndEnd();
			return;
		}, true);
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}
	
	dynamic function startAndEnd() // be careful with overriding this
	{
		if (endingSong) endSong();
		else startCountdown();
	}
	
	var dialogueCount:Int = 0;
	
	public var psychDialogue:DialogueBoxS3;
	
	// You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if (psychDialogue != null) return;
		
		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;
			psychDialogue = new DialogueBoxS3(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if (endingSong)
			{
				psychDialogue.finishThing = function() {
					// psychDialogue = null;
					remove(psychDialogue, true);
					
					psychDialogue = FlxDestroyUtil.destroy(psychDialogue);
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function() {
					remove(psychDialogue, true);
					
					psychDialogue = FlxDestroyUtil.destroy(psychDialogue);
					
					startCard();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}
	
	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;
	
	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	
	public static var startOnTime:Float = 0;
	
	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch (stageUI)
		{
			case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
			case "normal": ["ready", "set", "go"];
			default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);
		
		// Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		// Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}
	
	public function startCountdown()
	{
		if (startedCountdown)
		{
			callOnScripts('onStartCountdown');
			return false;
		}
		
		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if (ret != LuaUtils.Function_Stop)
		{
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;
			
			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length)
			{
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length)
			{
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				// if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}
			
			startedCountdown = true;
			mobileControls.instance.visible = #if !android touchPad.visible = #end true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', null);
			
			var swagCounter:Int = 0;
			if (startOnTime > 0)
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();
			
			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer) {
				characterBopper(tmr.loopsLeft);
				
				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch (stageUI)
				{
					case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
					case "normal": ["ready", "set", "go"];
					default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
				}
				introAssets.set(stageUI, introImagesArray);
				
				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;
				
				switch (swagCounter)
				{
					case 0:
						// FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						// FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						tick = START;
				}
				
				notes.forEachAlive(function(note:Note) {
					if (ClientPrefs.data.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if (ClientPrefs.data.middleScroll && !note.mustPress) note.alpha *= 0.35;
					}
				});
				
				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);
				
				swagCounter += 1;
			}, 5);
		}
		return true;
	}
	
	function hiddenCharIntro()
	{
		dad.color = FlxColor.BLACK;
		boyfriend.color = FlxColor.BLACK;
		
		if (gf != null) gf.color = FlxColor.BLACK;
		
		var spr = new FlxBGSprite();
		addBehindGF(spr);
		
		final duration = 0.2;
		
		final options:TweenOptions = {startDelay: (Conductor.crochet / 1000 / playbackRate) * 4};
		
		FlxTween.tween(spr, {alpha: 0}, duration,
			{
				startDelay: options.startDelay,
				onComplete: Void -> {
					remove(spr);
					spr.destroy();
				}
			});
		FlxTween.color(dad, duration, FlxColor.BLACK, FlxColor.WHITE, options);
		FlxTween.color(boyfriend, duration, FlxColor.BLACK, FlxColor.WHITE, options);
		if (gf != null) FlxTween.color(gf, duration, FlxColor.BLACK, FlxColor.WHITE, options);
		
		startCountdown();
	}
	
	public function startCard()
	{
		//
		inCutscene = true;
		
		var grp = new FlxTypedContainer();
		grp.cameras = [camHUD];
		add(grp);
		
		var meta:Meta = null;
		
		final formattedPath = Paths.formatToSongPath(SONG.song);
		final metaString:Null<String> = Paths.getTextFromFile('data/$formattedPath/meta.json');
		if (metaString != null)
		{
			var parsed = Json.parse(metaString);
			
			meta = Difficulty.getString().toLowerCase() == 'hard' ? parsed.hard : parsed.def;
		}
		
		var nameTxt:FlxText = new FlxText(-405, 90, 800, curSong.toUpperCase(), 100);
		nameTxt.alpha = 0;
		nameTxt.setFormat(Paths.font("gaslight.ttf"), 100, FlxColor.WHITE);
		nameTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xff303393, 4);
		
		var songBG:FlxSprite = new FlxSprite(0, -1000).loadGraphic(Paths.image('intro/songtitlebg'));
		
		var side:FlxSprite = new FlxSprite(-450, -5).loadGraphic(Paths.image('intro/songtitlesidething'));
		
		var black:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('intro/songtitleblack'));
		
		var bar:FlxSprite = new FlxSprite(1300, 520).loadGraphic(Paths.image('intro/songtitleSSSbar'));
		
		var charterTxt:FlxText = new FlxText(1300, 400, 0, meta?.charter ?? '???', 60);
		charterTxt.alpha = 0;
		charterTxt.setFormat(Paths.font("gaslight.ttf"), 60, FlxColor.WHITE);
		charterTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xff303393, 3);
		
		var chartIcon:FlxSprite = new FlxSprite(1520, 400).loadGraphic(Paths.image('intro/chartericon'));
		
		var composerTxt:FlxText = new FlxText(1300, 300, 0, meta?.composer ?? '???', 60);
		composerTxt.alpha = 0;
		composerTxt.setFormat(Paths.font("gaslight.ttf"), 60, 0xFFffce25);
		composerTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFFd74f13, 3);
		
		var musicIcon:FlxSprite = new FlxSprite(1520, 300).loadGraphic(Paths.image('intro/composericon'));
		
		black.alpha = 0;
		
		// Layering
		grp.add(black);
		grp.add(songBG);
		grp.add(bar);
		grp.add(side);
		grp.add(charterTxt);
		grp.add(chartIcon);
		grp.add(composerTxt);
		grp.add(musicIcon);
		grp.add(nameTxt);
		
		// Tweens
		
		FlxTween.tween(side, {y: -1400}, 5, {ease: FlxEase.quintOut});
		
		FlxTween.tween(nameTxt, {x: 450}, 1, {ease: FlxEase.quintOut});
		FlxTween.tween(charterTxt, {x: 570}, 1, {ease: FlxEase.quintOut});
		FlxTween.tween(charterTxt, {alpha: 1}, 2, {ease: FlxEase.quintOut});
		FlxTween.tween(chartIcon, {x: 450}, 1, {ease: FlxEase.quintOut});
		FlxTween.tween(composerTxt, {x: 550}, 1, {ease: FlxEase.quintOut});
		FlxTween.tween(composerTxt, {alpha: 1}, 2, {ease: FlxEase.quintOut});
		FlxTween.tween(musicIcon, {x: 460}, 1, {ease: FlxEase.quintOut});
		FlxTween.tween(nameTxt, {alpha: 1}, 2, {ease: FlxEase.quintOut});
		FlxTween.tween(bar, {x: 20}, 1, {ease: FlxEase.quintOut});
		FlxTween.tween(side, {x: -35}, 1, {ease: FlxEase.quintOut});
		FlxTween.tween(songBG, {y: 0}, 1, {ease: FlxEase.quintOut});
		FlxTween.tween(black, {alpha: 1}, 1);
		
		startCountdown();
		
		new FlxTimer().start(2, (f) -> {
			if (f.loopsLeft == 0)
			{
				remove(grp, true);
				grp.destroy();
				return;
			}
			
			FlxTween.tween(black, {alpha: 0}, 1, {ease: FlxEase.quintIn});
			
			FlxTween.tween(bar, {x: 1300}, 0.83, {ease: FlxEase.quintIn});
			FlxTween.tween(songBG, {y: -1000}, 1, {ease: FlxEase.quintIn});
			FlxTween.tween(side, {x: -505}, 0.83, {ease: FlxEase.quintIn});
			
			FlxTween.tween(nameTxt, {x: 1250}, 0.85, {ease: FlxEase.quintIn});
			FlxTween.tween(nameTxt, {alpha: 0}, 0.83, {ease: FlxEase.quintIn});
			
			FlxTween.tween(charterTxt, {x: -225}, 0.85, {ease: FlxEase.quintIn});
			FlxTween.tween(charterTxt, {alpha: 0}, 0.83, {ease: FlxEase.quintIn});
			
			FlxTween.tween(composerTxt, {x: -225}, 0.85, {ease: FlxEase.quintIn});
			FlxTween.tween(composerTxt, {alpha: 0}, 0.83, {ease: FlxEase.quintIn});
			
			FlxTween.tween(musicIcon, {x: -325, alpha: 0}, 0.83, {ease: FlxEase.quintIn});
			FlxTween.tween(chartIcon, {x: -325, alpha: 0}, 0.83, {ease: FlxEase.quintIn});
		}, 2);
	}
	
	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();
		
		if (PlayState.isPixelStage) spr.setGraphicSize(Std.int(spr.width * daPixelZoom));
		
		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000,
			{
				ease: FlxEase.cubeInOut,
				onComplete: function(twn:FlxTween) {
					remove(spr);
					spr.destroy();
				}
			});
		return spr;
	}
	
	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}
	
	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				
				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}
		
		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}
	
	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	public dynamic function updateScore(miss:Bool = false)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop) return;
		
		var str:String = ratingName;
		if (totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str += ' (${percent}%) - ${ratingFC}';
		}
		
		var tempScore:String = 'Score: ${songScore}';
		// "tempScore" variable is used to prevent another memory leak, just in case
		// "\n" here prevents the text from being cut off by beat zooms
		scoreTxt.text = '${tempScore}\n';
		
		if (!miss && !cpuControlled) doScoreBop();
		
		callOnScripts('onUpdateScore', [miss]);
	}
	
	public dynamic function fullComboFunction()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;
		
		ratingFC = "";
		if (songMisses == 0)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else
		{
			if (songMisses < 10) ratingFC = 'SDCB';
			else ratingFC = 'Clear';
		}
	}
	
	public function doScoreBop():Void
	{
		if (!ClientPrefs.data.scoreZoom) return;
		
		if (scoreTxtTween != null) scoreTxtTween.cancel();
		
		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2,
			{
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
	}
	
	public function setSongTime(time:Float)
	{
		if (time < 0) time = 0;
		
		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();
		
		FlxG.sound.music.time = time;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.play();
		
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			opponentVocals.time = time;
			#if FLX_PITCH
			vocals.pitch = playbackRate;
			opponentVocals.pitch = playbackRate;
			#end
		}
		vocals.play();
		opponentVocals.play();
		Conductor.songPosition = time;
	}
	
	public function startNextDialogue()
	{
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}
	
	public function skipDialogue()
	{
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}
	
	function startSong():Void
	{
		startingSong = false;
		
		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		opponentVocals.play();
		
		if (startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;
		
		if (paused)
		{
			// trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if (autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}
	
	var debugNum:Int = 0;
	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch (songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		
		var songData = SONG;
		Conductor.bpm = songData.bpm;
		
		curSong = songData.song;
		
		vocals = new PsychSound();
		opponentVocals = new PsychSound();
		
		try
		{
			if (songData.needsVoices)
			{
				final playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));
				
				final oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
				if (oppVocals != null)
				{
					opponentVocals.loadEmbedded(oppVocals);
					FlxG.sound.list.add(opponentVocals);
				}
			}
		}
		
		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		
		inst = new FlxSound();
		try
		{
			inst.loadEmbedded(Paths.inst(songData.song));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);
		
		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);
		
		var noteData:Array<SwagSection>;
		
		// NEW SHIT
		noteData = songData.notes;
		
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		#else
		if (OpenFlAssets.exists(file))
		#end
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) // Event Notes
				for (i in 0...event[1].length) makeEvent(event, i);
		}
		
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;
				
				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}
				
				var oldNote:Note;
				if (unspawnNotes.length > 0) oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else oldNote = null;
				
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.noteType = songNotes[3];
				if (!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
				
				swagNote.scrollFactor.set();
				
				unspawnNotes.push(swagNote);
				
				final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				final floorSus:Int = Math.floor(susLength);
				
				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);
						
						sustainNote.correctionOffset = swagNote.height / 2;
						if (!PlayState.isPixelStage)
						{
							if (oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}
							
							if (ClientPrefs.data.downScroll) sustainNote.correctionOffset = 0;
						}
						else if (oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}
						
						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if (ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if (daNoteData > 1) // Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}
				
				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if (daNoteData > 1) // Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				
				if (!noteTypes.contains(swagNote.noteType))
				{
					noteTypes.push(swagNote.noteType);
				}
			}
		}
		for (event in songData.events) // Event Notes
			for (i in 0...event[1].length) makeEvent(event, i);
			
		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}
	
	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote)
	{
		eventPushedUnique(event);
		if (eventsPushed.contains(event.event))
		{
			return;
		}
		
		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}
	
	// called by every event with the same name
	function eventPushedUnique(event:EventNote)
	{
		switch (event.event)
		{
			case "Change Character":
				var charType:Int = 0;
				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if (Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}
				
				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
				
			case 'Play Sound':
				Paths.sound(event.value1); // Precache sound
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}
	
	function eventEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Dynamic = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		returnedValue = Std.parseFloat(returnedValue);
		if (!Math.isNaN(returnedValue) && returnedValue != 0 && returnedValue != LuaUtils.Function_Continue)
		{
			return returnedValue;
		}
		
		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}
	
	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	
	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote =
			{
				strumTime: event[0] + ClientPrefs.data.noteOffset,
				event: event[1][i][0],
				value1: event[1][i][1],
				value2: event[1][i][2]
			};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}
	
	public var skipArrowStartTween:Bool = false; // for lua
	
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if (!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if (ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}
			
			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				// babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else babyArrow.alpha = targetAlpha;
			
			if (player == 1) playerStrums.add(babyArrow);
			else
			{
				if (ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}
			
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}
	
	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = false);
		}
		
		super.openSubState(SubState);
	}
	
	override function closeSubState()
	{
		super.closeSubState();
		
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if (!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if (!twn.finished) twn.active = true);
			
			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}
	}
	
	override public function onFocus():Void
	{
		if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.0);
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused && autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
		
		super.onFocusLost();
	}
	
	// Updating Discord Rich Presence.
	public var autoUpdateRPC:Bool = true; // performance setting for custom RPC things
	
	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if (!autoUpdateRPC) return;
		
		if (showTime) DiscordClient.changePresence(detailsText, SONG.song
			+ " ("
			+ storyDifficultyText
			+ ")", iconP2.getCharacter(), true,
			songLength
			- Conductor.songPosition
			- ClientPrefs.data.noteOffset);
		else DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}
	
	function resyncVocals():Void
	{
		if (finishTimer != null) return;
		
		vocals.pause();
		opponentVocals.pause();
		
		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}
		else if (Conductor.songPosition > vocals.length && !vocals.muted)
		{
			trace('shorter vocals muting');
			vocals.muted = true;
		}
		
		if (Conductor.songPosition <= opponentVocals.length)
		{
			opponentVocals.time = Conductor.songPosition;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
		}
		else if (Conductor.songPosition > opponentVocals.length && !opponentVocals.muted)
		{
			trace('shorter opponent vocals muting');
			opponentVocals.muted = true;
		}
		vocals.play();
		opponentVocals.play();
	}
	
	public var paused:Bool = false;
	public var canReset:Bool = true;
	
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = #if RELEASE_BUILD false #else true #end;
	
	override public function update(elapsed:Float)
	{
		if (!inCutscene && !paused && !freezeCamera)
		{
			final lerpValue = 0.04 * cameraSpeed * playbackRate;
			
			FlxG.camera.followLerp = lerpValue;
			if (!startingSong && !endingSong && boyfriend.getAnimationName().startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;
				if (boyfriendIdleTime >= 0.15)
				{ // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else
			{
				boyfriendIdleTime = 0;
			}
		}
		else FlxG.camera.followLerp = 0;
		callOnScripts('onUpdate', [elapsed]);
		
		super.update(elapsed);
		
		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);
		
		if (generatedMusic && !endingSong && !isCameraOnForcedPos) moveCameraSection();
		
		if (botplayTxt != null && botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
		
		if ((controls.PAUSE #if android || FlxG.android.justReleased.BACK #else || touchPad.buttonP.justPressed #end) && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if (ret != LuaUtils.Function_Stop)
			{
				openPauseMenu();
			}
		}
		
		if (!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1')) openChartEditor();
			else if (controls.justPressed('debug_2')) openCharacterEditor();
		}
		
		if (healthBar.bounds.max != null && health > healthBar.bounds.max) health = healthBar.bounds.max;
		
		updateIconsScale(elapsed);
		updateIconsPosition();
		
		if (startedCountdown && !paused) Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		
		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0) startSong();
			else if (!startedCountdown) Conductor.songPosition = -Conductor.crochet * 5;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);
			
			var songCalc:Float = (songLength - curTime);
			songCalc = curTime;
			
			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if (secondsTotal < 0) secondsTotal = 0;
			
			// FlxStringUtil.formatTime(secondsTotal, false); commented this out, if u want the exact time for the song length then this is the line to use
		}
		
		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom * defaultCamZoomMult, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}
		
		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();
		
		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;
			
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;
				
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);
				
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
		
		if (generatedMusic)
		{
			if (!inCutscene)
			{
				if (!cpuControlled) keysCheck();
				else playerDance();
				
				if (notes.length > 0)
				{
					if (startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						notes.forEachAlive(function(daNote:Note) {
							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if (!daNote.mustPress) strumGroup = opponentStrums;
							
							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);
							
							if (daNote.mustPress)
							{
								if (cpuControlled
									&& !daNote.blockHit
									&& daNote.canBeHit
									&& (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition)) goodNoteHit(daNote);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) opponentNoteHit(daNote);
							
							if (daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);
							
							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) noteMiss(daNote);
								
								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note) {
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}
		
		livesTxt.text = 'x${gameMeta.lives}';
		
		#if !RELEASE_BUILD
		if (!endingSong && !startingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if (FlxG.keys.justPressed.TWO)
			{ // Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		
		if (FlxG.keys.justPressed.SIX)
		{
			cpuControlled = !cpuControlled;
			botplayTxt.visible = cpuControlled;
		}
		#end
		
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
	}
	
	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(iconP1.defScale, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();
		
		var mult:Float = FlxMath.lerp(iconP2.defScale, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}
	
	var iconSpacing:Float = 15;
	var iconXOffset:Float = 5;
	
	public dynamic function updateIconsPosition()
	{
		final iconOffset:Float = 26; // magical number
		
		iconP1.x = (healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset) + iconXOffset;
		iconP2.x = (healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2) + iconXOffset;
		iconP1.x += iconSpacing;
		iconP2.x -= iconSpacing;
	}
	
	var iconsAnimations:Bool = true;
	
	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		if (!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			return health;
		}
		
		// update health bar
		health = value;
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);
		
		iconP1.setState(healthBar.percent);
		iconP2.setState(100 - healthBar.percent); // reverse !
		
		return health;
	}
	
	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		if (!cpuControlled)
		{
			for (note in playerStrums) if (note.animation.curAnim != null && note.animation.curAnim.name != 'static')
			{
				note.playAnim('static');
				note.resetAnim = 0;
			}
		}
		openSubState(new PauseSubState());
		
		#if DISCORD_ALLOWED
		if (autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}
	
	function openChartEditor()
	{
		gameMeta.resetHits();
		
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		chartingMode = true;
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end
		
		FlxG.switchState(() -> new ChartingState());
	}
	
	function openCharacterEditor()
	{
		gameMeta.resetHits();
		
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		FlxG.switchState(() -> new CharacterEditorState(SONG.player2));
	}
	
	public var isDead:Bool = false; // Don't mess with this on Lua!!!
	
	function doDeathCheck(?skipHealthCheck:Bool = false)
	{
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if (ret != LuaUtils.Function_Stop)
			{
				FlxG.animationTimeScale = 1;
				boyfriend.stunned = true;
				deathCounter++;
				
				paused = true;
				
				vocals.stop();
				opponentVocals.stop();
				FlxG.sound.music.stop();
				
				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				#if LUA_ALLOWED
				modchartTimers.clear();
				modchartTweens.clear();
				#end
				
				openSubState(new GameOverSubstate());
				
				// FlxG.switchState(()->new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if (autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}
	
	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var leStrumTime:Float = eventNotes[0].strumTime;
			if (Conductor.songPosition < leStrumTime)
			{
				return;
			}
			
			var value1:String = '';
			if (eventNotes[0].value1 != null) value1 = eventNotes[0].value1;
			
			var value2:String = '';
			if (eventNotes[0].value2 != null) value2 = eventNotes[0].value2;
			
			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}
	
	var cameraZoomTween:Null<FlxTween> = null;
	
	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float)
	{
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if (Math.isNaN(flValue1)) flValue1 = null;
		if (Math.isNaN(flValue2)) flValue2 = null;
		
		switch (eventName)
		{
			case 'Force Focus':
				final char = switch (value1)
				{
					case 'bf' | 'boyfriend' | 'player': boyfriend;
					case 'dad' | 'opponent': dad;
					case 'gf' | 'girlfriend': gf;
					default: null;
				}
				camFocusOverride = char;
			case 'Tween Zoom':
				final split = value1.split(',');
				var value = Std.parseFloat(split[0]);
				var time = Std.parseFloat(split[1]);
				if (Math.isNaN(value)) value = 1.0;
				if (Math.isNaN(time)) value = 1.0;
				
				cameraZoomTween?.cancel();
				cameraZoomTween = FlxTween.num(FlxG.camera.zoom, value, time, {ease: LuaUtils.getTweenEaseByString(value2), onComplete: Void -> camZooming = true}, (v) -> {
					camZooming = false;
					FlxG.camera.zoom = v;
					defaultCamZoom = v;
				});
			case 'Set Zoom':
				if (flValue1 == null) flValue1 = defaultCamZoom;
				defaultCamZoom = flValue1;
			case 'Hey!':
				var value:Int = 2;
				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}
				
				if (flValue2 == null || flValue2 <= 0) flValue2 = 0.6;
				
				if (value != 0)
				{
					if (dad.curCharacter.startsWith('gf'))
					{ // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					}
					else if (gf != null)
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if (value != 1)
				{
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}
				
			case 'Set GF Speed':
				if (flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);
				
			case 'Add Camera Zoom':
				if (ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35)
				{
					if (flValue1 == null) flValue1 = 0.015;
					if (flValue2 == null) flValue2 = 0.03;
					
					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}
				
			case 'Play Animation':
				// trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if (flValue2 == null) flValue2 = 0;
						switch (Math.round(flValue2))
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				
				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}
				
			case 'Camera Follow Pos':
				if (camFollow != null)
				{
					isCameraOnForcedPos = false;
					if (flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if (flValue1 == null) flValue1 = 0;
						if (flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}
				
			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val)) val = 0;
						
						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				
				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}
				
			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;
					
					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}
				
			case 'Change Character':
				var charType:Int = 0;
				switch (value1.toLowerCase().trim())
				{
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}
				
				switch (charType)
				{
					case 0:
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}
							
							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);
						
					case 1:
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2))
							{
								addCharacterToList(value2, charType);
							}
							
							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if (!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf')
							{
								if (wasGf && gf != null)
								{
									gf.visible = true;
								}
							}
							else if (gf != null)
							{
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);
						
					case 2:
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								if (!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}
								
								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();
				
			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if (flValue1 == null) flValue1 = 1;
					if (flValue2 == null) flValue2 = 0;
					
					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if (flValue2 <= 0) songSpeed = newValue;
					else songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate,
						{
							ease: FlxEase.linear,
							onComplete: function(twn:FlxTween) {
								songSpeedTween = null;
							}
						});
				}
				
			case 'Set Property':
				try
				{
					var split:Array<String> = value1.split('.');
					if (split.length > 1)
					{
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length - 1], value2);
					}
					else
					{
						#if hl
						final fl = Std.parseFloat(value2);
						if (!Math.isNaN(fl))
						{
							LuaUtils.setVarInArray(this, value1, fl);
							
							return;
						}
						#end
						LuaUtils.setVarInArray(this, value1, value2);
					}
				}
				catch (e:Dynamic)
				{
					#if hl
					trace('ERROR ("Set Property" Event($value1,$value2)) - ${Std.string(e)}');
					return;
					#end
					
					var len:Int = e.message.indexOf('\n') + 1;
					if (len <= 0) len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}
				
			case 'Play Sound':
				if (flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);
		}
		
		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}
	
	function moveCameraSection(?sec:Null<Int>):Void
	{
		if (sec == null) sec = curSection;
		if (sec < 0) sec = 0;
		
		if (SONG.notes[sec] == null) return;
		
		if (gf != null && SONG.notes[sec].gfSection)
		{
			var mainPos = getCharCamPos(camFocusOverride ?? gf).addPoint(getDisplacePoint(gf));
			
			camFollow.x = mainPos.x;
			camFollow.y = mainPos.y;
			
			mainPos.putWeak();
			
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}
		
		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		moveCamera(isDad);
		callOnScripts('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
	}
	
	public function getCharCamPos(char:Character)
	{
		if (char == null) return FlxPoint.get();
		var desiredPos = char.getMidpoint();
		
		if (gf != null && char == gf)
		{
			desiredPos.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			desiredPos.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
		}
		else if (char.isPlayer)
		{
			desiredPos.x -= 100 + (char.cameraPosition[0] - boyfriendCameraOffset[0]);
			desiredPos.y += -100 + char.cameraPosition[1] + boyfriendCameraOffset[1];
		}
		else
		{
			desiredPos.x += 150 + char.cameraPosition[0] + opponentCameraOffset[0];
			desiredPos.y += -100 + char.cameraPosition[1] + opponentCameraOffset[1];
		}
		
		return desiredPos;
	}
	
	public var camOffset:Float = 10;
	
	inline public function getDisplacePoint(char:Character):FlxPoint
	{
		final displace:FlxPoint = FlxPoint.weak();
		if (char == null) return displace;
		
		switch (char.getAnimationName().substr(4).split('-')[0].toLowerCase())
		{
			case 'up':
				displace.set(0, -camOffset);
			case 'down':
				displace.set(0, camOffset);
			case 'left':
				displace.set(-camOffset, 0);
			case 'right':
				displace.set(camOffset, 0);
		}
		
		return displace;
	}
	
	public var camFocusOverride:Null<Character> = null;
	
	public function moveCamera(isDad:Bool)
	{
		final char = camFocusOverride ?? (isDad ? dad : boyfriend);
		
		final charPos = getCharCamPos(char);
		
		final displacePos = getDisplacePoint(char);
		
		displacePos.x /= FlxG.camera.zoom;
		displacePos.y /= FlxG.camera.zoom;
		
		camFollow.x = charPos.x + displacePos.x;
		camFollow.y = charPos.y + displacePos.y;
		
		displacePos.putWeak();
		charPos.putWeak();
	}
	
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;
		
		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();
		
		if (ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset)
		{
			endCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}
	
	public var transitioning = false;
	
	public function endSong()
	{
		// Should kill you if you tried to cheat
		if (!startingSong)
		{
			notes.forEach(function(daNote:Note) {
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset)
				{
					health -= 0.05 * healthLoss;
				}
			}
			
			if (doDeathCheck())
			{
				return false;
			}
		}
		
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;
		
		deathCounter = 0;
		seenCutscene = false;
		
		mobileControls.instance.visible = #if !android touchPad.visible = #end false;
		
		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
		#end
		
		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if (ret != LuaUtils.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if (Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end
			playbackRate = 1;
			
			if (chartingMode)
			{
				openChartEditor();
				return false;
			}
			
			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;
				
				final prevSong = storyPlaylist[0];
				
				storyPlaylist.remove(storyPlaylist[0]);
				
				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					
					openSubState(new MissionClearSubstate(() -> {
						FlxG.switchState(() -> new StoryMenuState());
						
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
					}));
					
					// FlxG.switchState(() -> new StoryMenuState());
					// gameMeta.resetHits(true);
					
					// if ()
					if (!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay'))
					{
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						
						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();
					
					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);
					
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;
					
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();
					
					// callOnHScript('onNextStorySong',[])
					
					openSubState(new MissionClearSubstate(() -> LoadingState.loadAndSwitchState(() -> new PlayState()), prevSong));
					
					// LoadingState.loadAndSwitchState(() -> new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				
				openSubState(new MissionClearSubstate(() -> {
					FlxG.switchState(() -> new FreeplayState());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}));
				
				// FlxG.switchState(() -> new FreeplayState());
				// FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			
			gameMeta.resetHits();
			
			transitioning = true;
		}
		return true;
	}
	
	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}
	
	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	
	public var showCombo:Bool = ClientPrefs.data.showCombo;
	public var showComboNum:Bool = ClientPrefs.data.showCombo;
	public var showRating:Bool = ClientPrefs.data.showCombo;
	
	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;
	
	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';
		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
		}
		
		for (rating in ratingsData) Paths.image(uiPrefix + rating.image + uiSuffix);
		for (i in 0...10) Paths.image(uiPrefix + 'num' + i + uiSuffix);
	}
	
	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;
		
		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
		{
			for (spr in comboGroup)
			{
				spr.destroy();
				comboGroup.remove(spr);
			}
		}
		
		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;
		
		// tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);
		
		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if (!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;
		
		if (daRating.noteSplash && !note.noteSplashData.disabled) spawnNoteSplashOnNote(note);
		
		if (!practiceMode && !cpuControlled)
		{
			songScore += score;
			if (!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}
		
		var uiPrefix:String = "";
		var uiSuffix:String = '';
		var antialias:Bool = ClientPrefs.data.antialiasing;
		
		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
			antialias = !isPixelStage;
		}
		
		rating.loadGraphic(Paths.image(uiPrefix + daRating.image + uiSuffix));
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];
		rating.antialiasing = antialias;
		
		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);
		
		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}
		
		comboSpr.updateHitbox();
		rating.updateHitbox();
		
		var seperatedScore:Array<Int> = [];
		
		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);
		
		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo) comboGroup.add(comboSpr);
		
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.int(i) + uiSuffix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			
			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			numScore.updateHitbox();
			
			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;
			
			// if (combo >= 10 || combo == 0)
			if (showComboNum) comboGroup.add(numScore);
			
			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate,
				{
					onComplete: function(tween:FlxTween) {
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002 / playbackRate
				});
				
			daLoop++;
			if (numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate,
			{
				startDelay: Conductor.crochet * 0.001 / playbackRate
			});
			
		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate,
			{
				onComplete: function(tween:FlxTween) {
					comboSpr.destroy();
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
			
		callOnHScript('onPopUpScore', [note, rating, comboSpr]);
	}
	
	public var strumsBlocked:Array<Bool> = [];
	
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		
		if (!controls.controllerMode)
		{
			#if debug
			// Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end
			
			if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		}
	}
	
	private function keyPressed(key:Int)
	{
		if (cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;
		
		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if (ret == LuaUtils.Function_Stop) return;
		
		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if (Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time;
		
		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return n != null && canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(sortHitNotes);
		
		var shouldMiss:Bool = !ClientPrefs.data.ghostTapping;
		
		if (plrInputNotes.length != 0)
		{ // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note
			
			if (plrInputNotes.length > 1)
			{
				var doubleNote:Note = plrInputNotes[1];
				
				if (doubleNote.noteData == funnyNote.noteData)
				{
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0) invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}
			goodNoteHit(funnyNote);
		}
		else if (shouldMiss)
		{
			callOnScripts('onGhostTap', [key]);
			noteMissPress(key);
		}
		
		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if (!keysPressed.contains(key)) keysPressed.push(key);
		
		// more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;
		
		var spr:StrumNote = playerStrums.members[key];
		if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyPress', [key]);
	}
	
	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority) return 1;
		else if (!a.lowPriority && b.lowPriority) return -1;
		
		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}
	
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if (!controls.controllerMode && key > -1) keyReleased(key);
	}
	
	private function keyReleased(key:Int)
	{
		if (cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrums.length) return;
		
		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if (ret == LuaUtils.Function_Stop) return;
		
		var spr:StrumNote = playerStrums.members[key];
		if (spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyRelease', [key]);
	}
	
	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note) if (key == noteKey) return i;
			}
		}
		return -1;
	}
	
	private function onButtonPress(button:TouchButton):Void
	{
		if (button.IDs.filter(id -> id.toString().startsWith("EXTRA")).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];
		callOnScripts('onButtonPressPre', [buttonCode]);
		if (button.justPressed) keyPressed(buttonCode);
		callOnScripts('onButtonPress', [buttonCode]);
	}

	private function onButtonRelease(button:TouchButton):Void
	{
		if (button.IDs.filter(id -> id.toString().startsWith("EXTRA")).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];
		callOnScripts('onButtonReleasePre', [buttonCode]);
		if(buttonCode > -1) keyReleased(buttonCode);
		callOnScripts('onButtonRelease', [buttonCode]);
	}
	
	// Hold notes
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			if (controls.controllerMode)
			{
				pressArray.push(controls.justPressed(key));
				releaseArray.push(controls.justReleased(key));
			}
		}
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (controls.controllerMode && pressArray.contains(true)) for (i in 0...pressArray.length) if (pressArray[i] && strumsBlocked[i] != true) keyPressed(i);
		
		if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic)
		{
			if (notes.length > 0)
			{
				for (n in notes)
				{ // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);
					
					if (guitarHeroSustains) canHit = canHit && n.parent != null && n.parent.wasGoodHit;
					
					if (canHit && n.isSustainNote)
					{
						var released:Bool = !holdArray[n.noteData];
						
						if (!released) goodNoteHit(n);
					}
				}
			}
			
			if (!holdArray.contains(true) || endingSong) playerDance();
			
			#if ACHIEVEMENTS_ALLOWED
			else checkForAchievement(['oversinging']);
			#end
		}
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if ((controls.controllerMode || strumsBlocked.contains(true))
			&& releaseArray.contains(true)) for (i in 0...releaseArray.length) if (releaseArray[i] || strumsBlocked[i] == true) keyReleased(i);
	}
	
	function noteMiss(daNote:Note):Void
	{ // You didn't hit the key and let it go offscreen, also used by Hurt Notes
		// Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note
				&& daNote.mustPress
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1) invalidateNote(note);
		});
		
		noteMissCommon(daNote.noteData, daNote);
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if (result != LuaUtils.Function_Stop
			&& result != LuaUtils.Function_StopHScript
			&& result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}
	
	function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (ClientPrefs.data.ghostTapping) return; // fuck it
		
		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		callOnScripts('noteMissPress', [direction]);
	}
	
	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = 0.05;
		if (note != null) subtract = note.missHealth;
		
		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null)
		{
			if (note.tail.length > 0)
			{
				note.alpha = 0.35;
				for (childNote in note.tail)
				{
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;
				
				// subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -Tahir
			}
			
			if (note.missed) return;
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote)
		{
			if (note.missed) return;
			
			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0)
			{
				for (child in parentNote.tail) if (child != note)
				{
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}
		
		if (instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}
		
		gameMeta.resetHits();
		
		var lastCombo:Int = combo;
		combo = 0;
		
		health -= subtract * healthLoss;
		if (!practiceMode) songScore -= 10;
		if (!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);
		
		// play character anims
		var char:Character = boyfriend;
		if ((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;
		
		if (char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			var suffix:String = '';
			if (note != null) suffix = note.animSuffix;
			
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, direction)))] + 'miss' + suffix;
			char.playAnim(animToPlay, true);
			
			if (char != gf && lastCombo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		vocals.volume = 0;
	}
	
	function opponentNoteHit(note:Note):Void
	{
		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if (result != LuaUtils.Function_Stop
			&& result != LuaUtils.Function_StopHScript
			&& result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHitPre', [note]);
			
		if (songName != 'tutorial') camZooming = true;
		
		if (note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!note.noAnimation)
		{
			var altAnim:String = note.animSuffix;
			
			if (SONG.notes[curSection] != null) if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) altAnim = '-alt';
			
			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))] + altAnim;
			if (note.gfNote) char = gf;
			
			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}
		
		if (opponentVocals.length <= 0) vocals.volume = 1;
		strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;
		
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if (result != LuaUtils.Function_Stop
			&& result != LuaUtils.Function_StopHScript
			&& result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);
			
		if (!note.isSustainNote) invalidateNote(note);
	}
	
	public function goodNoteHit(note:Note):Void
	{
		if (note.wasGoodHit) return;
		if (cpuControlled && note.ignoreNote) return;
		
		if (!note.isSustainNote && !cpuControlled)
		{
			gameMeta.noteHits++;
			if (gameMeta.noteHits >= S3Meta.HIT_CAP)
			{
				gameMeta.gainLife();
			}
		}
		
		var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;
		
		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop
			&& result != LuaUtils.Function_StopHScript
			&& result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHitPre', [note]);
			
		note.wasGoodHit = true;
		
		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled) FlxG.sound.play(Paths.sound(note.hitsound), ClientPrefs.data.hitsoundVolume);
		
		if (note.hitCausesMiss)
		{
			if (!note.noMissAnimation)
			{
				switch (note.noteType)
				{
					case 'Hurt Note': // Hurt note
						if (boyfriend.animOffsets.exists('hurt'))
						{
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}
			
			noteMiss(note);
			if (!note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
			if (!note.isSustainNote) invalidateNote(note);
			return;
		}
		
		if (!note.noAnimation)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length - 1, note.noteData)))];
			
			var char:Character = boyfriend;
			var animCheck:String = 'hey';
			if (note.gfNote)
			{
				char = gf;
				animCheck = 'cheer';
			}
			
			if (char != null)
			{
				char.playAnim(animToPlay + note.animSuffix, true);
				char.holdTimer = 0;
				
				if (note.noteType == 'Hey!')
				{
					if (char.animOffsets.exists(animCheck))
					{
						char.playAnim(animCheck, true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}
				}
			}
		}
		
		if (!cpuControlled)
		{
			var spr = playerStrums.members[note.noteData];
			if (spr != null) spr.playAnim('confirm', true);
		}
		else strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		vocals.volume = 1;
		
		if (!note.isSustainNote)
		{
			combo++;
			if (combo > 9999) combo = 9999;
			
			if (combo > highestCombo) highestCombo = combo;
			popUpScore(note);
		}
		var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
		if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
		if (gainHealth) health += note.hitHealth * healthGain;
		
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if (result != LuaUtils.Function_Stop
			&& result != LuaUtils.Function_StopHScript
			&& result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);
			
		if (!note.isSustainNote) invalidateNote(note);
	}
	
	public function invalidateNote(note:Note):Void
	{
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}
	
	public function spawnNoteSplashOnNote(note:Note)
	{
		if (note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if (strum != null) spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}
	
	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null)
	{
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}
	
	override function destroy()
	{
		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		#end
		
		#if HSCRIPT_ALLOWED
		for (script in hscriptArray) if (script != null)
		{
			if (script.exists('onDestroy')) script.call('onDestroy');
			script.destroy();
		}
		
		while (hscriptArray.length > 0)
			hscriptArray.pop();
		#end
		
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.animationTimeScale = 1;
		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		Note.globalRgbShaders = [];
		psych.backend.NoteTypesConfig.clearNoteTypesData();
		super.destroy();
		qqqeb = false;
		instance = null;
	}
	
	var lastStepHit:Int = -1;
	var lastBeatHit:Int = -1;
	
	var beatsPerZoom:Int = 4;
	
	override function stepHit()
	{
		if (SONG.needsVoices && FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			var timeSub:Float = Conductor.songPosition - Conductor.offset;
			var syncTime:Float = 20 * playbackRate;
			if (Math.abs(FlxG.sound.music.time - timeSub) > syncTime
				|| (vocals.length > 0 && Math.abs(vocals.time - timeSub) > syncTime)
				|| (opponentVocals.length > 0 && Math.abs(opponentVocals.time - timeSub) > syncTime))
			{
				resyncVocals();
			}
		}
		
		super.stepHit();
		
		if (curStep == lastStepHit)
		{
			return;
		}
		
		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}
	
	override function beatHit()
	{
		if (lastBeatHit >= curBeat)
		{
			// trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}
		
		if (camZooming
			&& FlxG.camera.zoom < (defaultCamZoom * 1.35)
			&& ClientPrefs.data.camZooms
			&& beatsPerZoom > 0
			&& curBeat % beatsPerZoom == 0)
		{
			FlxG.camera.zoom += 0.015 * camZoomingMult;
			camHUD.zoom += 0.03 * camZoomingMult;
		}
		
		if (generatedMusic) notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		
		iconP1.scale.set(iconP1.defScale * 1.2, iconP1.defScale * 1.2);
		iconP2.scale.set(iconP2.defScale * 1.2, iconP2.defScale * 1.2);
		
		iconP1.updateHitbox();
		iconP2.updateHitbox();
		
		characterBopper(curBeat);
		
		super.beatHit();
		lastBeatHit = curBeat;
		
		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}
	
	public function characterBopper(beat:Int):Void
	{
		if (gf != null
			&& beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& !gf.getAnimationName().startsWith('sing')
			&& !gf.stunned) gf.dance();
		if (boyfriend != null
			&& beat % boyfriend.danceEveryNumBeats == 0
			&& !boyfriend.getAnimationName().startsWith('sing')
			&& !boyfriend.stunned) boyfriend.dance();
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned) dad.dance();
	}
	
	public function playerDance():Void
	{
		var anim:String = boyfriend.getAnimationName();
		if (boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * boyfriend.singDuration && anim.startsWith('sing') && !anim.endsWith('miss'))
			boyfriend.dance();
	}
	
	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			// if (generatedMusic && !endingSong && !isCameraOnForcedPos) moveCameraSection();
			
			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();
		
		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}
	
	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if (!FileSystem.exists(luaToLoad)) luaToLoad = Paths.getSharedPath(luaFile);
		
		if (FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if (OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray) if (script.scriptName == luaToLoad) return false;
			
			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end
	
	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if (!FileSystem.exists(scriptToLoad)) scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end
		
		if (FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;
			
			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}
	
	public function initHScript(file:String)
	{
		var newScript:HScript = null;
		try
		{
			newScript = new HScript(null, file);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
		}
		catch (e:IrisError)
		{
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast(Iris.instances.get(file), HScript);
			if (newScript != null) newScript.destroy();
		}
	}
	#end
	
	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if (args == null) args = [];
		if (exclusions == null) exclusions = [];
		if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];
		
		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if (result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}
	
	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if (args == null) args = [];
		if (exclusions == null) exclusions = [];
		if (excludeValues == null) excludeValues = [LuaUtils.Function_Continue];
		
		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{
			if (script.closed)
			{
				arr.push(script);
				continue;
			}
			
			if (exclusions.contains(script.scriptName)) continue;
			
			var myValue:Dynamic = script.call(funcToCall, args);
			if ((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll)
				&& !excludeValues.contains(myValue)
				&& !ignoreStops)
			{
				returnVal = myValue;
				break;
			}
			
			if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
			
			if (script.closed) arr.push(script);
		}
		
		if (arr.length > 0) for (script in arr) luaArray.remove(script);
		#end
		return returnVal;
	}
	
	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		
		#if HSCRIPT_ALLOWED
		if (exclusions == null) exclusions = new Array();
		if (excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);
		
		var len:Int = hscriptArray.length;
		if (len < 1) return returnVal;
		
		for (script in hscriptArray)
		{
			@:privateAccess
			if (script == null || !script.exists(funcToCall) || exclusions.contains(script.origin)) continue;
			
			var callValue = script.call(funcToCall, args);
			if (callValue != null)
			{
				var myValue:Dynamic = callValue.returnValue;
				
				if ((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)
					&& !excludeValues.contains(myValue)
					&& !ignoreStops)
				{
					returnVal = myValue;
					break;
				}
				
				if (myValue != null && !excludeValues.contains(myValue)) returnVal = myValue;
			}
		}
		#end
		
		return returnVal;
	}
	
	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		if (exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}
	
	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if LUA_ALLOWED
		if (exclusions == null) exclusions = [];
		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName)) continue;
			
			script.set(variable, arg);
		}
		#end
	}
	
	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
	{
		#if HSCRIPT_ALLOWED
		if (exclusions == null) exclusions = [];
		for (script in hscriptArray)
		{
			if (exclusions.contains(script.origin)) continue;
			
			script.set(variable, arg);
		}
		#end
	}
	
	function strumPlayAnim(isDad:Bool, id:Int, time:Float)
	{
		var spr:StrumNote = null;
		if (isDad)
		{
			spr = opponentStrums.members[id];
		}
		else
		{
			spr = playerStrums.members[id];
		}
		
		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}
	
	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	
	public function RecalculateRating(badHit:Bool = false)
	{
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);
		
		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if (ret != LuaUtils.Function_Stop)
		{
			ratingName = '?';
			if (totalPlayed != 0) // Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);
				
				// Rating Name
				ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				if (ratingPercent < 1) for (i in 0...ratingStuff.length - 1) if (ratingPercent < ratingStuff[i][1])
				{
					ratingName = ratingStuff[i][0];
					break;
				}
			}
			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}
	
	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if (chartingMode) return;
		
		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if (cpuControlled) return;
		
		for (name in achievesToCheck)
		{
			if (!Achievements.exists(name)) continue;
			
			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
			{
				switch (name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);
						
					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);
						
					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);
						
					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);
						
					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);
						
					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);
						
					case 'debugger':
						unlock = (songName == 'test' && !usedPractice);
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if (isStoryMode
					&& campaignMisses + songMisses < 1
					&& Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1
					&& !changedDifficulty
					&& !usedPractice) unlock = true;
			}
			
			if (unlock) Achievements.unlock(name);
		}
	}
	#end
	
	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if (!ClientPrefs.data.shaders) return new FlxRuntimeShader();
		
		#if (!flash && MODS_ALLOWED && sys)
		if (!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}
		
		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}
	
	public function initLuaShader(name:String, ?glslVersion:Int = 100)
	{
		if (!ClientPrefs.data.shaders) return false;
		
		#if (MODS_ALLOWED && !flash && sys)
		if (runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}
		
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if (FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;
			
			if (FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;
			
			if (found)
			{
				runtimeShaders.set(name, [frag, vert]);
				// trace('Found shader $name!');
				return true;
			}
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
		#else
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
	#end
	
	public function makeLuaTouchPad(DPadMode:String, ActionMode:String) {
		if(members.contains(luaTouchPad)) return;

		if(!variables.exists("luaTouchPad"))
			variables.set("luaTouchPad", luaTouchPad);

		luaTouchPad = new TouchPad(DPadMode, ActionMode, NONE);
		luaTouchPad.alpha = ClientPrefs.data.controlsAlpha;
	}
	
	public function addLuaTouchPad() {
		if(luaTouchPad == null || members.contains(luaTouchPad)) return;

		var target = LuaUtils.getTargetInstance();
		target.insert(target.members.length + 1, luaTouchPad);
	}

	public function addLuaTouchPadCamera() {
		if(luaTouchPad != null)
			luaTouchPad.cameras = [luaTpadCam];
	}

	public function removeLuaTouchPad() {
		if (luaTouchPad != null) {
			luaTouchPad.kill();
			luaTouchPad.destroy();
			remove(luaTouchPad);
			luaTouchPad = null;
		}
	}

	public function luaTouchPadPressed(button:Dynamic):Bool {
		if(luaTouchPad != null) {
			if(Std.isOfType(button, String))
				return luaTouchPad.buttonPressed(MobileInputID.fromString(button));
			else if(Std.isOfType(button, Array)){
				var FUCK:Array<String> = button; // haxe said "You Can't Iterate On A Dyanmic Value Please Specificy Iterator or Iterable *insert nerd emoji*" so that's the only i foud to fix
				var idArray:Array<MobileInputID> = [];
				for(strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyPressed(idArray);
			} else
				return false;
		}
		return false;
	}

	public function luaTouchPadJustPressed(button:Dynamic):Bool {
		if(luaTouchPad != null) {
			if(Std.isOfType(button, String))
				return luaTouchPad.buttonJustPressed(MobileInputID.fromString(button));
			else if(Std.isOfType(button, Array)){
				var FUCK:Array<String> = button;
				var idArray:Array<MobileInputID> = [];
				for(strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyJustPressed(idArray);
			} else
				return false;
		}
		return false;
	}
	
	public function luaTouchPadJustReleased(button:Dynamic):Bool {
		if(luaTouchPad != null) {
			if(Std.isOfType(button, String))
				return luaTouchPad.buttonJustReleased(MobileInputID.fromString(button));
			else if(Std.isOfType(button, Array)){
				var FUCK:Array<String> = button;
				var idArray:Array<MobileInputID> = [];
				for(strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyJustReleased(idArray);
			} else
				return false;
		}
		return false;
	}

	public function luaTouchPadReleased(button:Dynamic):Bool {
		if(luaTouchPad != null) {
			if(Std.isOfType(button, String))
				return luaTouchPad.buttonJustReleased(MobileInputID.fromString(button));
			else if(Std.isOfType(button, Array)){
				var FUCK:Array<String> = button;
				var idArray:Array<MobileInputID> = [];
				for(strId in FUCK)
					idArray.push(MobileInputID.fromString(strId));
				return luaTouchPad.anyReleased(idArray);
			} else
				return false;
		}
		return false;
	}
}
