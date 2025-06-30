package psych.objects;

import flixel.util.FlxDestroyUtil;

class GenerationsText extends FlxText
{
	public final shadow:FlxText;
	
	public final shadowXY:FlxPoint;
	
	public function new(x:Float = 0, y:Float = 0, fw:Float = 0, txt:String, size:Int = 24)
	{
		super(x, y, fw, txt, size);
		font = Paths.font('SeuratPro.otf');
		borderStyle = OUTLINE;
		borderSize = 3;
		borderColor = FlxColor.BLACK;
		
		shadow = new FlxText(x, y, fw, txt, size);
		shadow.font = font;
		shadow.color = 0xFF777777;
		shadow.borderSize = 3;
		shadow.borderStyle = OUTLINE_FAST;
		shadow.borderColor = 0xFF777777;
		
		shadowXY = new FlxPoint(3, 3);
	}
	
	override function draw()
	{
		if (shadow.visible) shadow.draw();
		super.draw();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		shadow.text = text;
		shadow.scrollFactor.copyFrom(scrollFactor);
		shadow.offset.copyFrom(offset);
		shadow.origin.copyFrom(origin);
		shadow.scale.copyFrom(scale);
		shadow.alpha = alpha;
		
		shadow.x = x + shadowXY.x;
		shadow.y = y + shadowXY.y;
		
		if (shadow.alignment != alignment) shadow.alignment = alignment;
	}
	
	override function destroy()
	{
		super.destroy();
		FlxDestroyUtil.destroy(shadow);
		FlxDestroyUtil.put(shadowXY);
	}
}
