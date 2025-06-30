package psych.cutscenes;

import haxe.ds.ArraySort;

import flixel.system.FlxBGSprite;

import haxe.Json;

import openfl.utils.Assets;

import psych.cutscenes.DialogueBoxPsych.DialogueLine;
import psych.cutscenes.DialogueBoxPsych.DialogueFile;
import psych.objects.TypedAlphabet;
import psych.cutscenes.DialogueCharacter;

import openfl.media.Sound;

enum abstract CharEffect(String)
{
	var SHAKE;
}

typedef DialogueLineData =
{
	> DialogueLine,
	?charEffect:CharEffect
}

// TO DO: Clean code? Maybe? idk
// no dude to do rewrite everything
class DialogueBoxS3 extends FlxSpriteGroup
{
	public static var LEFT_CHAR_X:Float = 0;
	public static var RIGHT_CHAR_X:Float = -100;
	public static var DEFAULT_CHAR_Y:Float = 300;
	
	var scrollSpeed = 4000;
	
	var dialogueList:DialogueFile = null;
	
	public var finishThing:Null<Void->Void> = null;
	public var nextDialogueThing:Null<Void->Void> = null;
	public var skipDialogueThing:Null<Void->Void> = null;
	
	final bgFade:FlxSprite;
	final box:FlxSprite;
	final textInstance:FlxText;
	final voiceSound:FlxSound;
	
	var arrayCharacters:Array<Null<DialogueCharacter>> = [];
	
	var currentText:Int = 0;
	var offsetPos:Float = -600;
	
	var curCharacter:String = "";
	
	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;
	
	public function new(dialogueList:DialogueFile, ?song:String = null)
	{
		super();
		
		// precache sounds
		Paths.sound('dialogue');
		Paths.sound('dialogueClose');
		
		if (song != null && song != '')
		{
			FlxG.sound.playMusic(Paths.music(song), 0);
			FlxG.sound.music.fadeIn(2, 0, 1);
		}
		this.dialogueList = dialogueList;
		
		bgFade = new FlxBGSprite();
		bgFade.color = FlxColor.BLACK;
		bgFade.scrollFactor.set();
		bgFade.visible = true;
		bgFade.alpha = 0;
		add(bgFade);
		
		spawnCharacters();
		
		box = new FlxSprite().loadFromSheet('dialogue/textbox', 'textbox', 24, false);
		box.animation.pause();
		box.antialiasing = ClientPrefs.data.antialiasing;
		box.scrollFactor.set();
		box.visible = false;
		box.updateHitbox();
		add(box);
		box.screenCenter(X);
		
		textInstance = new FlxText(0, 60, 1000, 'WEENER', 48);
		textInstance.color = FlxColor.BLACK;
		textInstance.font = Paths.font('ms-pgothic-regular.ttf');
		add(textInstance);
		textInstance.x = box.x + 80;
		textInstance.visible = false;
		
		voiceSound = new FlxSound();
		FlxG.sound.list.add(voiceSound);
		
		FlxTimer.wait(1, startBox);
	}
	
	function spawnCharacters()
	{
		var charsMap:Map<String, Bool> = new Map<String, Bool>();
		for (i in 0...dialogueList.dialogue.length)
		{
			if (dialogueList.dialogue[i] != null)
			{
				var charToAdd:String = dialogueList.dialogue[i].portrait;
				if (!charsMap.exists(charToAdd) || !charsMap.get(charToAdd))
				{
					charsMap.set(charToAdd, true);
				}
			}
		}
		
		for (individualChar in charsMap.keys())
		{
			var x:Float = LEFT_CHAR_X;
			var y:Float = DEFAULT_CHAR_Y;
			
			var char:DialogueCharacter = new DialogueCharacter(x + offsetPos, y, individualChar);
			char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * char.jsonFile.scale));
			char.updateHitbox();
			char.scrollFactor.set();
			char.alpha = 0.00001;
			add(char);
			
			var saveY:Bool = false;
			switch (char.jsonFile.dialogue_pos)
			{
				case 'center':
					char.x = FlxG.width / 2;
					char.x -= char.width / 2;
					y = char.y;
					char.y = FlxG.height + 50;
					saveY = true;
				case 'right':
					x = FlxG.width - char.width + RIGHT_CHAR_X;
					char.x = x - offsetPos;
			}
			x += char.jsonFile.position[0];
			y += char.jsonFile.position[1];
			char.x += char.jsonFile.position[0];
			char.y += char.jsonFile.position[1];
			char.startingPos = (saveY ? y : x);
			arrayCharacters.push(char);
		}
	}
	
	var ignoreThisFrame:Bool = true; // First frame is reserved for loading dialogue images
	
	public var closeSound:String = 'dialogueClose';
	public var closeVolume:Float = 1;
	
	function tryAdvancingDialogue()
	{
		if (currentText >= dialogueList.dialogue.length)
		{
			dialogueEnded = true;
			
			box.animation.curAnim.curFrame = box.animation.curAnim.frames.length - 1;
			box.animation.curAnim.reverse();
			textInstance.visible = false;
			FlxG.sound.music.fadeOut(1, 0);
		}
		else
		{
			startNextDialog();
		}
		// FlxG.sound.play(Paths.sound(closeSound), closeVolume);
	}
	
	override function update(elapsed:Float)
	{
		if (ignoreThisFrame)
		{
			ignoreThisFrame = false;
			super.update(elapsed);
			return;
		}
		
		if (!dialogueEnded)
		{
			bgFade.alpha += 0.5 * elapsed;
			if (bgFade.alpha > 0.5) bgFade.alpha = 0.5;
			
			if (Controls.instance.ACCEPT)
			{
				tryAdvancingDialogue();
			}
			
			if (lastCharacter != -1 && arrayCharacters.length > 0)
			{
				for (i in 0...arrayCharacters.length)
				{
					var char = arrayCharacters[i];
					if (char != null)
					{
						if (i != lastCharacter)
						{
							switch (char.jsonFile.dialogue_pos)
							{
								case 'left':
									char.x -= scrollSpeed * elapsed;
									if (char.x < char.startingPos + offsetPos) char.x = char.startingPos + offsetPos;
								case 'center':
									char.y += scrollSpeed * elapsed;
									if (char.y > char.startingPos + FlxG.height) char.y = char.startingPos + FlxG.height;
								case 'right':
									char.x += scrollSpeed * elapsed;
									if (char.x > char.startingPos - offsetPos) char.x = char.startingPos - offsetPos;
							}
							char.alpha -= 3 * elapsed;
							if (char.alpha < 0.00001) char.alpha = 0.00001;
						}
						else
						{
							switch (char.jsonFile.dialogue_pos)
							{
								case 'left':
									char.x += scrollSpeed * elapsed;
									if (char.x > char.startingPos) char.x = char.startingPos;
								case 'center':
									char.y -= scrollSpeed * elapsed;
									if (char.y < char.startingPos) char.y = char.startingPos;
								case 'right':
									char.x -= scrollSpeed * elapsed;
									if (char.x < char.startingPos) char.x = char.startingPos;
							}
							char.alpha += 3 * elapsed;
							if (char.alpha > 1) char.alpha = 1;
						}
					}
				}
			}
		}
		else
		{ // Dialogue ending
			if (box.animation.curAnim.curFrame <= 0)
			{
				box.kill();
			}
			
			bgFade.alpha -= 0.5 * elapsed;
			if (bgFade.alpha <= 0)
			{
				bgFade.kill();
			}
			
			for (i in 0...arrayCharacters.length)
			{
				var leChar:Null<DialogueCharacter> = arrayCharacters[i];
				if (leChar != null)
				{
					switch (arrayCharacters[i].jsonFile.dialogue_pos)
					{
						case 'left':
							leChar.x -= scrollSpeed * elapsed;
						case 'center':
							leChar.y += scrollSpeed * elapsed;
						case 'right':
							leChar.x += scrollSpeed * elapsed;
					}
					leChar.alpha -= elapsed * 10;
				}
			}
			
			if (!box.alive && !bgFade.alive)
			{
				voiceSound.stop();
				voiceSound.destroy();
				finishThing();
				return;
			}
		}
		super.update(elapsed);
	}
	
	function startBox()
	{
		box.visible = true;
		box.animation.resume();
		
		final curDialogue:Null<DialogueLine> = dialogueList.dialogue[0];
		
		if (curDialogue != null)
		{
			for (i in 0...arrayCharacters.length)
			{
				if (arrayCharacters[i].curCharacter == curDialogue.portrait)
				{
					box.flipX = arrayCharacters[i].jsonFile.dialogue_pos != 'left';
					break;
				}
			}
		}
		
		FlxTimer.wait(1, startNextDialog);
	}
	
	var lastCharacter:Int = -1;
	
	function startNextDialog():Void
	{
		var curDialogue:Null<DialogueLine> = null;
		do
		{
			curDialogue = dialogueList.dialogue[currentText];
		}
		while (curDialogue == null);
		
		if (curDialogue.text == null || curDialogue.text.length < 1) curDialogue.text = ' ';
		
		var character:Int = 0;
		
		for (i in 0...arrayCharacters.length)
		{
			if (arrayCharacters[i].curCharacter == curDialogue.portrait)
			{
				character = i;
				break;
			}
		}
		
		final lePosition:String = arrayCharacters[character].jsonFile.dialogue_pos;
		
		if (character != lastCharacter)
		{
			box.flipX = (lePosition != 'left');
		}
		lastCharacter = character;
		
		if (curDialogue.text != textInstance.text)
		{
			textInstance.visible = true;
			textInstance.text = curDialogue.text;
			FlxTween.completeTweensOf(textInstance, ['y']);
			
			final y = textInstance.y;
			textInstance.y -= 5;
			FlxTween.tween(textInstance, {y: y}, 0.1);
		}
		
		if (curDialogue.sound != null && curDialogue.sound.length != 0)
		{
			if (voiceSound.playing)
			{
				voiceSound.stop();
			}
			voiceSound.loadEmbedded(Paths.sound('cutscenes/${curDialogue.sound}'));
			FlxTimer.wait(0, () -> {
				voiceSound.play(true);
			});
			voiceSound.onComplete = tryAdvancingDialogue;
		}
		
		final char:Null<DialogueCharacter> = arrayCharacters[character];
		if (char != null)
		{
			char.playAnim(curDialogue.expression);
		}
		currentText++;
		
		if (nextDialogueThing != null)
		{
			nextDialogueThing();
		}
	}
	
	public static function parseDialogue(path:String):DialogueFile
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(path))
		{
			return cast Json.parse(File.getContent(path));
		}
		#end
		return cast Json.parse(Assets.getText(path));
	}
}
