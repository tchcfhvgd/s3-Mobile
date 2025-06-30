package psych.states;

import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.group.FlxContainer.FlxTypedContainer;

import psych.psychlua.ModchartSprite;

using psych.states.S3Credits;

typedef CreditData =
{
	user:String,
	?desc:String,
	?link:String
}

class S3Credits extends MusicBeatState
{
	var allowedControls:Bool = true;
	
	var backButton:BackButton;
	
	var curSelected:Int = 0;
	
	public function new(role:String)
	{
		super();
		
		build(role);
	}
	
	var buttons:FlxTypedContainer<Credit>;
	var credits:Array<CreditData> = [];
	
	var role:String;
	
	var arrow:Null<FlxSprite> = null;
	
	function build(role:String)
	{
		switch (role)
		{
			case 'music':
				credits = [
					{
						user: 'Veronyx',
						desc: "Worked on\nScrambled,\nMetallic Medley,\nSurf Caster,\nMania,\nLuminous,\nBazaar,\nCutscene Music",
						link: "https://x.com/veronyxlol",
					},
					{
						user: "HUGENATE",
						desc: "Worked on\nAct 0,\nHard-Headed,\nContinue?,\nHammered",
						link: "https://x.com/HUGENATEMUSIC",
					},
					{
						user: "RiverMusic",
						desc: "Worked on\nSeven Symphonies",
						link: "https://x.com/rivermusic_"
					},
					{
						user: "Jacaris",
						desc: "Worked on\nScrambled",
						link: "https://x.com/JaceyAmaris",
					},
					{
						user: "Luc",
						desc: "Worked on\nStardust Shutdown",
						link: "https://x.com/LIQDrummer"
					},
					{
						user: "Speedz",
						desc: "Worked on\nDynamite",
						link: "https://x.com/YahBoiSpeedz"
					}
					
				];
			case 'va':
				credits = [
					{
						user: 'Jacaris',
						desc: "Voice of Sonic & AOSTH Sonic",
						link: "https://x.com/JaceyAmaris",
					},
					{
						user: "ShibiPaffu",
						desc: "Voice of Amy",
						link: "https://x.com/ShibiPaffu"
					},
					{
						user: "MegaBlade",
						desc: "Voice of Eggman",
						link: "https://x.com/MegaBlade"
					},
					{
						user: "BanBuds",
						desc: "Eggman (Chromatic)",
						link: "https://x.com/Banbuds"
					},
					{
						user: "Shinseinaken",
						desc: "Metal Sonic (Chromatic)",
						link: "https://bsky.app/profile/shinseinaken.bsky.social"
					},
					{
						user: "Speedz",
						desc: "Bean (Chromatic)",
						link: "https://x.com/YahBoiSpeedz"
					},
					{
						user: "Charmhung",
						desc: "Voice of Big"
					},
					{
						user: "TicTonic1996",
						desc: "Grounder (Chromatic)",
						link: "https://x.com/TicTonic96_VA"
					},
					{
						user: "SuperA",
						desc: "Scratch (Chromatic)",
						link: "https://steamcommunity.com/profiles/76561199248505909"
					}
				];
			case 'chart':
				credits = [
					{
						user: 'HUGENATE',
						desc: "Charted Act 0,\nScrambled,\nMetallic Medley,\nSurf Caster,\nHard-Headed",
						link: "https://x.com/HUGENATEMUSIC",
					},
					{
						user: "thisnotgeorgie",
						desc: "Charted Stardust Shutdown, Dynamite",
						link: "https://x.com/thisnotgeorgie"
					},
					{
						user: "Veronyx",
						desc: "Helped with normal difficulty charts",
						link: "https://x.com/veronyxlol",
					}
				];
				
			case 'artist':
				credits = [
					{
						user: 'KOLSAN',
						desc: "Main Artist/Director and Writer",
						link: "https://x.com/KOLSANART"
					},
					{
						user: 'ManiacXVII',
						desc: "Icon Artist",
						link: "https://x.com/ManiacXVII"
					},
					{
						user: 'JonSpeedArts',
						desc: "Intro Card Artist",
						link: "https://x.com/Jon_SpeedArts"
					},
					{
						user: 'meatku',
						desc: "Funkin` Hills background",
						link: "https://x.com/meatku_"
					},
					{
						user: 'howdoyourock',
						desc: "Menu UI",
						link: "https://x.com/howdoyourock"
					},
					{
						user: "Cherribun",
						desc: "3D Modeling",
						link: "https://x.com/casinobunbun"
					},
					{
						user: "thisnotgeorgie",
						desc: "Portrait Artist,\nCutscene animation",
						link: "https://x.com/thisnotgeorgie"
					},
					{
						user: "Yabo",
						desc: "Additional Animation",
						link: "https://x.com/heyimyabo"
					},
					{
						user: "ColdRamen_18",
						desc: "Additional Animation",
						link: "https://x.com/ColdRamen_18"
					},
					{
						user: "Yoshi Cape",
						desc: "Credits UI",
						link: "https://x.com/yoshicape"
					},
					{
						user: "HUGENATE",
						desc: "Credits Icons",
						link: "https://x.com/HUGENATEMUSIC",
					}
				];
			case 'code':
				credits = [
					{
						user: 'data5',
						desc: "Main coder",
						link: "https://x.com/_data5"
					},
					{
						user: 'Grave',
						desc: "S3 HERO",
						link: "https://x.com/infinitydeaft"
					},
					{
						user: "infry",
						desc: "Helped with camera events",
						link: "https://x.com/Infry20"
					}
				];
				
				if (FlxG.random.bool(0.5))
				{
					credits.push(
						{
							user: "gluttonous beast",
							desc: "IGNORE"
						});
				}
				
				if (FlxG.random.bool(0.5))
				{
					credits.push(
						{
							user: "noxhy",
							desc: "IGNORE"
						});
				}
				
				if (FlxG.random.bool(0.5))
				{
					credits.push(
						{
							user: "vladosikos17",
							desc: "IGNORE"
						});
				}
		}
		this.role = role;
	}
	
	var bigBox:FlxSprite;
	
	override function create()
	{
		super.create();
		
		persistentUpdate = true;
		
		var bg = new ModchartSprite(Paths.image('menu/credits/bg')).to720();
		add(bg);
		
		bigBox = cast new ModchartSprite(Paths.image('menu/credits/bgbox')).to720().screenCenter();
		add(bigBox);
		
		buttons = new FlxTypedContainer();
		add(buttons);
		
		backButton = cast new BackButton(Paths.image('menu/credits/back')).to720();
		add(backButton);
		backButton.y = FlxG.height;
		backButton.x = -backButton.width;
		FlxTween.tween(backButton, {x: 0, y: FlxG.height - backButton.height}, 0.4, {ease: FlxEase.cubeOut, startDelay: 0.3});
		
		var border:ModchartSprite = cast new ModchartSprite(Paths.image('menu/credits/border')).screenCenter();
		add(border);
		FlxTween.tween(border, {'scale.x': _1080_720, 'scale.y': _1080_720}, 0.4, {ease: FlxEase.expoOut});
		
		var _refWidth = (Paths.image('menu/credits/creditbox').width + Paths.image('menu/credits/credit').width) * _1080_720;
		var _refHeight = Paths.image('menu/credits/creditbox').height * _1080_720;
		
		for (k => i in credits)
		{
			final idx = k > 8 ? k - 9 : k;
			
			final newX = FlxMath.remapToRange(idx % 3, 0, 2, bigBox.x + (75 * _1080_720), bigBox.x + bigBox.width - (75 * _1080_720) - _refWidth) + 35;
			
			final newY = FlxMath.remapToRange(Math.floor(idx / 3), 0, 2, bigBox.y + (36 * _1080_720), bigBox.y + bigBox.height - (36 * _1080_720) - _refHeight)
				- 5;
				
			var cr = new Credit(newX, newY, i);
			buttons.add(cr);
		}
		
		spawnText(role);
		
		arrow = new FlxSprite(0, bigBox.y + bigBox.height - 15, Paths.image('menu/credits/arrow'));
		add(arrow);
		arrow.setGraphicSize(0, 50);
		arrow.updateHitbox();
		
		arrow.x = bigBox.x + bigBox.width - arrow.width;
		
		arrow.visible = credits.length > 9;
		
		changeSel();
	}
	
	function spawnText(txt:String)
	{
		var blue = new ModchartSprite(Paths.image('menu/credits/blue')).to720();
		blue.x = FlxG.width;
		add(blue);
		
		var red = new ModchartSprite(Paths.image('menu/credits/red')).to720();
		red.x = FlxG.width;
		add(red);
		
		var black = new ModchartSprite(Paths.image('menu/credits/creditrole')).to720();
		black.x = FlxG.width;
		add(black);
		
		var _t = new FlxText(FlxG.width, 0, black.width, CoolUtil.capitalize(txt), 36);
		_t.setFormat(Paths.font('SeuratPro.otf'), 36, FlxColor.WHITE, CENTER);
		add(_t);
		
		_t.y = (black.height - _t.height) / 2;
		
		for (k => i in [blue, red, black, _t])
		{
			FlxTween.tween(i, {x: FlxG.width - i.width}, 0.2, {startDelay: k * 0.05, ease: FlxEase.sineOut});
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (allowedControls)
		{
			if (controls.ACCEPT)
			{
				if (buttons.members[curSelected].user.link != null)
				{
					var s = FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxG.sound.list.remove(s);
					s.autoDestroy = true;
					CoolUtil.browserLoad(buttons.members[curSelected].user.link);
				}
			}
			
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				
				FlxG.switchState(() -> new psych.states.S3CreditsMain());
			}
			if (controls.UI_RIGHT_P || controls.UI_LEFT_P) changeSel(controls.UI_RIGHT_P ? 1 : -1);
			if (controls.UI_DOWN_P || controls.UI_UP_P)
			{
				// var y = buttons.members[curSelected].y;
				// var diff = buttons.members.filter(button -> button.y == y);
				changeSel(controls.UI_DOWN_P ? 3 : -3);
			}
		}
		
		var arrowFlip = false;
		for (k => i in buttons.members)
		{
			final isPage2 = k > 8 && curSelected > 8;
			i.visible = (isPage2 || k < 9 && curSelected < 9); // this is the stupidest work around but whatevr
			if (isPage2 && !arrowFlip) arrowFlip = true;
		}
		
		sine += elapsed;
		if (arrow != null)
		{
			arrow.flipX = arrowFlip;
			
			if (!arrowFlip) arrow.x = bigBox.x + bigBox.width - arrow.width;
			else arrow.x = bigBox.x + 65;
			
			arrow.x += Math.cos(sine * 2) / 0.25;
		}
	}
	
	var sine = 0.0;
	
	function changeSel(diff:Int = 0)
	{
		if (diff != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
		buttons.members[curSelected].selected = false;
		
		curSelected = FlxMath.wrap(curSelected + diff, 0, buttons.length - 1);
		buttons.members[curSelected].selected = true;
	}
	
	public static final _1080_720:Float = 0.667;
	
	public static inline function to720(spr:ModchartSprite, scalePos:Bool = false)
	{
		spr.scale.scale(_1080_720);
		spr.updateHitbox();
		if (scalePos)
		{
			spr.x *= _1080_720;
			spr.y *= _1080_720;
		}
		return spr;
	}
}

private class BackButton extends ModchartSprite
{
	public var selected(default, set):Bool = false;
	
	function set_selected(value:Bool):Bool
	{
		if (selected == value) return value;
		FlxTween.cancelTweensOf(this, ['scale.x', 'scale.y']);
		
		final scale = defScale * (value ? 1.05 : 1);
		FlxTween.tween(this.scale, {x: scale, y: scale}, 0.3, {ease: FlxEase.elasticOut});
		
		return (selected = value);
	}
	
	var defScale:Float = 0.667;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

private class Credit extends ModchartSprite
{
	public final user:CreditData;
	
	final potrait:FlxSprite;
	final name:FlxText;
	
	final desc:FlxSprite;
	
	public var selected(default, set):Bool = false;
	
	var descX:Float = 0;
	
	var descText:FlxText;
	
	function set_selected(value:Bool):Bool
	{
		if (selected == value) return value;
		
		descX = value ? width - (29 * S3Credits._1080_720) : 6;
		
		return (selected = value);
	}
	
	public function new(x:Float = 0, y:Float = 0, user:CreditData)
	{
		super(x, y, Paths.image('menu/credits/creditbox'));
		this.to720(false);
		
		potrait = new ModchartSprite(Paths.image('menu/credits/users/${user.user}'));
		potrait.setGraphicSize(0, 214 * S3Credits._1080_720);
		potrait.updateHitbox();
		
		name = new FlxText(0, 0, width, user.user, 18);
		name.setFormat(Paths.font('SeuratPro.otf'), 18, FlxColor.BLACK, CENTER, OUTLINE, FlxColor.WHITE);
		
		desc = new ModchartSprite(Paths.image('menu/credits/credit')).to720();
		
		descText = new FlxText(0, 0, 0, '', 14);
		descText.font = Paths.font('punk-mono.ttf');
		
		this.user = user;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		potrait.x = x + (width - potrait.width) / 2;
		potrait.y = y + ((height - (48 * S3Credits._1080_720)) - potrait.height) / 2;
		
		name.x = x;
		name.y = (y + (231 * S3Credits._1080_720)) + ((51 * S3Credits._1080_720) - name.height) / 2;
		
		desc.x = x + (width - (29 * S3Credits._1080_720));
		
		var rect = desc.clipRect ?? new FlxRect(0, 0, 0);
		rect.height = desc.frameHeight;
		
		rect.width = FlxMath.lerp(rect.width, selected ? desc.frameWidth : 0, FlxMath.getElapsedLerp(0.4, elapsed));
		desc.clipRect = rect;
		
		desc.y = y + (4 * S3Credits._1080_720);
		
		descText.x = desc.x + 25;
		descText.y = desc.y + 10;
		descText.fieldWidth = desc.width - 65;
		descText.fieldHeight = desc.height;
		descText.text = user.desc ?? 'lol';
		
		descText.clipRect = desc.clipRect;
	}
	
	override function draw()
	{
		desc.draw();
		super.draw();
		potrait.draw();
		name.draw();
		
		descText.draw();
	}
	
	override function destroy()
	{
		FlxDestroyUtil.destroy(potrait);
		FlxDestroyUtil.destroy(name);
		FlxDestroyUtil.destroy(desc);
		FlxDestroyUtil.destroy(descText);
		
		super.destroy();
	}
}
