package psych.assets.shared.scripts;

import psych.psychlua.ModchartSprite;

import flixel.FlxSprite;

import psych.states.PlayState;

import flixel.text.FlxText;
import flixel.FlxG;

import psych.psychlua.LuaUtils;

var cachedPerfecto = Paths.getSparrowAtlas('jammin');

function onCreate()
{
	ratingsData[1].image = 'bad';
	ratingsData[2].image = 'bad';
	ratingsData[3].image = 'bad';
	
	return LuaUtils.Function_Continue;
}

function onPopUpScore(note, rating, combo)
{
	if (note.ratingMod == 0.67)
	{
		rating.frames = cachedPerfecto;
		rating.animation.addByPrefix('jammin', 'jammin', 24);
		rating.animation.play('jammin', true, false, -1);
		rating.updateHitbox();
		// rating.offset.y = -36;
	}
}
