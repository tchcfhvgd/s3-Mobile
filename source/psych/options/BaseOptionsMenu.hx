package psych.options;

import psych.objects.GenerationsText;
import psych.objects.AttachedGenerationsText;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

import psych.objects.CheckboxThingie;
import psych.objects.AttachedText;
import psych.options.Option;
import psych.backend.InputFormatter;

class BaseOptionsMenu extends MusicBeatSubstate
{
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;
	
	private var grpOptions:FlxTypedGroup<OptionsText>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedGenerationsText>;
	
	private var descBox:FlxSprite;
	private var descText:FlxText;
	
	public var title:String;
	public var rpcTitle:String;
	
	public var bg:FlxSprite;
	
	public function new()
	{
		super();
		
		if (title == null) title = 'Options';
		if (rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(rpcTitle, null);
		#end
		
		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<OptionsText>();
		add(grpOptions);
		
		grpTexts = new FlxTypedGroup<AttachedGenerationsText>();
		add(grpTexts);
		
		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);
		
		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.8;
		add(descBox);
		
		var titleText:GenerationsText = new GenerationsText(0, 13, 0, title, 36);
		titleText.screenCenter(X);
		add(titleText);
		
		descText = new FlxText(50, 600, 1180, "", 28);
		descText.setFormat(Paths.font("FOT-NewRodin Pro DB.otf"), 28, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		
		add(descText);
		
		for (i in 0...optionsArray.length)
		{
			var optionText:OptionsText = new OptionsText(50, 260, 0, optionsArray[i].name, 48);
			optionText.targetY = i;
			grpOptions.add(optionText);
			
			if (optionsArray[i].type == 'bool')
			{
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, Std.string(optionsArray[i].getValue()) == 'true');
				checkbox.offsetX = optionText.width + 10;
				checkbox.offsetY = -10;
				
				checkbox.sprTracker = optionText;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else
			{
				// optionText.xAdd -= 80;
				var valueText:AttachedGenerationsText = new AttachedGenerationsText(0, 0, 0, '' + optionsArray[i].getValue(), 48);
				valueText.offsetX = optionText.width + 10;
				valueText.sprTracker = optionText;
				// valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].child = valueText;
			}
			// optionText.snapToPosition(); //Don't ignore me when i ask for not making a fucking pull request to uncomment this line ok
			updateTextFrom(optionsArray[i]);
		}
		
		changeSelection();
		reloadCheckboxes();
		
		addTouchPad("LEFT_FULL", "A_B_C");
	}
	
	public function addOption(option:Option)
	{
		if (optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
		return option;
	}
	
	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
	
	var bindingKey:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingText:Alphabet;
	var bindingText2:Alphabet;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (bindingKey)
		{
			bindingKeyUpdate(elapsed);
			return;
		}
		
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}
		
		if (controls.BACK)
		{
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
		
		if (nextAccept <= 0)
		{
			if (curOption.type == 'bool')
			{
				if (controls.ACCEPT)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			}
			else
			{
				if (curOption.type == 'keybind')
				{
					if (controls.ACCEPT)
					{
						bindingBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
						bindingBlack.scale.set(FlxG.width, FlxG.height);
						bindingBlack.updateHitbox();
						bindingBlack.alpha = 0;
						FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
						add(bindingBlack);
						
						bindingText = new Alphabet(FlxG.width / 2, 160, "Rebinding " + curOption.name, false);
						bindingText.alignment = CENTERED;
						add(bindingText);
						
						bindingText2 = new Alphabet(FlxG.width / 2, 340, "Hold ESC to Cancel\nHold Backspace to Delete", true);
						bindingText2.alignment = CENTERED;
						add(bindingText2);
						
						bindingKey = true;
						holdingEsc = 0;
						ClientPrefs.toggleVolumeKeys(false);
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
				}
				else if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if (holdTime > 0.5 || pressed)
					{
						if (pressed)
						{
							var add:Dynamic = null;
							if (curOption.type != 'string') add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
							
							switch (curOption.type)
							{
								case 'int' | 'float' | 'percent':
									holdValue = curOption.getValue() + add;
									if (holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
									
									switch (curOption.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);
											
										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}
									
								case 'string':
									var num:Int = curOption.curOption; // lol
									if (controls.UI_LEFT_P) --num;
									else num++;
									
									if (num < 0) num = curOption.options.length - 1;
									else if (num >= curOption.options.length) num = 0;
									
									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); // lol
									// trace(curOption.options[num]);
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));
						}
						else if (curOption.type != 'string')
						{
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
							if (holdValue < curOption.minValue) holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;
							
							switch (curOption.type)
							{
								case 'int':
									curOption.setValue(Math.round(holdValue));
									
								case 'float' | 'percent':
									curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}
					
					if (curOption.type != 'string') holdTime += elapsed;
				}
				else if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
				{
					if (holdTime > 0.5) FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
			
			if (controls.RESET || touchPad.buttonC.justPressed)
			{
				var leOption:Option = optionsArray[curSelected];
				if (leOption.type != 'keybind')
				{
					leOption.setValue(leOption.defaultValue);
					if (leOption.type != 'bool')
					{
						if (leOption.type == 'string') leOption.curOption = leOption.options.indexOf(leOption.getValue());
						updateTextFrom(leOption);
					}
				}
				else
				{
					leOption.setValue(!Controls.instance.controllerMode ? leOption.defaultKeys.keyboard : leOption.defaultKeys.gamepad);
					updateBind(leOption);
				}
				leOption.change();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}
		
		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
	}
	
	function bindingKeyUpdate(elapsed:Float)
	{
		if (touchPad.buttonB.pressed || FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
		{
			holdingEsc += elapsed;
			if (holdingEsc > 0.5)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else if (touchPad.buttonC.pressed || FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
		{
			holdingEsc += elapsed;
			if (holdingEsc > 0.5)
			{
				if (!controls.controllerMode) curOption.keys.keyboard = NONE;
				else curOption.keys.gamepad = NONE;
				updateBind(!controls.controllerMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
				FlxG.sound.play(Paths.sound('cancelMenu'));
				closeBinding();
			}
		}
		else
		{
			holdingEsc = 0;
			var changed:Bool = false;
			if (!controls.controllerMode)
			{
				if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
				{
					var keyPressed:FlxKey = cast(FlxG.keys.firstJustPressed(), FlxKey);
					var keyReleased:FlxKey = cast(FlxG.keys.firstJustReleased(), FlxKey);
					
					if (keyPressed != NONE && keyPressed != ESCAPE && keyPressed != BACKSPACE)
					{
						changed = true;
						curOption.keys.keyboard = keyPressed;
					}
					else if (keyReleased != NONE && (keyReleased == ESCAPE || keyReleased == BACKSPACE))
					{
						changed = true;
						curOption.keys.keyboard = keyReleased;
					}
				}
			}
			else if (FlxG.gamepads.anyJustPressed(ANY)
				|| FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)
				|| FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)
				|| FlxG.gamepads.anyJustReleased(ANY))
			{
				var keyPressed:FlxGamepadInputID = NONE;
				var keyReleased:FlxGamepadInputID = NONE;
				if (FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)) keyPressed = LEFT_TRIGGER; // it wasnt working for some reason
				else if (FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)) keyPressed = RIGHT_TRIGGER; // it wasnt working for some reason
				else
				{
					for (i in 0...FlxG.gamepads.numActiveGamepads)
					{
						var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
						if (gamepad != null)
						{
							keyPressed = gamepad.firstJustPressedID();
							keyReleased = gamepad.firstJustReleasedID();
							if (keyPressed != NONE || keyReleased != NONE) break;
						}
					}
				}
				
				if (keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
				{
					changed = true;
					curOption.keys.gamepad = keyPressed;
				}
				else if (keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
				{
					changed = true;
					curOption.keys.gamepad = keyReleased;
				}
			}
			
			if (changed)
			{
				var key:String = null;
				if (!controls.controllerMode)
				{
					if (curOption.keys.keyboard == null) curOption.keys.keyboard = 'NONE';
					curOption.setValue(curOption.keys.keyboard);
					key = InputFormatter.getKeyName(FlxKey.fromString(curOption.keys.keyboard));
				}
				else
				{
					if (curOption.keys.gamepad == null) curOption.keys.gamepad = 'NONE';
					curOption.setValue(curOption.keys.gamepad);
					key = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(curOption.keys.gamepad));
				}
				updateBind(key);
				FlxG.sound.play(Paths.sound('confirmMenu'));
				closeBinding();
			}
		}
	}
	
	final MAX_KEYBIND_WIDTH = 320;
	
	function updateBind(?text:String = null, ?option:Option = null)
	{
		if (option == null) option = curOption;
		if (text == null)
		{
			text = option.getValue();
			if (text == null) text = 'NONE';
			
			if (!controls.controllerMode) text = InputFormatter.getKeyName(FlxKey.fromString(text));
			else text = InputFormatter.getGamepadName(FlxGamepadInputID.fromString(text));
		}
		
		var bind:AttachedGenerationsText = cast option.child;
		var attach:AttachedGenerationsText = new AttachedGenerationsText(0, 0, 0, text, 48);
		attach.offsetX = bind.offsetX;
		attach.sprTracker = bind.sprTracker;
		// attach.copyAlpha = true;
		attach.ID = bind.ID;
		// playstationCheck(attach);
		// attach.scaleX = Math.min(1, MAX_KEYBIND_WIDTH / attach.width);
		attach.x = bind.x;
		attach.y = bind.y;
		
		option.child = attach;
		grpTexts.insert(grpTexts.members.indexOf(bind), attach);
		grpTexts.remove(bind);
		bind.destroy();
	}
	
	// function playstationCheck(alpha:Alphabet)
	// {
	// 	if (!controls.controllerMode) return;
	// 	var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
	// 	var model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
	// 	var letter = alpha.letters[0];
	// 	if (model == PS4)
	// 	{
	// 		switch (alpha.text)
	// 		{
	// 			case '[', ']': // Square and Triangle respectively
	// 				letter.image = 'alphabet_playstation';
	// 				letter.updateHitbox();
	// 				letter.offset.x += 4;
	// 				letter.offset.y -= 5;
	// 		}
	// 	}
	// }
	
	function closeBinding()
	{
		bindingKey = false;
		bindingBlack.destroy();
		remove(bindingBlack);
		
		bindingText.destroy();
		remove(bindingText);
		
		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.toggleVolumeKeys(true);
	}
	
	function updateTextFrom(option:Option)
	{
		if (option.type == 'keybind')
		{
			updateBind(option);
			return;
		}
		
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', Std.string(val)).replace('%d', Std.string(def));
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, optionsArray.length - 1);
		
		descText.text = optionsArray[curSelected].description;
		descText.screenCenter(Y);
		descText.y += 270;
		
		for (k => item in grpOptions.members)
		{
			item.targetY = k - curSelected;
			
			item.color = item.targetY == 0 ? FlxColor.YELLOW : FlxColor.WHITE;
		}
		
		for (k => i in grpTexts)
		{
			i.color = i.ID == curSelected ? FlxColor.YELLOW : FlxColor.WHITE;
		}
		
		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
		
		curOption = optionsArray[curSelected]; // shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	
	function reloadCheckboxes() for (checkbox in checkboxGroup)
		checkbox.daValue = Std.string(optionsArray[checkbox.ID].getValue()) == 'true'; // Do not take off the Std.string() from this, it will break a thing in Mod Settings Menu
}

class OptionsText extends GenerationsText
{
	public var distancePerItem:FlxPoint = new FlxPoint(20, 120);
	public var startPosition:FlxPoint = new FlxPoint(0, 0); // for the calculations
	public var targetY:Int = 0;
	
	public var changeX:Bool = false;
	public var changeY:Bool = true;
	
	public function new(x:Float = 0, y:Float = 0, fw:Float = 0, text:String, size:Int = 24)
	{
		super(x, y, fw, text, size);
		startPosition.set(x, y);
	}
	
	override function update(elapsed:Float)
	{
		final lerpVal:Float = FlxMath.getElapsedLerp(0.3, elapsed);
		if (changeX) x = FlxMath.lerp(x, (targetY * distancePerItem.x) + startPosition.x, lerpVal);
		if (changeY) y = FlxMath.lerp(y, (targetY * 1.3 * distancePerItem.y) + startPosition.y, lerpVal);
		
		super.update(elapsed);
	}
	
	public function snapToPosition()
	{
		if (changeX) x = (targetY * distancePerItem.x) + startPosition.x;
		if (changeY) y = (targetY * 1.3 * distancePerItem.y) + startPosition.y;
	}
}
