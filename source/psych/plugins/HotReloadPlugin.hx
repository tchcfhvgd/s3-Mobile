package psych.plugins;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxBasic;

class HotReloadPlugin extends FlxBasic
{
	public function new()
	{
		super();
		this.visible = false;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		
		if (FlxG.keys.justPressed.F6)
		{
			FlxG.signals.preStateCreate.addOnce((state) -> {
				Paths.clearStoredMemory();
				Paths.clearUnusedMemory();
			});
			
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
	}
}
