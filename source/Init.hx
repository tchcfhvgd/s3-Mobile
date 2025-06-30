import psych.backend.ClientPrefs;
import psych.states.PlayState;

import flixel.addons.transition.FlxTransitionableState;

import psych.states.TitleState;

import flixel.FlxState;
import flixel.input.keyboard.FlxKey;

class Init extends FlxState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	override function create()
	{
		super.create();
		
		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		psych.backend.ClientPrefs.loadPrefs();
		
		psych.backend.Highscore.load();
		
		MobileData.init();
		
		if (FlxG.save.data.weekCompleted != null)
		{
			psych.states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}
		
		FlxG.mouse.useSystemCursor = true;
		
		PlayState.gameMeta.lives = ClientPrefs.data.heldLives;
		
		FlxG.plugins.addPlugin(new psych.plugins.FullScreenPlugin());
		#if !RELEASE_BUILD
		FlxG.plugins.addPlugin(new psych.plugins.HotReloadPlugin());
		#end
		
		#if FLX_DEBUG
		FlxG.console.registerClass(psych.states.PlayState);
		#end
		
		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init();
		#end
		
		FlxTransitionableState.skipNextTransOut = true;
		
		FlxG.switchState(() -> Type.createInstance(Main.game.initialState, []));
	}
}
