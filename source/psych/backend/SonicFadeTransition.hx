package psych.backend;

import openfl.filters.ShaderFilter;

import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxGradient;

class SonicFadeTransition extends MusicBeatSubstate
{
	public static var finishCallback:Void->Void = null;
	
	static var personalManager:Null<FlxTweenManager> = null;
	
	final isTransIn:Bool;
	final duration:Float;
	
	var spr:FlxSprite;
	
	var shader:BlueFadeShader;
	var filter:ShaderFilter;
	
	public function new(duration:Float = 0.5, isTransIn:Bool = false)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
		
		init();
	}
	
	static function init()
	{
		static var wasInitiated:Bool = false;
		if (wasInitiated) return;
		
		FlxG.plugins.addPlugin(personalManager = new FlxTweenManager());
	}
	
	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		
		shader = new BlueFadeShader(isTransIn ? 1 : 0);
		
		filter = new ShaderFilter(shader);
		
		// for (i in FlxG.cameras.list)
		// {
		// 	i.filters ??= [];
		// 	i.filters.push(filter);
		// }
		
		// FlxG.camera.filters = [filter];
		
		FlxG.game.setFilters([filter]);
		
		personalManager.tween(shader, {transitionValue: isTransIn ? 0 : 1}, duration, {onComplete: onFinish, ease: isTransIn ? FlxEase.sineOut : FlxEase.sineIn});
		
		// not as nice but not applying a shader to 3 cameras method
		
		// spr = new FlxSprite().makeScaledGraphic(camera.viewWidth, camera.viewHeight, FlxColor.WHITE);
		// spr.color = 0xFF03014E;
		// add(spr);
		// spr.scrollFactor.set();
		// spr.alpha = isTransIn ? 1 : 0;
		// FlxTween.tween(spr, {alpha: isTransIn ? 0 : 1}, duration,
		// 	{
		// 		onComplete: onFinish,
		// 		onUpdate: twn -> {
		// 			var sCol = 0xFF0700D3;
		// 			var startColour = !isTransIn ? 0xFF0700D3 : FlxColor.BLACK;
		// 			var endColour = !isTransIn ? FlxColor.BLACK : 0xFF0700D3;
		// 			spr.color = FlxColor.interpolate(startColour, endColour, twn.percent);
		// 		}
		// 	});
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	function onFinish(twn)
	{
		close();
		if (finishCallback != null)
		{
			finishCallback();
		}
		finishCallback = null;
		// FlxTimer.wait(0, close);
		
		if (isTransIn)
		{
			// for (i in FlxG.cameras.list)
			// {
			// 	i.filters ??= [];
			// 	i.filters.remove(filter);
			// }
			@:privateAccess
			if (FlxG.game._filters != null) FlxG.game._filters.remove(filter);
		}
	}
}

class BlueFadeShader extends FlxGraphicsShader
{
	@:isVar public var transitionValue(get, set):Float = 0;
	
	function set_transitionValue(value:Float):Float
	{
		this.percent.value = [value, value];
		return value;
	}
	
	function get_transitionValue():Float
	{
		return this.percent.value[0];
	}
	
	@:glFragmentSource('
	#pragma header

	uniform float percent;
	void main() 
	{
		vec2 uv = openfl_TextureCoordv.xy;
		vec4 color = flixel_texture2D(bitmap, uv);
	
	
    	color.rgb = clamp(color.rgb + (percent * -1.0) * normalize(vec3(5.0, 2.0, 1.0)) * 8.0, 0.0, 1.0);
		gl_FragColor = color;
	}
			
		
	')
	public function new(val:Float = 0)
	{
		super();
		transitionValue = val;
	}
}
