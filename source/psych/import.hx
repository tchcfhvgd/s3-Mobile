#if !macro
// Discord API
#if DISCORD_ALLOWED
import psych.backend.DiscordClient;
#end

// Psych
#if LUA_ALLOWED
import llua.*;

import llua.Lua;
#end

#if ACHIEVEMENTS_ALLOWED
import psych.backend.Achievements;
#end

#if sys
import sys.*;

import sys.io.*;
#elseif js
import js.html.*;
#end

#if VIDEOS_ALLOWED
import hxvlc.flixel.*;
#end

import psych.backend.Paths;
import psych.backend.Controls;
import psych.backend.CoolUtil;
import psych.backend.MusicBeatState;
import psych.backend.MusicBeatSubstate;
import psych.backend.CustomFadeTransition;
import psych.backend.ClientPrefs;
import psych.backend.Conductor;
import psych.backend.BaseStage;
import psych.backend.Difficulty;
import psych.backend.Mods;
import psych.objects.Alphabet;
import psych.objects.BGSprite;
import psych.states.PlayState;
import psych.states.LoadingState;

#if flxanimate
import flxanimate.*;

import psych.flxanimate.PsychFlxAnimate as FlxAnimate;
#end

// Flixel
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;
#end
