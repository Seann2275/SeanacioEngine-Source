package;

import editors.WeekEditorState.WeekEditorFreeplayState;
import flixel.util.FlxSpriteUtil;
import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import lime.app.Application;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSave;
import animateatlas.AtlasFrameMaker;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import Conductor.Rating;
#if sys
import sys.FileSystem;
#end

#if VIDEOS_ALLOWED
import vlc.MP4Handler;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
	public static var camFollowDadNote = 40;
	public static var camFollowBFNote = 40; // idk why i made literally same variable	

	public static var ratingStuff:Array<Dynamic> = [
		['BOZO!', 0.2], //0% to 19%
		['Get Good', 0.4], //20% to 39%
		['Lame', 0.5], //40% to 49%
		['Bruh', 0.6], //50% to 59%
		['Ass', 0.69], //60% to 68%
		['Really Bad', 0.7], //69%
		['Bad', 0.8], //70% to 79%
		['Nice', 0.9], //80% to 89%
		['Sick!', 1], //90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 3000;

	public var vocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;

	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZooming2:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var ratingsData:Array<Rating> = [];
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

    //Too Many Modcharts   life sucks.. 
	private var camSwing:Bool = false;	
	private var camSwing2:Bool = false;	
	private var floatRot:Bool = false;		
	private var spinSwing:Bool = false;	
	private var windowChill:Bool = false;
	private var windowChill2:Bool = false;
	private var trailShit:Bool = false;
	private var cameraCenter:Bool = false;
	private var swapSwap:Bool = false;
	private var idkWatocallthisathisPoint:Bool = false;
	private var timeThing:Bool = false;
	private var floatRotSpinSwing:Bool = false;	
	private var spfinswlnef:Bool = false;
	private var spfinswlnef2:Bool = false;
	private var arrowSpin:Bool = false;
	private var floatNote:Bool = false;	
	private var floatNoteSlow:Bool = false;		
	private var funny:Bool = false;	
	private var wiggleNote:Bool = false;	
	private var shakeCam:Bool = false;	
	private var camGLITCH:Bool = false;	
	private var playerStrumsY:Bool = false;
	var windowX:Float = Lib.application.window.x;
	var windowY:Float = Lib.application.window.y;
	var windowX2:Float = Lib.application.window.x;
	var windowY2:Float = Lib.application.window.y;
	var Cmd2:Float = 0;		

	public var engineWatermark:FlxText;			

	//Gameplay settings
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var comboBreaks:Int = 0;
	public var scoreTxt:FlxText;	
	public var ratingCounter1:FlxText;	
	public var ratingCounter2:FlxText;
	public var ratingCounter3:FlxText;
	public var ratingCounter4:FlxText;
	public var ratingCounter5:FlxText;
	public var txtTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;
	var engineWatermarkTween:FlxTween;

	public var background:FlxSprite;

	public var text:FlxText;

	public var music:FlxSound;

    public var contText:FlxText;   

    public var comboText:FlxText;	

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;	

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;	

	var precacheList:Map<String, String> = new Map<String, String>();

    var focusedChar:Null<Character>=null;

	var timeSongTxt:FlxText;

	var skipActive:Bool = false;
	var enterActive:Bool = false;
	var skipText:FlxText;

	override public function create()
	{
		FlxG.sound.cache("assets/songs/song1" + SONG.song + "Inst");
		FlxG.sound.cache("assets/songs/song2" + SONG.song + "Voices");
		FlxG.sound.cache("assets/songs/song2" + SONG.song + "Inst");
		FlxG.sound.cache("assets/songs/song1" + SONG.song + "Voices");

		Paths.clearStoredMemory();
        Paths.clearUnusedMemory();	

		precacheList.set('BF_assets', 'characters');	
        precacheList.set('BOYFRIEND_DEAD', 'characters');	

        GameOverSubstate.characterName = 'bf-dead';									

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		//Ratings
		ratingsData.push(new Rating('sick')); //default rating

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);		

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = SONG.stage;
		//trace('stage is: ' + curStage);
		if(SONG.stage == null || SONG.stage.length < 1) {
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}
		SONG.stage = curStage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null)
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage':
				var bg:BGSprite = new BGSprite('lowQuality/stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('lowQuality/stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				var stageCurtains:BGSprite = new BGSprite('lowQuality/stagecurtains', -500, -300, 1.3, 1.3);
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				add(stageCurtains);

				if (!ClientPrefs.lowQuality)
				{
					var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
					add(bg);
	
					var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					add(stageFront);
	
					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup); //Needed for blammed lights

		add(dadGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				default:
					gfVersion = 'gf';
			}

			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		var file:String = Paths.json(songName + '/dialogue');
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue');
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 96);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;	

		timeSongTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, SONG.song + " - " + "(" + storyDifficultyText + ")", 16);
		timeSongTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeSongTxt.scrollFactor.set();
		timeSongTxt.alpha = 0;
		timeSongTxt.borderSize = 2;
		if(ClientPrefs.downScroll) timeSongTxt.y = FlxG.height - 44;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.screenCenter(X);
		timeBarBG.y = timeTxt.y;
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(FlxColor.GRAY, FlxColor.fromRGB(153,50,204));
		//timeBar.createFilledBar(FlxColor.GRAY, FlxColor.LIME);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		add(timeBar);
		add(timeSongTxt);
		timeBarBG.sprTracker = timeBar;	

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		noteTypeMap.clear();
		noteTypeMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		botplayTxt = new FlxText(400, timeBarBG.y + 550, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;		
		add(botplayTxt);				
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y + -550;
		}
		
		skipActive = true;
		skipText = new FlxText(400, timeBarBG.y + 550, FlxG.width - 800);
		skipText.text = "Press Space to Skip Intro";
		skipText.borderSize = 1.25;	
		skipText.size = 30;
		skipText.color = FlxColor.WHITE;
		skipText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
		skipText.alpha = 0;
		add(skipText);	
		if(ClientPrefs.downScroll) {
			skipText.y = timeBarBG.y + -550;
		}

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.alpha = 0;
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.alpha = 0;
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.antialiasing = ClientPrefs.globalAntialiasing;	
		iconP1.alpha = 0;
		iconP1.y = healthBar.y - 75;

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.antialiasing = ClientPrefs.globalAntialiasing;	
		iconP2.alpha = 0;
		iconP2.y = healthBar.y - 75;

		reloadHealthBarColors();
		add(healthBar);
		add(healthBarBG);
		add(iconP1);
		add(iconP2);

		scoreTxt = new FlxText(0, healthBarBG.y + 26, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.antialiasing = ClientPrefs.globalAntialiasing;	
		scoreTxt.scrollFactor.set();
		scoreTxt.alpha = 0;
		scoreTxt.borderSize = 1.25;
		add(scoreTxt);

		ratingCounter1 = new FlxText(6, healthBarBG.y + -295, FlxG.width, "", 16); 
		ratingCounter1.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		ratingCounter1.antialiasing = ClientPrefs.globalAntialiasing;
		ratingCounter1.scrollFactor.set();
		ratingCounter1.alpha = 0;
		ratingCounter1.borderSize = 1.25;
		add(ratingCounter1);
		if (ClientPrefs.downScroll) {
			ratingCounter1.y = healthBarBG.y + 293; 	
		}				

		ratingCounter2 = new FlxText(6, healthBarBG.y + -268, FlxG.width, "", 16); 
		ratingCounter2.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		ratingCounter2.antialiasing = ClientPrefs.globalAntialiasing;		
		ratingCounter2.scrollFactor.set();
		ratingCounter2.alpha = 0;
		ratingCounter2.borderSize = 1.25;
		add(ratingCounter2);
		if (ClientPrefs.downScroll) {
			ratingCounter2.y = healthBarBG.y + 268; 	
		}		

		ratingCounter3 = new FlxText(6, healthBarBG.y + -238, FlxG.width, "", 16); 
		ratingCounter3.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		ratingCounter3.antialiasing = ClientPrefs.globalAntialiasing;	
		ratingCounter3.scrollFactor.set();
		ratingCounter3.alpha = 0;
		ratingCounter3.borderSize = 1.25;
		add(ratingCounter3);
		if (ClientPrefs.downScroll) {
			ratingCounter3.y = healthBarBG.y + 238; 	
		}		

		ratingCounter4 = new FlxText(6, healthBarBG.y + -208, FlxG.width, "", 16); 
		ratingCounter4.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		ratingCounter4.antialiasing = ClientPrefs.globalAntialiasing;	
		ratingCounter4.scrollFactor.set();
		ratingCounter4.alpha = 0;
		ratingCounter4.borderSize = 1.25;
		add(ratingCounter4);
		if (ClientPrefs.downScroll) {
			ratingCounter4.y = healthBarBG.y + 208; 	
		}		

		ratingCounter5 = new FlxText(6, healthBarBG.y + -178, FlxG.width, "", 16); 
		ratingCounter5.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		ratingCounter5.antialiasing = ClientPrefs.globalAntialiasing;	
		ratingCounter5.scrollFactor.set();
		ratingCounter5.alpha = 0;
		ratingCounter5.borderSize = 1.25;
		add(ratingCounter5);
		if (ClientPrefs.downScroll) {
			ratingCounter5.y = healthBarBG.y + 176; 	
		}			

		engineWatermark = new FlxText(5, healthBarBG.y + 50, "Seanacio Engine - V0.4.2", 16);
		engineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		engineWatermark.alpha = 0;
		engineWatermark.antialiasing = ClientPrefs.globalAntialiasing;	
		engineWatermark.borderSize = 1.25;
		add(engineWatermark);	
		if (ClientPrefs.downScroll) {
			engineWatermark.y = healthBarBG.y + -70;
		}	
			
		strumLineNotes.cameras = [camHUD];
		ratingCounter1.cameras = [camHUD];
		ratingCounter2.cameras = [camHUD];
		ratingCounter3.cameras = [camHUD];
		ratingCounter4.cameras = [camHUD];
		ratingCounter5.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		engineWatermark.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];	
		skipText.cameras = [camHUD];
		healthBar.cameras = [camHUD];		
		healthBarBG.cameras = [camHUD];	
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeSongTxt.cameras = [camHUD];	
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/charts' + Paths.formatToSongPath(SONG.song) + '/')];

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end		

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);														

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		}

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);		

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);

		super.create();

		Paths.clearUnusedMemory();

		for (key => type in precacheList)
		{
			//trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);				
			}
		}
		CustomFadeTransition.nextCamera = camOther;
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String, color:FlxColor) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors() {
		    healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			    FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));			

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartObjects.exists(tag))return modchartObjects.get(tag);
		if(modchartSprites.exists(tag))return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag))return modchartTexts.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		FlxG.sound.music.stop();
		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		
		video.finishCallback = function()
		{
			startAndEnd();
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		Lib.application.window.title = "Friday Night Funkin' - " + SONG.song + " (" + "Hard" + ")";

		dad.playAnim('singLEFT', true);
	    boyfriend.playAnim('singLEFT', true);

		new FlxTimer().start(0.1, function(tmr:FlxTimer) {
		    dad.playAnim('singDOWN', true);
			boyfriend.playAnim('singDOWN', true);
		});
		new FlxTimer().start(0.2, function(tmr:FlxTimer) {
		    dad.playAnim('singUP', true);
			boyfriend.playAnim('singUP', true);
		});
		new FlxTimer().start(0.3, function(tmr:FlxTimer) {
		    dad.playAnim('singRIGHT', true);
			boyfriend.playAnim('singRIGHT', true);
		});
		new FlxTimer().start(0.4, function(tmr:FlxTimer) {
		    dad.playAnim('idle', true);
			boyfriend.playAnim('idle', true);
		});

		if (ClientPrefs.getGameplaySetting('botplay', true)) {	
		    health = 2;					
		}	
		
		if (ClientPrefs.optimization) {
			camGame.visible = false;
			scoreTxt.visible = false;
			ratingCounter1.visible = false;
			ratingCounter2.visible = false;
			ratingCounter3.visible = false;
			ratingCounter4.visible = false;
			ratingCounter5.visible = false;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
				/*
				if (ClientPrefs.getGameplaySetting('fucknent', true)) {
					opponentStrums.members[0].x = 732;
					opponentStrums.members[1].x = 844;
					opponentStrums.members[2].x = 956;
					opponentStrums.members[3].x = 1068;
					playerStrums.members[0].x = 90;
					playerStrums.members[1].x = 202;
					playerStrums.members[2].x = 314;
					playerStrums.members[3].x = 426;
				}
				else if (ClientPrefs.getGameplaySetting('fucknent', true) && ClientPrefs.optimization) {
					playerStrums.members[0].x = 416;
					playerStrums.members[1].x = 528;
					playerStrums.members[2].x = 640;
					playerStrums.members[3].x = 754;
				}
				*/

				if (ClientPrefs.optimization) {
					playerStrums.members[0].x = 416;
					playerStrums.members[1].x = 528;
					playerStrums.members[2].x = 640;
					playerStrums.members[3].x = 754;
				}
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				if (ClientPrefs.optimization) opponentStrums.members[i].x = -200;	
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;


			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('invert', ['readyInvert', 'setInvert', 'goInvert']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var introAltsInvert:Array<String> = introAssets.get('invert');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);					
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.cameras = [camHUD];
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						insert(members.indexOf(notes), countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);											
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						insert(members.indexOf(notes), countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);									
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						insert(members.indexOf(notes), countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);							
					case 4:
				}

				//notes.forEachAlive(function(note:Note) {
				//	if(ClientPrefs.opponentStrums || note.mustPress)
				//	{
				//		note.copyAlpha = false;
				//		note.alpha = note.multAlpha;
				//		if(ClientPrefs.middleScroll && !note.mustPress) {
				//			note.alpha *= 0.10;
				//		}
				//	}
				//});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		FlxTween.tween(skipText, {alpha: 1}, 0.5);

		FlxTween.tween(timeSongTxt, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(timeBar, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(timeBarBG, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(healthBar, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(healthBarBG, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(iconP1, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(iconP2, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(scoreTxt, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(ratingCounter1, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(ratingCounter2, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(ratingCounter3, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(ratingCounter4, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(ratingCounter5, {alpha: 1}, 0.2, {ease: FlxEase.circOut});
		FlxTween.tween(engineWatermark, {alpha: 1}, 0.2, {ease: FlxEase.circOut});

		/*
		if(ClientPrefs.getGameplaySetting('fucknent', true) && curSong.toLowerCase() == 'Song1') {
		    PlayState.SONG = Song.loadFromJson("497830485739", "nentlay4903124");
		    PlayState.isStoryMode = false;
		    PlayState.storyDifficulty = 1;
    
		    LoadingState.loadAndSwitchState(new PlayState());
		}

		if(ClientPrefs.getGameplaySetting('fucknent', true) && curSong.toLowerCase() == 'Song2')
		{
			PlayState.SONG = Song.loadFromJson("982347398474", "nentlay4903124");
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = 1;
	
			LoadingState.loadAndSwitchState(new PlayState());
		}
		*/		

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();		

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}	

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}		

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				swagNote.ID = unspawnNotes.length;
				modchartObjects.set('note${swagNote.ID}', swagNote);
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.ID = unspawnNotes.length;
						modchartObjects.set('note${sustainNote.ID}', sustainNote);
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(ClientPrefs.middleScroll) targetAlpha = 0.10;
			}

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			if (player == 1)
			{
				modchartObjects.set("playerStrum" + i, babyArrow);
				playerStrums.add(babyArrow);
			}
			else
			{
				modchartObjects.set("opponentStrum" + i, babyArrow);
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
		}
		vocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	function truncateFloat( number : Float, precision : Int): Float {
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round( num ) / Math.pow(10, precision);
		return num;
	}

	var timer:Float = 0;	
	var beatOffset:Float = 0;
	var isDad:Bool = false;	
	override public function update(elapsed:Float)
	{
        timer+=elapsed;

		if (enterActive)
		{
			if (FlxG.keys.justPressed.ENTER)
			{
				if (isStoryMode) {
			        MusicBeatState.switchState(new StoryMenuState());
			        FlxG.sound.playMusic(Paths.music('freakyMenu'));
			    }
				else {
					MusicBeatState.switchState(new FreeplayState());
				}
		    }
		}

		if (shakeCam)
		{
			FlxG.camera.shake(0.005);
	        camHUD.shake(0.005);		
		}

		if (camGLITCH)
		{
			FlxG.camera.shake(0.010);
	        camHUD.shake(0.010);		
		}		

		if (funny){
			for (str in playerStrums)
            {					
		    FlxTween.tween(strumLine, {y: 570}, 1, {ease: FlxEase.quadInOut, type: PINGPONG});
		    FlxTween.tween(strumLine, {y: 570}, 1, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});
			}			
		}

		if (floatNoteSlow){
			for(str in playerStrums){
				str.y = strumLine.y+(10*Math.sin((timer*4)+str.ID*2));
			}
			for(str in opponentStrums){
				str.y = strumLine.y+(10*Math.sin((timer*4)+str.ID*2));
			}
		}
		else
        {
	    	for(str in playerStrums){
	    	str.angle = 0*Math.cos((timer*4)+str.ID*2);
	    	str.y = strumLine.y+(0*Math.sin((timer*4)+str.ID*2));
	    	}
	    	for(str in opponentStrums){
	    	str.angle = 0*Math.cos((timer*4)+str.ID*2);
	    	str.y = strumLine.y+(0*Math.sin((timer*4)+str.ID*2));
	    	}	
		}			

		if (floatNote){
			for(str in playerStrums){
				str.y = strumLine.y+(10*Math.sin((timer*8)+str.ID*2));
			}
			for(str in opponentStrums){
				str.y = strumLine.y+(10*Math.sin((timer*8)+str.ID*2));
			}
		}
		else
        {
	    	for(str in playerStrums){
	    	str.angle = 0*Math.cos((timer*4)+str.ID*2);
	    	str.y = strumLine.y+(0*Math.sin((timer*4)+str.ID*2));
	    	}
	    	for(str in opponentStrums){
	    	str.angle = 0*Math.cos((timer*4)+str.ID*2);
	    	str.y = strumLine.y+(0*Math.sin((timer*4)+str.ID*2));
	    	}	
		}

		if (trailShit){
			var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
			add(evilTrail);
		}
		else
		{
			var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
			remove(evilTrail);
		}

		if (windowChill){
			var libwindowX:Float = 20*Math.cos((timer*4));
			var cmdX = Std.int(windowX + libwindowX);
			Lib.application.window.move(cmdX,0);
			for (str in playerStrums){
				Cmd2 = Cmd2 + 0.0003;
			}			
		}	

		if (windowChill2){
			var libwindowX:Float = 30*Math.cos((timer*1));
			var libwindowY:Float = 20*Math.cos((timer*4));
			var cmdX = Std.int(windowX2 + libwindowX);
			var cmdY = Std.int(windowY2 + libwindowY);
			Lib.application.window.move(cmdX,cmdY);
			for (str in playerStrums){
				Cmd2 = Cmd2 + 0.0003;
			}				
		}

		if (cameraCenter) {
			camFollow.x = (((dad.getMidpoint().x + 150 + dad.cameraPosition[0]) + (boyfriend.getMidpoint().x - 100 + boyfriend.cameraPosition[0])) / 2);
		} else {
			if(isDad) {
				camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				camFollow.x += dad.cameraPosition[0];
				camFollow.y += dad.cameraPosition[1];
				tweenCamIn();
			}
		}

		if (floatRotSpinSwing){
			floatRot = true;
			spinSwing = true;
		}
		else
        if (floatRotSpinSwing){
			floatRot = false;
			spinSwing = false;
			spfinswlnef = true;
			spfinswlnef2 = true;
		}

		if (spfinswlnef){
	    	for(str in playerStrums){
	    	str.angle = 0*Math.cos((timer*4)+str.ID*2);
	    	str.y = strumLine.y+(0*Math.sin((timer*4)+str.ID*2));
	    	}
	    	for(str in opponentStrums){
	    	str.angle = 0*Math.cos((timer*4)+str.ID*2);
	    	str.y = strumLine.y+(0*Math.sin((timer*4)+str.ID*2));
	    	}			
		}

        if (floatRot){
	    	for(str in playerStrums){
	    	str.angle = 15*Math.cos((timer*4)+str.ID*2);
	    	str.y = strumLine.y+(15*Math.sin((timer*4)+str.ID*2));
	    	}
	    	for(str in opponentStrums){
	    	str.angle = 15*Math.cos((timer*4)+str.ID*2);
	    	str.y = strumLine.y+(15*Math.sin((timer*4)+str.ID*2));
	    	}
	    }	

		if (arrowSpin){
			for(str in playerStrums){
			str.angle = 90*Math.cos((timer*4)+str.ID*2);
			}
			for(str in opponentStrums){
			str.angle = 90*Math.cos((timer*4)+str.ID*2);
			}			
		}
        else
		{
			for(str in playerStrums){
			str.angle = 0*Math.cos((timer*4)+str.ID*2);
			}
			for(str in opponentStrums){
			str.angle = 0*Math.cos((timer*4)+str.ID*2);
			}	
		}

		if (timeThing){
			timeTxt.angle = Math.sin((Conductor.songPosition / 1000)*(Conductor.bpm/60) * 1.0) * 1.5;
		}	

        if (camSwing)
        {
        	FlxG.camera.angle = Math.sin((Conductor.songPosition / 1000)*(Conductor.bpm/60) * 1.0) * 2.5;
        	camHUD.angle = Math.sin((Conductor.songPosition / 1000)*(Conductor.bpm/60) * 1.0) * 2.5;
	    }
		else
		{
        	FlxG.camera.angle = Math.sin((Conductor.songPosition / 1000)*(Conductor.bpm/60) * 0) * 0;
        	camHUD.angle = Math.sin((Conductor.songPosition / 1000)*(Conductor.bpm/60) * 0) * 0;			
		}	

        if (camSwing2)
        {
        	FlxG.camera.angle = Math.sin((Conductor.songPosition / 1000)*(Conductor.bpm/60) * 1.0) * 2;
        	camHUD.angle = Math.sin((Conductor.songPosition / 1000)*(Conductor.bpm/60) * 1.0) * 0.1;
	    }						

		callOnLuas('onUpdate', [elapsed]);

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		scoreTxt.text = 'Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%' + ' | Score: ' + songScore + ' | Combo Breaks: ' + comboBreaks;
		ratingCounter1.text = 'Rating: ' + ratingFC;
		ratingCounter2.text = 'Sicks: '  + sicks;
		ratingCounter3.text = 'Goods: '  + goods;
		ratingCounter4.text = 'Bads: '  + bads;
		ratingCounter5.text = 'Shits: '  + shits;
	    if (ClientPrefs.getGameplaySetting('botplay', true)) {	
		    scoreTxt.text = 'Accuracy: ' + '0%' + ' | Score: ' + '0' + ' | Combo Breaks: ' + '0';
		    ratingCounter1.text = 'Rating: ' + 'You Suck!';
		    ratingCounter2.text = 'Sicks: '  + '0';
		    ratingCounter3.text = 'Goods: '  + '0';
		    ratingCounter4.text = 'Bads: '  + '0';
		    ratingCounter5.text = 'Shits: '  + '0';		
		}
		if(ratingName != '0%')
			scoreTxt.text += '';
	    if (ClientPrefs.getGameplaySetting('botplay', true)) {	
		scoreTxt.text = 'Accuracy: ' + '0%' + ' | Score: ' + '0' + ' | Combo Breaks: ' + '0';
		ratingCounter1.text = 'Rating: ' + 'You Suck!';
		ratingCounter2.text = 'Sicks: '  + '0';
		ratingCounter3.text = 'Goods: '  + '0';
		ratingCounter4.text = 'Bads: '  + '0';
		ratingCounter5.text = 'Shits: '  + '0';		
		}			

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		//Credits To EyeDaleHim
		var realPrt:Float = healthBar.percent;
		@:privateAccess
		{
			realPrt = ((healthBar.value - healthBar.min) / healthBar.range) * healthBar._maxPercent;
		}		

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
		{
			iconP1.animation.curAnim.curFrame = 1;
		    scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter1.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter2.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter3.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter4.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter5.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    engineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter5.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.RED, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeSongTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		}
		else
		{
			iconP1.animation.curAnim.curFrame = 0;
		    scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter1.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter2.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter3.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter4.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter5.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    engineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    ratingCounter5.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			timeSongTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		    botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		}	

		if (healthBar.percent > 80)
		{
			iconP2.animation.curAnim.curFrame = 1;
		}
		else
		{
			iconP2.animation.curAnim.curFrame = 0;
		}

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}	
		
		if (FlxG.keys.justPressed.SPACE && skipActive)
		{
			if (curSong.toLowerCase() == 'song2') {
			    setSongTime(8500);
			    clearNotesBefore(Conductor.songPosition);
			}
			else
			{
				setSongTime(2500);
			    clearNotesBefore(Conductor.songPosition);
			}
			FlxTween.tween(skipText, {alpha: 0}, 0.2, {
				onComplete: function(tw)
				{
					remove(skipText);
				}
			});
			skipActive = false;
		}
		
		if (curSong.toLowerCase() == 'song1' && Conductor.songPosition > 2500)
		{
			FlxTween.tween(skipText, {alpha: 0}, 0.4, {
				onComplete: function(tw)
				{
					remove(skipText);
				}
			});
			skipActive = false;
		}
		else if (curSong.toLowerCase() == 'song2' && Conductor.songPosition > 8500)
		{						
			FlxTween.tween(skipText, {alpha: 0}, 0.4, {
				onComplete: function(tw)
				{
					remove(skipText);
				}
			});
			skipActive = false;
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		if (camZooming2)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
		}		

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;//shit be werid on 4:3
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned=true;
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.ID]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
			}

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) //Downscroll
				{
					//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}
				else //Upscroll
				{
					//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if(daNote.copyAlpha)
					daNote.alpha = strumAlpha;

				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if(daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if(strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if(PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							} else {
								daNote.y -= 19;
							}
						}
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}

				var center:Float = strumY + Note.swagWidth / 2;
				if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
					(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}			
				
			    if (wiggleNote){
	            	if(daNote.mustPress){
	            	daNote.x = daNote.x+(10*Math.sin((timer*2)+daNote.noteData*2));
	            	}
		        }	
                if (spinSwing){
	            	if(daNote.mustPress){
	            	daNote.y = daNote.y+(10*Math.sin((timer*2)+daNote.noteData*2));
	            	}	
	            }	
				if (spfinswlnef2){
					if(daNote.mustPress){
					daNote.y = daNote.y+(0*Math.sin((timer*8)+daNote.noteData*2));
				    }					
				}							
		    });						
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);

		timeSinceLastUpdate = Lib.getTimer() / 1000;		
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	function flashWhite()
	{
        FlxG.camera.flash(FlxColor.WHITE, 1);		
	}

	function flashBlack()
	{
		FlxG.camera.flash(FlxColor.BLACK, 1);
	}

	function flashRed()
	{
        FlxG.camera.flash(FlxColor.RED, 1);		
	}

	function flashBlue()
	{
        FlxG.camera.flash(FlxColor.CYAN, 1);		
	}

	function flashGreen()
	{
        FlxG.camera.flash(FlxColor.GREEN, 1);		
	}

	function flashPink()
	{
        FlxG.camera.flash(FlxColor.PINK, 1);		
	}	

	function cameraInvis()
	{
        FlxTween.tween(camGame, {alpha: 0}, 0.5, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});		
	}

	function cameraVis()
	{
		FlxTween.tween(camGame, {alpha: 1}, 0.5, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
	}

	function hudInvis()
	{
		FlxTween.tween(camHUD, {alpha: 0}, 0.5, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
	}

	function hudVis()
	{
		FlxTween.tween(camHUD, {alpha: 1}, 0.5, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
	}

	function squishTransition()
	{
	    for (note in playerStrums) {
	    FlxTween.tween(note.scale, {x: 1.3, y: 0.5}, 0.1, {
	    	ease: FlxEase.quadInOut,
	    	onComplete: function(twn:FlxTween)
	    	{
	    		FlxTween.tween(note.scale, {x: 0.7, y: 0.7}, 0.2, {ease: FlxEase.quadInOut});
	    	}
	    });
	    }		
	}

	function switchDownscroll()
	{
		for (str in playerStrums)
        {					
		FlxTween.tween(strumLine, {y: 570}, 1, {ease: FlxEase.quadInOut});
		}
		
		for (str in opponentStrums)
        {					
		FlxTween.tween(strumLine, {y: 570}, 1, {ease: FlxEase.quadInOut});
		}
		
		for (note in playerStrums)
		{
		FlxTween.tween(playerStrums.members[0], {direction: -90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(playerStrums.members[1], {direction: -90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(playerStrums.members[2], {direction: -90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(playerStrums.members[3], {direction: -90}, 0.5, {ease: FlxEase.quadInOut});	
		}									
		
		for (note in opponentStrums)
		{
		FlxTween.tween(opponentStrums.members[0], {direction: -90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(opponentStrums.members[1], {direction: -90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(opponentStrums.members[2], {direction: -90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(opponentStrums.members[3], {direction: -90}, 0.5, {ease: FlxEase.quadInOut});												
		}				
	}

	function switchUpscroll()
	{
		for (str in playerStrums)
        {					
		FlxTween.tween(strumLine, {y: 50}, 1, {ease: FlxEase.quadInOut});
		}
		
		for (str in opponentStrums)
        {					
		FlxTween.tween(strumLine, {y: 50}, 1, {ease: FlxEase.quadInOut});
		}
		
		for (i in 0...unspawnNotes.length) {
			unspawnNotes[i].flipY = false;
		}
		
		for (note in playerStrums)
		{
		FlxTween.tween(playerStrums.members[0], {direction: 90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(playerStrums.members[1], {direction: 90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(playerStrums.members[2], {direction: 90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(playerStrums.members[3], {direction: 90}, 0.5, {ease: FlxEase.quadInOut});	
		}									
		
		for (note in opponentStrums)
		{
		FlxTween.tween(opponentStrums.members[0], {direction: 90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(opponentStrums.members[1], {direction: 90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(opponentStrums.members[2], {direction: 90}, 0.5, {ease: FlxEase.quadInOut});
		FlxTween.tween(opponentStrums.members[3], {direction: 90}, 0.5, {ease: FlxEase.quadInOut});												
		}	
	}

	function glitchNotes() {
		for (i in 0...opponentStrums.length)
			if (i == 0) {
				opponentStrums.members[i].x = FlxG.random.int(100, Std.int(FlxG.width / 3));
				opponentStrums.members[i].y = FlxG.random.int(0, 300);
			} else {
				var futurex = FlxG.random.int(Std.int(opponentStrums.members[i - 1].x) + 80, Std.int(opponentStrums.members[i - 1].x) + 400);
				if (futurex > FlxG.width - 100)
					futurex = FlxG.width - 100;
				opponentStrums.members[i].x = futurex;
				opponentStrums.members[i].y = FlxG.random.int(Std.int(opponentStrums.members[0].y - 50), Std.int(opponentStrums.members[0].y + 50));
			}
		for (i in 0...playerStrums.length) {
			if (i == 0) {
				playerStrums.members[i].x = FlxG.random.int(100, Std.int(FlxG.width / 3));
				playerStrums.members[i].y = FlxG.random.int(0, 300);
			} else {
				var futurex = FlxG.random.int(Std.int(playerStrums.members[i - 1].x) + 80, Std.int(playerStrums.members[i - 1].x) + 400);
				if (futurex > FlxG.width - 100)
					futurex = FlxG.width - 100;
				playerStrums.members[i].x = futurex;
				playerStrums.members[i].y = FlxG.random.int(Std.int(playerStrums.members[0].y - 50), Std.int(playerStrums.members[0].y + 50));
			}
		}
	}

	function missingnoThing() {
		for (i in opponentStrums)
			i.alpha = 0;
		for (i in 0...playerStrums.length) {
			if (i == 0) {
				playerStrums.members[i].x = FlxG.random.int(100, Std.int(FlxG.width / 3));
			} else {
				var futurex = FlxG.random.int(Std.int(playerStrums.members[i - 1].x) + 80, Std.int(playerStrums.members[i - 1].x) + 400);
				if (futurex > FlxG.width - 100)
					futurex = FlxG.width - 100;
				playerStrums.members[i].x = futurex;
			}
		}
	}	

	function noteReset()
	{
		for (note in playerStrums)
        {
            FlxTween.tween(playerStrums.members[0], {x: 732}, 0.5, { ease: FlxEase.cubeInOut});
            FlxTween.tween(playerStrums.members[1], {x: 844}, 0.5, { ease: FlxEase.cubeInOut});
            FlxTween.tween(playerStrums.members[2], {x: 956}, 0.5, { ease: FlxEase.cubeInOut});
            FlxTween.tween(playerStrums.members[3], {x: 1068}, 0.5, { ease: FlxEase.cubeInOut});
        }
        for (note in opponentStrums)
        {
            FlxTween.tween(opponentStrums.members[0], {x: 90}, 0.5, { ease: FlxEase.cubeInOut});
            FlxTween.tween(opponentStrums.members[1], {x: 202}, 0.5, { ease: FlxEase.cubeInOut});
            FlxTween.tween(opponentStrums.members[2], {x: 314}, 0.5, { ease: FlxEase.cubeInOut});
            FlxTween.tween(opponentStrums.members[3], {x: 426}, 0.5, { ease: FlxEase.cubeInOut});
        }
	}

	function noteFlipX()
	{
		for (note in playerStrums)
        {		
		    note.flipX = true;
		}
		for (note in opponentStrums)
        {		
		    note.flipX = true;
		}	
	}
	function noteFlipXback()
	{
		for (note in playerStrums)
        {		
		    note.flipX = false;
		}
		for (note in opponentStrums)
        {		
		    note.flipX = false;
		}		
	}

	function noteFlipY()
	{
		for (note in playerStrums)
        {		
		    note.flipY = true;
		}
		for (note in opponentStrums)
        {		
		    note.flipY = true;
		}		
	}
	function noteFlipYback()
	{
		for (note in playerStrums)
        {		
		    note.flipY = false;
		}
		for (note in opponentStrums)
        {		
		    note.flipY = false;
		}		
	}	

	function windowReset()
	{
		new FlxTimer().start(0.01, function(tmr:FlxTimer)
		{
			var xX:Float = FlxMath.lerp(windowX, Lib.application.window.x, 0.95);
			var yY:Float = FlxMath.lerp(windowY, Lib.application.window.y, 0.95);
			var xX:Float = FlxMath.lerp(windowX2, Lib.application.window.x, 0.95);
			var yY:Float = FlxMath.lerp(windowY2, Lib.application.window.y, 0.95);
			Lib.application.window.move(Std.int(xX),Std.int(yY));
		}, 20);
	}	

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		return pressed;
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		canPause = false;
		endingSong = true;
		camZooming = false;
		camZooming2 = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			WeekData.loadTheFirstEnabledMod();
			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += comboBreaks;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}

					paused = true;

					enterActive = true;

					background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
					background.alpha = 0;
					background.scrollFactor.set();
					add(background);	
			
					text = new FlxText(20, -55, 0, "Song Cleared!");
					text.size = 34;
					text.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
					text.color = FlxColor.WHITE;
					text.scrollFactor.set();
					add(text);
			
					contText = new FlxText(FlxG.width - 475, FlxG.height + 50, 0, "Press ENTER to continue.");
					contText.size = 28;
					contText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
					contText.color = FlxColor.WHITE;
					contText.scrollFactor.set();
					add(contText); 
					
					comboText = new FlxText(20, -75, 0,
						'Sicks - $sicks\nGoods - $goods\nBads - $bads\nShits - $shits\nCombo Breaks: $comboBreaks\nScore: $songScore\nRating: $ratingFC\nAccuracy: ${Highscore.floorDecimal(ratingPercent * 100, 2)}%
					');
					comboText.size = 28;
					comboText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
					comboText.color = FlxColor.WHITE;
					comboText.scrollFactor.set();
					add(comboText);

					background.cameras = [camHUD];
					text.cameras = [camHUD];
					contText.cameras = [camHUD];
					comboText.cameras = [camHUD];

					FlxTween.tween(background, {alpha: 0.5}, 0.5);
		            FlxTween.tween(text, {y: 20}, 0.5, {ease: FlxEase.expoInOut});
                    FlxTween.tween(contText, {y: FlxG.height - 45}, 0.5, {ease: FlxEase.expoInOut});
                    FlxTween.tween(comboText, {y: 145}, 0.5, {ease: FlxEase.expoInOut});
					FlxTween.tween(timeSongTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					FlxTween.tween(timeBar, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					FlxTween.tween(timeBarBG, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					FlxTween.tween(healthBar, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					FlxTween.tween(healthBarBG, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					FlxTween.tween(iconP1, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					FlxTween.tween(iconP2, {alpha: 0}, 0.5, {ease: FlxEase.circOut});		
					FlxTween.tween(engineWatermark, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					FlxTween.tween(scoreTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
					FlxTween.tween(ratingCounter1, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
					FlxTween.tween(ratingCounter2, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
					FlxTween.tween(ratingCounter3, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
					FlxTween.tween(ratingCounter4, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
					FlxTween.tween(ratingCounter5, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					FlxTween.tween(botplayTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					for (i in 0...playerStrums.length) {
						FlxTween.tween(playerStrums.members[i], {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					}
					for (i in 0...opponentStrums.length) {
						FlxTween.tween(opponentStrums.members[i], {alpha: 0}, 0.5, {ease: FlxEase.circOut});
					}	

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				
				paused = true;

				enterActive = true;

				background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
				background.alpha = 0;
				background.scrollFactor.set();
				add(background);	
		
				text = new FlxText(20, -55, 0, "Song Cleared!");
				text.size = 34;
				text.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
				text.color = FlxColor.WHITE;
				text.scrollFactor.set();
				add(text);
		
				contText = new FlxText(FlxG.width - 475, FlxG.height + 50, 0, "Press ENTER to continue.");
				contText.size = 28;
				contText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
				contText.color = FlxColor.WHITE;
				contText.scrollFactor.set();
				add(contText); 
				
				comboText = new FlxText(20, -75, 0,
					'Sicks - $sicks\nGoods - $goods\nBads - $bads\nShits - $shits\nCombo Breaks: $comboBreaks\nScore: $songScore\nRating: $ratingFC\nAccuracy: ${Highscore.floorDecimal(ratingPercent * 100, 2)}%
				');
				comboText.size = 28;
				comboText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
				comboText.color = FlxColor.WHITE;
				comboText.scrollFactor.set();
				add(comboText);

				background.cameras = [camHUD];
				text.cameras = [camHUD];
				contText.cameras = [camHUD];
				comboText.cameras = [camHUD];

				FlxTween.tween(background, {alpha: 0.5}, 0.5);
				FlxTween.tween(text, {y: 20}, 0.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(contText, {y: FlxG.height - 45}, 0.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(comboText, {y: 145}, 0.5, {ease: FlxEase.expoInOut});
				FlxTween.tween(timeSongTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(timeBar, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(timeBarBG, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(healthBar, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(healthBarBG, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(iconP1, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(iconP2, {alpha: 0}, 0.5, {ease: FlxEase.circOut});		
				FlxTween.tween(engineWatermark, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(scoreTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
				FlxTween.tween(ratingCounter1, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
				FlxTween.tween(ratingCounter2, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
				FlxTween.tween(ratingCounter3, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
				FlxTween.tween(ratingCounter4, {alpha: 0}, 0.5, {ease: FlxEase.circOut});	
				FlxTween.tween(ratingCounter5, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(botplayTxt, {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				for (i in 0...playerStrums.length) {
					FlxTween.tween(playerStrums.members[i], {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				}
				for (i in 0...opponentStrums.length) {
					FlxTween.tween(opponentStrums.members[i], {alpha: 0}, 0.5, {ease: FlxEase.circOut});
				}				

				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			if(modchartObjects.exists('note${daNote.ID}'))modchartObjects.remove('note${daNote.ID}');
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35 + 60;
		coolText.y += 200;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			//spawnNoteSplashOnNote(note);
		}

		if(note.rating == 'shit')
		{
			noteMiss(note);
		}

		if(note.rating == 'bad')
		{
			noteMiss(note);
		}		

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x + 60;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x + 60;
        comboSpr.y = rating.y + 20;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();
		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90 + 140;
			numScore.y += 80 + 200;
			//numScore.x = coolText.x + (43 * daLoop) - 90;
			//numScore.y += 80;

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}
	
	public var timeSinceLastUpdate:Float = 0.0;
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition += ((Lib.getTimer() / 1000) - timeSinceLastUpdate);

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								if(modchartObjects.exists('note${doubleNote.ID}'))modchartObjects.remove('note${doubleNote.ID}');
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else{
					callOnLuas('onGhostTap', [key]);
					if (canMiss) {
						noteMissPress(key);
						callOnLuas('noteMissPress', [key]);
					}
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}

	function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	/*TODO LIST:
	REVERT TO OLD 
	LIKE REMOVE % 4 STUFF AGAIN AND FIX EVERYTHING
	LIKE
	YKNOW
	I FORGOT TO ADD THE IF (!CLIENTWHATEVER) INPUT CODE
	THE STATE SHOULD BE NEXT TO THIS PLAYSTATE.HX
	*/

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];	

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
				{
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
		}
	}

	function noteMiss(daNote:Note):Void //You didn't hit the key and let it go offscreen, also used by Hurt Notes
	{
		if(ClientPrefs.getGameplaySetting('botplay', true)) return; //fuck it
	
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		health -= daNote.missHealth;
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		comboBreaks++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		if(char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			if(ClientPrefs.optimization) return;

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.ID]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.ghostTapping) return; //fuck it

		if (!boyfriend.stunned)
		{
			health -= 0.05;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				comboBreaks++;
			}
			totalPlayed++;
			RecalculateRating(true);

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				if(ClientPrefs.optimization) return;

				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
		callOnLuas('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;	

        //screen shake
		//so laggy
		if (curSong.toLowerCase() == 'song-name')
		{
			FlxG.camera.shake(0.010, 0.05);
	        camHUD.shake(0.005, 0.05);
		}

		if(SONG.notes[Math.floor(curStep / 16)].mustHitSection == false && !note.isSustainNote)
		{
			if (!dad.stunned)
			{
				switch(Std.int(Math.abs(note.noteData)))
				{
					case 0: camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
						    camFollow.x += dad.cameraPosition[0] - camFollowDadNote; camFollow.y += dad.cameraPosition[1];

					case 1: camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
						    camFollow.x += dad.cameraPosition[0]; camFollow.y += dad.cameraPosition[1] + camFollowDadNote;

					case 2: camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
						    camFollow.x += dad.cameraPosition[0]; camFollow.y += dad.cameraPosition[1] - camFollowDadNote;

					case 3: camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
						    camFollow.x += dad.cameraPosition[0] + camFollowDadNote; camFollow.y += dad.cameraPosition[1];
				}                   
			}
		} 

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			if(char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.09;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.09;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;		

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, note.ID]);

		if (!note.isSustainNote)
		{
			if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

		    //if(note.noteType == 'Crash Note') {
		    //	var errMsg:String = "";
		    //	
		    //	errMsg += "Error: YOU SUCK!";
	        //
		    //	Application.current.window.alert(errMsg, "Error!");
		    //	DiscordClient.shutdown();
		    //	Sys.exit(1);
		    //}

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				if(!note.noMissAnimation)
				{
					switch(note.noteType) {
						case 'Hurt Note': //Hurt note
							if(boyfriend.animation.getByName('hurt') != null) {
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
					}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
			health += note.hitHealth;

			if(!note.noAnimation) {
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if(note.gfNote)
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					boyfriend.holdTimer = 0;

					if(SONG.notes[Math.floor(curStep / 16)].mustHitSection == true && !note.isSustainNote) {
						if (!boyfriend.stunned)
						{
							switch(Std.int(Math.abs(note.noteData))){				 
								case 0: camFollow.set(boyfriend.getMidpoint().x - 150, boyfriend.getMidpoint().y - 100);
									    camFollow.x += boyfriend.cameraPosition[0] - camFollowBFNote; camFollow.y += boyfriend.cameraPosition[1];

								case 1: camFollow.set(boyfriend.getMidpoint().x - 150, boyfriend.getMidpoint().y - 100);
									    camFollow.x += boyfriend.cameraPosition[0]; camFollow.y += boyfriend.cameraPosition[1] + camFollowBFNote;

								case 2: camFollow.set(boyfriend.getMidpoint().x - 150, boyfriend.getMidpoint().y - 100);
									    camFollow.x += boyfriend.cameraPosition[0]; camFollow.y += boyfriend.cameraPosition[1] - camFollowBFNote;

								case 3:	camFollow.set(boyfriend.getMidpoint().x - 150, boyfriend.getMidpoint().y - 100);
									    camFollow.x += boyfriend.cameraPosition[0] + camFollowBFNote; camFollow.y += boyfriend.cameraPosition[1];			
							}                        
						}
					}					
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.09;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.09;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus, note.ID]);

			if (!note.isSustainNote)
			{
				if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);		

		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);

		if (curSong.toLowerCase() == 'song1' && curBeat >= 1 && curBeat < 999) {
		    if (curStep % 4 == 0){
		    	FlxTween.tween(camGame, {y: -12}, Conductor.stepCrochet*0.002, {ease: FlxEase.circOut});
				FlxTween.tween(camHUD, {y: -12}, Conductor.stepCrochet*0.002, {ease: FlxEase.circOut});
		    	FlxTween.tween(camGame.scroll, {y: 12}, Conductor.stepCrochet*0.002, {ease: FlxEase.sineIn});
				FlxTween.tween(camHUD.scroll, {y: 12}, Conductor.stepCrochet*0.002, {ease: FlxEase.circOut});
				FlxTween.tween(camHUD, {x: -angleshit*8}, Conductor.crochet*0.001, {ease: FlxEase.linear});
                FlxTween.tween(camGame, {x: -angleshit*8}, Conductor.crochet*0.001, {ease: FlxEase.linear});
            }
    
		    if (curStep % 4 == 2){
		    	FlxTween.tween(camGame, {y: 0}, Conductor.stepCrochet*0.002, {ease: FlxEase.sineIn});
				FlxTween.tween(camHUD, {y: 0}, Conductor.stepCrochet*0.002, {ease: FlxEase.circOut});
		    	FlxTween.tween(camGame.scroll, {y: 0}, Conductor.stepCrochet*0.002, {ease: FlxEase.sineIn});
				FlxTween.tween(camHUD.scroll, {y: 0}, Conductor.stepCrochet*0.002, {ease: FlxEase.circOut});
				FlxTween.tween(camHUD, {x: angleshit*8}, Conductor.crochet*0.001, {ease: FlxEase.linear});
				FlxTween.tween(camGame, {x: angleshit*8}, Conductor.crochet*0.001, {ease: FlxEase.linear});				
            }
	    }

		switch (curSong){
			case 'Song-Name':
				switch (curStep){							
					case 0:
					squishTransition();		
					flashWhite();
					flashBlack();
					flashRed();
					flashBlue();
					flashGreen();
					flashPink();	
					glitchNotes();
					noteReset();
					switchDownscroll();
					switchUpscroll();
					cameraInvis();
					cameraVis();
					hudInvis();
					hudVis();
					windowReset();
					noteFlipX();
					noteFlipY();
					noteFlipXback();
					noteFlipYback();
				    Lib.application.window.fullscreen = false;
					Lib.application.window.maximized = true;
					windowChill = true;
					camSwing = true;
					floatNote = true;
					defaultCamZoom = 0.9;
					cameraCenter = true;		
					FlxG.camera.zoom -= 0.120;
			        camHUD.zoom -= 0.08;
					FlxTween.tween(camGame, {alpha:0}, 0.1, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});					
				}		
				case 'Song3':
					switch (curStep){
						case 1:				
							FlxG.camera.flash(FlxColor.BLACK, 6);
						case 96:
							camGame.alpha = 0;	
						case 112:
							FlxG.camera.flash(FlxColor.WHITE, 0.5);
							defaultCamZoom = 0.7;												
							camGame.alpha = 1;	
						case 128:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 2);
						case 160:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 2);
						case 192:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 2);
						case 224:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 1);	
						case 244:					
							defaultCamZoom = 1;			
						case 256:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 2);
							defaultCamZoom = 0.7;	
						case 288:
							FlxG.camera.flash(FlxColor.WHITE, 0.5);
							camGame.alpha = 0;	
						case 308:
							FlxG.camera.flash(FlxColor.WHITE, 0.5);
							camGame.alpha = 1;
	
						case 352:
							FlxG.camera.flash(FlxColor.WHITE, 0.5);
							camGame.alpha = 0;	
						case 372:
							FlxG.camera.flash(FlxColor.WHITE, 0.5);
							camGame.alpha = 1;
	
						case 320:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 2);
						case 384:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 2);
						case 416:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 2);	
						case 448:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 2);	
						case 480:
							FlxG.camera.zoom -= 0.120;
							camHUD.zoom -= 0.08;						
							FlxG.camera.flash(FlxColor.WHITE, 2);
						case 496:
							FlxTween.tween(camGame, {alpha: 0}, 1, { ease: FlxEase.cubeInOut});	
						case 512:
							floatNote = true;
							FlxG.camera.flash(FlxColor.WHITE, 1);
							camGame.alpha = 1;	
						case 576:
							defaultCamZoom = 0.9;
							FlxG.camera.flash(FlxColor.WHITE, 0.3);
							floatNote = false;	
						case 580:
							FlxG.camera.flash(FlxColor.WHITE, 0.3);
							defaultCamZoom = 0.6;
						case 584:
							FlxG.camera.flash(FlxColor.WHITE, 0.3);
							defaultCamZoom = 0.9;
						case 588:
							FlxG.camera.flash(FlxColor.WHITE, 0.3);
							defaultCamZoom = 0.6;
						case 592:
							FlxG.camera.flash(FlxColor.WHITE, 0.3);
							defaultCamZoom = 0.9;
						case 596:
							FlxG.camera.flash(FlxColor.WHITE, 0.3);
							defaultCamZoom = 0.6;
						case 600:
							FlxG.camera.flash(FlxColor.WHITE, 0.3);
							defaultCamZoom = 0.9;
						case 604:
							FlxG.camera.flash(FlxColor.WHITE, 0.3);
							defaultCamZoom = 0.6;
						case 640:
							FlxTween.tween(camGame, {alpha: 0}, 1, { ease: FlxEase.cubeInOut});	
							FlxTween.tween(camHUD, {alpha: 0}, 1, { ease: FlxEase.cubeInOut});	
						case 660:
							camHUD.alpha = 1;
							camGame.alpha = 1;
							for (note in opponentStrums)
							{
							FlxTween.tween(opponentStrums.members[0], {x: 416, alpha: 0.4}, 0.0001, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(opponentStrums.members[1], {x: 528, alpha: 0.4}, 0.0001, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(opponentStrums.members[2], {x: 640, alpha: 0.4}, 0.0001, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(opponentStrums.members[3], {x: 754, alpha: 0.4}, 0.0001, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(playerStrums.members[0], {x: 416}, 0.0001, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(playerStrums.members[1], {x: 528}, 0.0001, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(playerStrums.members[2], {x: 640}, 0.0001, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(playerStrums.members[3], {x: 754}, 0.0001, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});						
							}	
						case 784 | 785 | 786 | 790 | 791 | 792 | 796 | 798 | 848 | 849 | 850 | 854 | 855 | 856 | 860 | 862:
							missingnoThing();
							FlxG.camera.shake(0.010, 0.05);
							camHUD.shake(0.005, 0.05);
						case 787 | 793 | 800 | 851 | 857 | 864:
							for (note in opponentStrums)
							{
							FlxTween.tween(opponentStrums.members[0], {x: 416, alpha: 0.4}, 0.2, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(opponentStrums.members[1], {x: 528, alpha: 0.4}, 0.2, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(opponentStrums.members[2], {x: 640, alpha: 0.4}, 0.2, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(opponentStrums.members[3], {x: 754, alpha: 0.4}, 0.2, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(playerStrums.members[0], {x: 416}, 0.2, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(playerStrums.members[1], {x: 528}, 0.2, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(playerStrums.members[2], {x: 640}, 0.2, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});
							FlxTween.tween(playerStrums.members[3], {x: 754}, 0.2, { ease: FlxEase.cubeInOut, type: FlxTween.PERSIST});						
							}						
						case 912:
							noteReset();																																																																																		
					}																																					
			}	
			
			switch (curSong){
				case 'Song3':
					switch (curBeat){							
						case 168:
						Lib.application.window.fullscreen = false;
						Lib.application.window.maximized = true;
						windowChill = true;				
					}	
		    }			
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	var camtween:FlxTween;
	var angleshit:Float = 1;
	var anglevar:Float = 1;
	var turnvalue:Float = 25;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}

		if (curBeat % 4 == 0){
			FlxG.camera.zoom += 0.030;
			camZooming2 = true;
			if(camtween != null) {
				camtween.cancel();
			}
			camHUD.zoom = 1.05;
			camtween = FlxTween.tween(camHUD, {zoom: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					camtween = null;
				}
			});	
		}

        if (curBeat % 2 == 0){		
			iconP1.angle = -8;
			iconP2.angle = 8;	
		    iconP1.setGraphicSize(Std.int(iconP1.width + 40));
		    iconP2.setGraphicSize(Std.int(iconP2.width + 40));
		}
		else
		{
			iconP1.angle = 8;
			iconP2.angle = -8;
			iconP1.setGraphicSize(Std.int(iconP1.width + 40));
			iconP2.setGraphicSize(Std.int(iconP2.width + 40));
		}	
		iconP1.updateHitbox();
		iconP2.updateHitbox();

        if (curSong.toLowerCase() == 'song-name' && curBeat >= 1 && curBeat < 1 && camZooming && FlxG.camera.zoom < 1.35)
		{
            var disco:FlxColor = new FlxColor();
            switch (FlxG.random.int(1, 4))
            {
				case 1:
					disco = FlxColor.fromString('#C660CE');
				case 2:
					disco = FlxColor.fromString('#009dff');
				case 3:
					disco = FlxColor.fromString('#45f248');
				case 4:
					disco = FlxColor.fromString('#FFA500');
            }
            FlxG.camera.flash(disco, 0.5, null, true);						
			FlxG.camera.zoom += 0.060;
		    camHUD.zoom += 0.06;						
		}			

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}	 			

		if (curSong.toLowerCase() == 'song-name' && curBeat == 1 )
		{
			windowX = Lib.application.window.x;
			windowY = Lib.application.window.y;
		}						

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops=false, ?exclusions:Array<String>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		//trace(event, returnVal);
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false) {
		setOnLuas('score', songScore);
		setOnLuas('misses', comboBreaks);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (comboBreaks > 0 && comboBreaks < 10) ratingFC = "SDCB";
			else if (comboBreaks >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	var curLight:Int = -1;
	var curLightEvent:Int = -1;
}
