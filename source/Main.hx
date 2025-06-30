package;

import psych.debug.FPSCounter;

import flixel.graphics.FlxGraphic;
import flixel.FlxGame;
import flixel.FlxState;

import haxe.io.Path;

import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;

import lime.system.System as LimeSystem;
import lime.app.Application;

import psych.states.TitleState;
import mobile.backend.MobileScaleMode;

#if linux
import lime.graphics.Image;
#end

#if COPYSTATE_ALLOWED
import psych.states.CopyState;
#end

#if linux
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('
	#define GAMEMODE_AUTO
')
#end
class Main extends Sprite
{
	public static final game =
		{
			width: 1280, // WINDOW width
			height: 720, // WINDOW height
			initialState: psych.states.TitleState, // initial game state
			framerate: 60, // default framerate
			skipSplash: true, // if the default flixel splash screen should be skipped
			startFullscreen: false // if the game should start at fullscreen mode
		};
		
	public static var fpsVar:Null<FPSCounter> = null;
	
	// You can pretty much ignore everything from here on - your code should go in your states.
	
	public static function main():Void
	{
		psych.macros.MacroUtil.haxeVersionEnforcement();
		Lib.current.addChild(new Main());
		#if cpp
        cpp.NativeGc.enable(true);
        cpp.NativeGc.run(true);
        #end
	}
	
	public function new()
	{
		super();
		
		#if mobile
		#if android
		StorageUtil.requestPermissions();
		#end
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end
		psych.backend.CrashHandler.init();
		
		#if windows
		psych.backend.system.WindowsNative.setDpiAware();
		#end
		
		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psych.psychlua.CallbackHandler.call)); #end
		psych.backend.Controls.instance = new psych.backend.Controls();
		psych.backend.ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED psych.backend.Achievements.load(); #end
		
		FlxG.save.bind('funkin', psych.backend.CoolUtil.getSavePath());
		
		addChild(new FlxGame(game.width, game.height, #if COPYSTATE_ALLOWED !CopyState.checkExistingFiles() ? CopyState : #end Init, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		#if !mobile
		addChild(fpsVar);
		#else
		FlxG.game.addChild(fpsVar);
		#end
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = psych.backend.ClientPrefs.data.showFPS;
		}
		
		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end
		
		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		
		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		#if mobile
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		FlxG.scaleMode = new MobileScaleMode();
		#end
		
		#if DISCORD_ALLOWED
		psych.backend.DiscordClient.prepare();
		#end
		
		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h) {
			if (FlxG.cameras != null)
			{
				for (cam in FlxG.cameras.list)
				{
					if (cam != null && cam.filters != null) resetSpriteCache(cam.flashSprite);
				}
			}
			
			if (FlxG.game != null) resetSpriteCache(FlxG.game);
		});
	}
	
	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}
