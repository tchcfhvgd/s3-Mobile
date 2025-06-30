function onCreate()
{
	// startCallback = startCountdown;
	
	var scale = 1.2;
	
	var scale2 = 1.1;
	var bgX = -200;
	var bgY = -25;
	
	var spr = new FlxSprite(bgX, bgY - 250, Paths.image('stages/stardust-speedway/sky'));
	spr.scale.set(scale * scale2 * 1.2, scale * scale2 * 1.2);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.scrollFactor.set(0.4, 0.4);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(bgX + (885 * scale * scale2), bgY + (95 * scale * scale2)).loadFromSheet('stages/stardust-speedway/assets', 'eggman_statue', 24);
	spr.scale.set(scale * scale2, scale * scale2);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.scrollFactor.set(0.4, 0.4);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(bgX + (1005 * scale * scale2), bgY + (-204 * scale * scale2), Paths.image('stages/stardust-speedway/spotlight'));
	spr.scale.set(scale * scale2, scale * scale2);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.scrollFactor.set(0.4, 0.4);
	spr.origin.set(10, 486);
	spr.angle = -70;
	FlxTween.tween(spr, {angle: 20}, 3, {ease: FlxEase.sineInOut, type: 4});
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(bgX + ((1005 + 25) * scale * scale2) - spr.width, bgY + (-204 * scale * scale2), Paths.image('stages/stardust-speedway/spotlight'));
	spr.scale.set(scale * scale2, scale * scale2);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.scrollFactor.set(0.4, 0.4);
	spr.flipX = true;
	spr.origin.set(371, 486);
	spr.angle = 70;
	FlxTween.tween(spr, {angle: -20}, 3, {ease: FlxEase.sineInOut, type: 4});
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(bgX + (-69 * scale * scale2), bgY + ((224) * scale * scale2), Paths.image('stages/stardust-speedway/skyline'));
	spr.scale.set(scale * scale2, scale * scale2);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.scrollFactor.set(0.4, 0.4);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(bgX, bgY + ((1) * scale * scale2)).loadFromSheet('stages/stardust-speedway/assets', 'buildings', 24);
	spr.scale.set(scale * scale2, scale * scale2);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.scrollFactor.set(0.7, 0.7);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(1072 * scale * scale2, (150) * scale * scale2).loadFromSheet('stages/stardust-speedway/assets', 'back_platform', 24);
	spr.scale.set(scale * scale2, scale * scale2);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.scrollFactor.set(0.9, 0.9);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var ndY = -65;
	var spr = new FlxSprite(-200 + (-255 * scale), ndY + (-320 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'front_platform', 24);
	spr.scale.set(scale, scale);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.scrollFactor.set(0.9, 0.9);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(1058 * scale, ndY + (390 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'arrow_pipe', 24);
	spr.scale.set(scale, scale);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(-210, ndY + (465 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'stardustFloor', 24);
	spr.scale.set(scale, scale);
	spr.updateHitbox();
	addBehindGF(spr);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	setVar('stage', spr);
	
	var spr = new FlxSprite(175 * scale, (597 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'piston', 24);
	spr.scale.set(scale, scale);
	spr.updateHitbox();
	add(spr);
	spr.scrollFactor.set(1.4, 1);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(305 * scale, (676 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'ring_set', 24);
	spr.scale.set(scale, scale);
	spr.updateHitbox();
	add(spr);
	spr.scrollFactor.set(1.4, 1);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	var spr = new FlxSprite(971 * scale, (639 * scale)).loadFromSheet('stages/stardust-speedway/assets', 'horn', 24);
	spr.scale.set(scale, scale);
	spr.updateHitbox();
	add(spr);
	spr.scrollFactor.set(1.4, 1);
	spr.antialiasing = ClientPrefs.data.antialiasing;
	
	// dadGroup.visible = false;
}
