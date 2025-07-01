package psych.substates;

import psych.objects.GenerationsText;
import psych.backend.WeekData;
import psych.backend.Highscore;

import flixel.FlxSubState;

import psych.objects.HealthIcon;

class ResetScoreSubState extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var alphabetArray:Array<GenerationsText> = [];
	var icon:HealthIcon;
	var onYes:Bool = false;
	var yesText:GenerationsText;
	var noText:GenerationsText;
	
	var song:String;
	var difficulty:Int;
	var week:Int;
	
	// Week -1 = Freeplay
	public function new(song:String, difficulty:Int, character:String, week:Int = -1)
	{
		this.song = song;
		this.difficulty = difficulty;
		this.week = week;
		
		super();
		
		var name:String = song;
		if (week > -1)
		{
			name = WeekData.weeksLoaded.get(WeekData.weeksList[week]).weekName;
		}
		name += ' (' + Difficulty.getString(difficulty) + ')?';
		
		bg = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
		
		var tooLong:Float = (name.length > 18) ? 0.8 : 1; // Fucking Winter Horrorland
		var text:GenerationsText = new GenerationsText(0, 180, FlxG.width, "Reset the score of", 48);
		text.alignment = CENTER;
		
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);
		
		var text:GenerationsText = new GenerationsText(0, text.y + 90, FlxG.width, name, 48);
		text.alignment = CENTER;
		// if (week == -1) text.x += 60 * tooLong;
		alphabetArray.push(text);
		
		text.alpha = 0;
		add(text);
		if (week == -1)
		{
			icon = new HealthIcon(character);
			icon.setGraphicSize(Std.int(icon.width * tooLong));
			icon.updateHitbox();
			icon.y = text.y + 50;
			icon.screenCenter(X);
			// icon.setPosition(text.x - icon.width + (10 * tooLong), text.y - 30);
			icon.alpha = 0;
			add(icon);
		}
		
		yesText = new GenerationsText(0, text.y + 150, 0, 'Yes', 48);
		yesText.screenCenter(X);
		yesText.x -= 200;
		add(yesText);
		noText = new GenerationsText(0, text.y + 150, 0, 'No', 48);
		noText.screenCenter(X);
		noText.x += 200;
		add(noText);
		updateOptions();
		
		addTouchPad("LEFT_RIGHT", "A_B");
		addTouchPadCamera();
	}
	
	override function update(elapsed:Float)
	{
		bg.alpha += elapsed * 1.5;
		if (bg.alpha > 0.6) bg.alpha = 0.6;
		
		for (i in 0...alphabetArray.length)
		{
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}
		if (week == -1) icon.alpha += elapsed * 2.5;
		
		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			onYes = !onYes;
			updateOptions();
		}
		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
		}
		else if (controls.ACCEPT)
		{
			if (onYes)
			{
				if (week == -1)
				{
					Highscore.resetSong(song, difficulty);
				}
				else
				{
					Highscore.resetWeek(WeekData.weeksList[week], difficulty);
				}
			}
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
		}
		if (touchPad == null){ //sometimes it dosent add the tpad, hopefully this fixes it
		addTouchPad("LEFT_RIGHT", "A_B");
		addTouchPadCamera();
		}
		super.update(elapsed);
	}
	
	function updateOptions()
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 0 : 1;
		
		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
		if (week == -1)
		{
			if (icon != null)
			{
				icon.setState(onYes ? 50 : 0);
			}
		}
	}
}
