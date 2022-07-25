#if sys
package;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.system.FlxSound;
import lime.app.Application;
#if windows
import Discord.DiscordClient;
#end
import openfl.display.BitmapData;
import openfl.utils.Assets;
import haxe.Exception;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
#if cpp
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class CachingState extends MusicBeatState
{
	public static var bitmapData:Map<String,FlxGraphic>;
	public static var bitmapData2:Map<String,FlxGraphic>;

	var images = [];
	var music = [];
	var inst = [];
	var voices = [];
	var sound = [];	
	var json = [];
	var xml = [];

	override function create()
	{
		//Paths.clearUnusedMemory();

		FlxG.mouse.visible = true;

		FlxG.worldBounds.set(0,0);

		bitmapData = new Map<String,FlxGraphic>();
		bitmapData2 = new Map<String,FlxGraphic>();

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('loadingScreen'));
		menuBG.screenCenter();
		add(menuBG);

		for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images")))
		{
			if (!i.endsWith(".png"))
				continue;
			images.push(i);
		}

		for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/images")))
		{
			if (!i.endsWith(".png"))
				continue;
			images.push(i);
		}

		sys.thread.Thread.create(() -> {
            preloadNotes();
        });

        sys.thread.Thread.create(() -> {
            preloadCharacters();
        });

		sys.thread.Thread.create(() -> {
			cache();
		});		

		super.create();
	}

	override function update(elapsed) 
	{
		super.update(elapsed);
	}

    function preloadNotes(){
        ImageCache.add("assets/shared/images" + "NOTE_assets.png");
		trace("Chached Notes");
    }

    function preloadCharacters(){
        ImageCache.add("assets/shared/images/characters" + ".png");
		trace("Chached Characters");
    }

	function cache()
	{
		FlxG.switchState(new TitleState());
	}

}
#end