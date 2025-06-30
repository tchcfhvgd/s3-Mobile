package;

#if android
import android.content.Context;
#end

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

import lime.app.Application;

import psych.states.TitleState;

#if linux
import lime.graphics.Image;
#end

// crash handler stuff
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;

import haxe.CallStack;
import haxe.io.Path;
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
	}
	
	public function new()
	{
		super();
		
		psych.backend.system.WindowsNative.setDpiAware();
		
		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end
		
		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psych.psychlua.CallbackHandler.call)); #end
		psych.backend.Controls.instance = new psych.backend.Controls();
		psych.backend.ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED psych.backend.Achievements.load(); #end
		
		FlxG.save.bind('funkin', psych.backend.CoolUtil.getSavePath());
		
		addChild(new FlxGame(game.width, game.height, Init, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		
		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = psych.backend.ClientPrefs.data.showFPS;
		}
		#end
		
		#if linux
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end
		
		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
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
	
	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();
		
		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");
		
		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";
		
		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}
		
		errMsg += "\nUncaught Error: "
			+ e.error
			+ "\nPlease report this error to the GitHub page: https://github.com/ShadowMario/FNF-PsychEngine\n\n> Crash Handler written by: sqirra-rng";
			
		if (!sys.FileSystem.exists("./crash/")) sys.FileSystem.createDirectory("./crash/");
		
		sys.io.File.saveContent(path, errMsg + "\n");
		
		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));
		
		Application.current.window.alert(errMsg, "Error!");
		#if DISCORD_ALLOWED
		psych.backend.DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}
