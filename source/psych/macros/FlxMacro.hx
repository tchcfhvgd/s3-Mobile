package psych.macros;

#if macro
import haxe.macro.Context;

/**
 * Variety of macros to help add additional features to flixel we want/need
 */
class FlxMacro
{
	public static macro function buildFlxSprite():Array<haxe.macro.Expr.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();
		
		fields.push(
			{
				doc: "	
				*
				* Flixel 5.9.0 animation crash fix
				* 
				* Due to a change in when callbacks are called, destroying a sprite on animation finished will crash the game
				* 
				* So to compensate we will wait one update call before destroying it 
				*",
				name: "delayAndDestroy",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [],
						expr: macro
						{
							this.visible = false;
							this.active = false;
							flixel.util.FlxTimer.wait(0, this.destroy);
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "creates a 1x1 graphic scaled to the size",
				name: "makeScaledGraphic",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: 'width', type: (macro :Float), value: macro $v{1.0}},
							{name: 'height', type: (macro :Float), value: macro $v{1.0}},
							{name: "color", type: (macro :flixel.util.FlxColor), value: macro $v{cast 0xFFFFFFFF}},
						],
						expr: macro
						{
							this.makeGraphic(1, 1, color, false, '#${color.toHexString(true, false)}');
							this.scale.set(width, height);
							this.updateHitbox();
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "centers `this` onto another FlxObject by hitbox",
				name: "centerOnObject",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: 'object', type: (macro :flixel.FlxObject)},
							{name: 'axes', type: (macro :flixel.util.FlxAxes), opt: true},
						],
						expr: macro
						{
							axes ??= flixel.util.FlxAxes.XY;
							if (axes.x) this.x = object.x + (object.width - this.width) / 2;
							if (axes.y) this.y = object.y + (object.height - this.height) / 2;
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "	
			*
			*	Loads a sprites frames in a similar manor to loadGraphic for convenience
			*",
				name: "loadAtlasFrames",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: "frames", type: (macro :flixel.graphics.frames.FlxAtlasFrames)}],
						expr: macro
						{
							this.frames = frames;
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		return fields;
	}
	
	/**
	 * Having these with buildFlxSprite felt wrong?? so im moving it here
	 * 
	 * These are more funkin specific functions
	 * @return Array<haxe.macro.Expr.Field>
	 */
	public static macro function BuildFunkinSprite():Array<haxe.macro.Expr.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();
		
		fields.push(
			{
				doc: "	
				*
				*	LoadFrames but goes through Paths for Convenience
				*",
				name: "loadFunkinSparrow",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: "path", type: (macro :String)},
							{name: "library", type: (macro :String), opt: true}
						],
						expr: macro
						{
							// ADD NULL SAFETY LATER
							this.frames = psych.backend.Paths.getSparrowAtlas(path, library);
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "	
				*
				*	LoadFrames but goes through Paths for Convenience
				*",
				name: "loadMultiAtlas",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: "path", type: (macro :Array<String>)},
							{name: "library", type: (macro :String), opt: true}
						],
						expr: macro
						{
							// ADD NULL SAFETY LATER
							this.frames = psych.backend.Paths.getMultiAtlas(path, library);
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "	
				*
				*	loadGraphic but goes through Paths for Convenience
				*",
				name: "loadTex",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: "path", type: (macro :String)},
							{name: "library", type: (macro :String), opt: true}
						],
						expr: macro
						{
							this.loadGraphic(psych.backend.Paths.image(path, library));
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		fields.push(
			{
				doc: "	
					*
					*	loadGraphic but goes through Paths for Convenience
					*",
				name: "loadFromSheet",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FFun(
					{
						args: [
							{name: "path", type: (macro :String)},
							{name: "anim", type: (macro :String)},
							{name: "fps", type: (macro :Int), value: macro $v{24}},
							{name: 'loops', type: (macro :Bool), value: macro $v{true}}
						],
						expr: macro
						{
							this.loadFunkinSparrow(path);
							this.animation.addByPrefix(anim, anim, fps, loops);
							this.animation.play(anim);
							if (this.animation.curAnim == null || this.animation.curAnim.numFrames == 1)
							{
								this.active = false;
							}
							
							return this;
						}
					}),
				pos: Context.currentPos(),
			});
			
		return fields;
	}
	
	public static macro function buildFlxBasic():Array<haxe.macro.Expr.Field>
	{
		var fields:Array<haxe.macro.Expr.Field> = haxe.macro.Context.getBuildFields();
		
		fields.push(
			{
				name: "zIndex",
				access: [haxe.macro.Expr.Access.APublic],
				kind: FVar(macro :Int, macro $v{0}),
				pos: Context.currentPos(),
			});
			
		return fields;
	}
}
#end
