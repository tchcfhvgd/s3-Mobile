package assets.shared.data.scrambled;

import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.group.FlxSpriteContainer;

// import flixel.group.FlxGroup;
import psych.backend.Paths;

var ringFrames = Paths.getSparrowAtlas('stages/ring');
var rings:FlxSpriteContainer;
var groundY = 700;

function onCreate()
{
	rings = new FlxSpriteContainer();
	
	insert(members.indexOf(boyfriendGroup) + 1, rings);
	setVar('ringHurt', hurt);
}

function hurt()
{
	var range = FlxG.random.int(3, 8);
	for (i in 0...range)
	{
		var ring = rings.recycle(Ring, () -> {
			var spr = new Ring(ringFrames);
			return spr;
		});
		
		ring.x = boyfriend.getGraphicMidpoint().x;
		ring.y = boyfriend.getGraphicMidpoint().y;
		
		ring.velocity.set(1400, 0);
		ring.acceleration.y = 1400 * 4;
		var ringPos = FlxMath.remapToRange(i, 0, range, 0, -180);
		setPointDegrees(ring.velocity, ringPos);
		ring.spawn();
		
		ring.groundY = groundY + (FlxG.random.int(-20, 20));
		
		rings.add(ring);
	}
	
	FlxG.sound.play(Paths.sound('ring hit sound effect'), 0.8);
}
