package psych.backend;

import flixel.addons.ui.FlxUIState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxState;

import psych.backend.SonicFadeTransition;

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;
	
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	
	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	
	public var controls(get, never):Controls;
	
	private function get_controls()
	{
		return Controls.instance;
	}
	
	var _psychCameraInitialized:Bool = false;
	
	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end
		
		if (!_psychCameraInitialized) initPsychCamera();
		
		super.create();
		
		if (!skip)
		{
			openSubState(new SonicFadeTransition(0.6, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}
	
	public function initPsychCamera():RotationCamera
	{
		var camera = new RotationCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}
	
	public static var timePassedOnState:Float = 0;
	
	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;
		timePassedOnState += elapsed;
		
		updateCurStep();
		updateBeat();
		
		if (oldStep != curStep)
		{
			if (curStep > 0) stepHit();
			
			if (PlayState.SONG != null)
			{
				if (oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}
		
		if (FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;
		
		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});
		
		super.update(elapsed);
	}
	
	private function updateSection():Void
	{
		if (stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while (curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}
	
	private function rollbackSection():Void
	{
		if (curStep < 0) return;
		
		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if (stepsToDo > curStep) break;
				
				curSection++;
			}
		}
		
		if (curSection > lastSection) sectionHit();
	}
	
	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}
	
	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		
		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}
	
	override function startOutro(onOutroComplete:() -> Void)
	{
		if (!FlxTransitionableState.skipNextTransIn)
		{
			openSubState(new SonicFadeTransition(0.6, false));
			SonicFadeTransition.finishCallback = onOutroComplete;
			return;
		}
		
		FlxTransitionableState.skipNextTransIn = false;
		
		super.startOutro(onOutroComplete);
	}
	
	public static function getState():MusicBeatState
	{
		return cast(FlxG.state, MusicBeatState);
	}
	
	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});
		
		if (curStep % 4 == 0) beatHit();
	}
	
	public var stages:Array<BaseStage> = [];
	
	public function beatHit():Void
	{
		// trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}
	
	public function sectionHit():Void
	{
		// trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}
	
	function stagesFunc(func:BaseStage->Void)
	{
		for (stage in stages) if (stage != null && stage.exists && stage.active) func(stage);
	}
	
	function getBeatsOnSection():Float
	{
		return PlayState.SONG?.notes[curSection]?.sectionBeats ?? 4;
	}
	
	public function refreshZ(?group:FlxTypedGroup<flixel.FlxBasic>)
	{
		group ??= FlxG.state;
		
		group.sort(sortByZ, flixel.util.FlxSort.ASCENDING);
	}
	
	public static function sortByZ(order:Int, a:flixel.FlxBasic, b:flixel.FlxBasic):Int
	{
		if (a == null || b == null) return 0;
		return flixel.util.FlxSort.byValues(order, a.zIndex, b.zIndex);
	}
}
