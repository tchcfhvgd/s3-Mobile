package psych.states;

import psych.objects.RepeatInput;

import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.util.FlxDestroyUtil;

import psych.psychlua.ModchartSprite;

using psych.states.S3Credits;

class S3CreditsMain extends MusicBeatState
{
	var buttons:FlxTypedContainer<SubButton>;
	
	public static var initiated:Bool = false;
	
	static var curSelected:Int = 0;
	
	override function create()
	{
		super.create();
		
		var bg = new ModchartSprite(Paths.image('menu/credits/primary/background')).to720();
		bg.scale.scale(1.1);
		add(bg);
		
		var bg = new ModchartSprite(FlxG.width, 0, Paths.image('menu/credits/primary/background_part_2')).to720();
		bg.scale.scale(1.1);
		add(bg);
		FlxTween.tween(bg, {x: FlxG.width - bg.width}, 0.4, {ease: FlxEase.cubeOut});
		
		var txt = new ModchartSprite(Paths.image('menu/credits/primary/credit_bg')).to720();
		add(txt);
		txt.x = -txt.width;
		txt.scrollFactor.set();
		
		FlxTween.tween(txt, {x: 0}, 0.2, {ease: FlxEase.sineOut});
		
		var txt = new ModchartSprite(Paths.image('menu/credits/primary/credit')).to720();
		add(txt);
		txt.x = -txt.width;
		txt.scrollFactor.set();
		
		FlxTween.tween(txt, {x: 0}, 0.2, {ease: FlxEase.sineOut, startDelay: 0.05});
		
		buttons = new FlxTypedContainer();
		add(buttons);
		
		for (i in ['artist', 'music', 'code', 'chart', 'va'])
		{
			var button = new SubButton(i);
			button.scrollFactor.set();
			buttons.add(button);
		}
		
		reposButtons(0, true);
		
		if (!initiated)
		{
			for (k => i in buttons)
			{
				var fromLeft = k % 2 == 0;
				var lastX = i.x;
				i.x = fromLeft ? -i.width - 20 : FlxG.width + 20;
				FlxTween.tween(i, {x: lastX}, 0.4, {ease: FlxEase.cubeOut, startDelay: 0.5 + 0.05 * k});
			}
		}
		
		initiated = true;
		
		changeSel();
	}
	
	override function startOutro(onOutroComplete:() -> Void)
	{
		for (i in buttons) FlxTween.cancelTweensOf(i, ['x']);
		
		super.startOutro(onOutroComplete);
	}
	
	var holdTime:Float = 0;
	
	var elap:Float = 0;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		// reposButtons(elapsed);
		if (controls.BACK) FlxG.switchState(() -> new MainMenuState());
		
		if (controls.UI_DOWN_P || controls.UI_UP_P) changeSel(controls.UI_DOWN_P ? 1 : -1);
		
		if (controls.UI_DOWN || controls.UI_UP)
		{
			final checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			final checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
			
			final repeat = holdTime > 0.5 && checkNewHold - checkLastHold > 0;
			
			if (repeat) changeSel(controls.UI_DOWN ? 1 : -1);
		}
		else
		{
			holdTime = 0;
		}
		
		if (controls.ACCEPT) openCredit();
		
		elap += elapsed;
		
		FlxG.camera.scroll.x += Math.cos(elap) * 0.03;
		FlxG.camera.scroll.y += Math.sin(elap) * 0.03;
	}
	
	function openCredit()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));
		final role = buttons.members[curSelected].title;
		FlxG.switchState(() -> new S3Credits(role));
	}
	
	// nvm ig
	function reposButtons(elapsed:Float, snap:Bool = false)
	{
		final lerpRate = FlxMath.getElapsedLerp(0.16, elapsed);
		
		for (k => i in buttons)
		{
			final target = k; //- curSelected;
			
			final ySpacing = 145;
			final xSpacing = -125;
			
			final xStart = 750;
			final yStart = 25;
			
			if (snap)
			{
				i.x = (target * 1.3 * xSpacing) + xStart;
				i.y = (target * ySpacing) + yStart;
			}
			else
			{
				i.x = FlxMath.lerp(i.x, (target * 1.3 * xSpacing) + xStart, lerpRate);
				i.y = FlxMath.lerp(i.y, (target * ySpacing) + yStart, lerpRate);
			}
		}
	}
	
	function changeSel(diff:Int = 0)
	{
		if (diff != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
		buttons.members[curSelected].resetRed();
		
		curSelected = FlxMath.wrap(curSelected + diff, 0, buttons.length - 1);
		buttons.members[curSelected].bounce();
	}
}

private class SubButton extends ModchartSprite
{
	public final title:String;
	
	final red:ModchartSprite;
	final name:ModchartSprite;
	
	public function new(title:String)
	{
		super(Paths.image('menu/credits/primary/box'));
		this.to720();
		
		red = new ModchartSprite(Paths.image('menu/credits/primary/box_red')).to720();
		
		name = new ModchartSprite(Paths.image('menu/credits/primary/$title')).to720();
		
		this.title = title;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		red.x = x + 6;
		red.y = y + 10;
		
		name.x = x + (width - name.width) / 2;
		name.y = y;
		
		name.scrollFactor.copyFrom(scrollFactor);
		red.scrollFactor.copyFrom(scrollFactor);
	}
	
	override function draw()
	{
		red.draw();
		super.draw();
		name.draw();
	}
	
	override function destroy()
	{
		FlxDestroyUtil.destroy(red);
		FlxDestroyUtil.destroy(name);
		
		super.destroy();
	}
	
	public function resetRed()
	{
		red.colorTransform.redOffset = 0;
		red.colorTransform.greenOffset = 0;
		red.colorTransform.blueOffset = 0;
		redTween?.cancel();
	}
	
	var redTween:FlxTween;
	
	public function bounce()
	{
		resetRed();
		
		redTween = FlxTween.num(0, 255, 1, {type: PINGPONG}, f -> {
			red.colorTransform.redOffset = f;
			red.colorTransform.greenOffset = f;
			red.colorTransform.blueOffset = f;
		});
		
		FlxTween.num(10, 0, 0.25, {}, f -> {
			red.centerOffsets();
			red.offset.x -= f;
			red.offset.y -= f;
			
			centerOffsets();
			offset.x += f;
			offset.y += f;
			
			name.centerOffsets();
			name.offset.x += f;
			name.offset.y += f;
		});
	}
}
