package;

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
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxSave;
import flixel.animation.FlxAnimationController;
import animateatlas.AtlasFrameMaker;
import achievements.Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import Conductor.Rating;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if VIDEOS_ALLOWED
#if hxCodec
#if (hxCodec >= "2.6.1") import hxcodec.VideoHandler as MP4Handler;
#elseif (hxCodec == "2.6.0") import VideoHandler as MP4Handler;
#else import vlc.MP4Handler; #end
#end
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartTweens:Map<String, FlxTween> = new Map();
	public var modchartSprites:Map<String, ModchartSprite> = new Map();
	public var modchartTimers:Map<String, FlxTimer> = new Map();
	public var modchartSounds:Map<String, FlxSound> = new Map();
	public var modchartTexts:Map<String, ModchartText> = new Map();
	public var modchartSaves:Map<String, FlxSave> = new Map();
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

	public var playbackRate(default, set):Float = 1;

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

	public var spawnTime:Float = 2000;

	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var ara:BGSprite;
	public var dono:BGSprite;

	public static var dadIdleInt:Int = 4;
	public static var gfIdleInt:Int = 4;
	public static var bfIdleInt:Int = 4;

	public static var dadInvertIdleDirection:Bool = false;
	public static var gfInvertIdleDirection:Bool = false;
	public static var bfInvertIdleDirection:Bool = false;

	public static var dadIdleisHalfBeat:Bool = false;
	public static var gfIdleisHalfBeat:Bool = false;
	public static var bfIdleisHalfBeat:Bool = false;

	public static var dadIdleSpeedChanged:Bool = false;
	public static var gfIdleSpeedChanged:Bool = false;
	public static var isGfIdleByBPM:Bool = true;
	public static var bfIdleSpeedChanged:Bool = false;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public static var healthGainOnSustains:Bool = true; //This will be used soon... (I guess lol)
	public static var allowedHealthDrainByOpponent:Bool = true;
	public static var healthDrainOnOpponentSustains:Bool = true;

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var camFollowReal:FlxPoint;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var grpOpponentNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var opponentHoldCovers:HoldCover;
	public var playerHoldCovers:HoldCover;

	var forceDisableSustainLoop:Bool = false;

	public var camZooming:Bool = true; //so now it's canon that camZooming is activated from the beginning of the song eh?
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	//public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	var originalScroll:Bool;

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

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var visualsOnlyMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camCountdown:FlxCamera; //Joder
	public var camGameOverlay:FlxCamera; //Mátenme, ya parezco Glowsoony :worried:
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;
	
	var heyTimer:Float;

	var luz:FlxSprite;

	var fire:FlxSprite;

	var stageBack:BGSprite;
	var stageFront:BGSprite;
	var mueble:BGSprite;
	var adornos:BGSprite;
	var extra:BGSprite;
	var luzChanger:FlxSprite;
	var stageBackOLD:BGSprite;
	var stageFrontOLD:BGSprite;
	var muebleOLD:BGSprite;
	var adornosOLD:BGSprite;
	var extraOLD:BGSprite;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	var checkSubtitlesOptionTextBG:FlxSprite;
	var checkSubtitlesOptionText:Alphabet;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	private var songInfo:SongInfo;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	public var cameraOffsetWhenSinging:Array<Float> = null;
	var moveCameraWhenSingingBool:Bool = false;
	var cameraOffsetWhenSingingValue:Float = 25;

	var blackOverlayCamGame:FlxSprite;
	var blackOverlayCamHUD:FlxSprite;

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
	var tauntCounter:Int = 0;

	//Hazard shit (Sorry, I stole it Haz lol) -Drkfon
	var hazardAlarmLeft:BGSprite;
	var hazardAlarmRight:BGSprite;

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
	private var controlArray:Array<String>;

	private var tauntKey:Array<FlxKey>;

	var precacheList:Map<String, String> = new Map<String, String>();
	
	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];
	public var lastHeyCombo:Int = 0;
	public var heyComboInterval:Int = 250; 

	public var healthLerp:Float = 1;

	public var songName:String = null;

	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		tauntKey = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('taunt'));

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
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
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		#if covers_build
		visualsOnlyMode = ClientPrefs.getGameplaySetting('visualsOnly', false);
		#else
		visualsOnlyMode = false;
		#end

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camGameOverlay = new FlxCamera();
		camHUD = new FlxCamera();
		camCountdown = new FlxCamera();
		camOther = new FlxCamera();
		camGameOverlay.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camCountdown.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camGameOverlay, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camCountdown, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpOpponentNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);

		curStage = SONG.stage;
		//trace('stage is: ' + curStage);
		if(SONG.stage == null || SONG.stage.length < 1) {
			switch (songName)
			{
				case 'bad-battle', 'friendship-v2':
					curStage = 'Stage-Rami';
				case 'intervention':
					curStage = 'Stage-Rami-Sunset';
				case 'friendship':
					curStage = 'Stage-Rami-Night';
				case 'override', 'bad-battle-pico':
					curStage = 'Stage-Drk';
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
				camera_speed: 1,
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
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];
		
		if(cameraOffsetWhenSinging == null)
			cameraOffsetWhenSinging = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				//This is for trash PCs, like zRamirez for example
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'Stage-Rami': //Vs zRamirez - zRamirez Day Back Stage
				var stageBack:BGSprite = new BGSprite('StageHotfix/StageBack', -200, 0, 1.0, 1.0);
				add(stageBack);

				var stageFront:BGSprite = new BGSprite('StageHotfix/StageFront', -208, 1031, 1.0, 1.0);
				add(stageFront);

				var mueble:BGSprite = new BGSprite('StageHotfix/StageMueble', 569, 607, 1.0, 1.0);
				mueble.setGraphicSize(Std.int(mueble.width * 1.1));
				mueble.updateHitbox();
				add(mueble);
				//This is for trash PCs, like zRamirez for example
				if(!ClientPrefs.lowQuality) {
					var adornos:BGSprite = new BGSprite('StageHotfix/Adornos', -110, 305, 1.0, 1.0);
					add(adornos);

					var extra:BGSprite = new BGSprite('StageHotfix/StageExtra2', 290, 715, 1.0, 1.0);
					add(extra);

					luz = new FlxSprite(-200, 0).loadGraphic(Paths.image('StageHotfix/idk'));
					luz.scrollFactor.set(1.0, 1.0);
					luz.alpha=0.2;
				}

			case 'Stage-Rami-Sunset': //Vs zRamirez - zRamirez Sunset Back Stage
				var stageBack:BGSprite = new BGSprite('StageHotfix/StageBack-Sunset', -200, 0, 1.0, 1.0);
				add(stageBack);

				var stageFront:BGSprite = new BGSprite('StageHotfix/StageFront', -208, 1031, 1.0, 1.0);
				add(stageFront);

				var mueble:BGSprite = new BGSprite('StageHotfix/StageMueble', 569, 607, 1.0, 1.0);
				mueble.setGraphicSize(Std.int(mueble.width * 1.1));
				mueble.updateHitbox();
				add(mueble);
				//This is for trash PCs, like zRamirez for example
				if(!ClientPrefs.lowQuality) {
					var adornos:BGSprite = new BGSprite('StageHotfix/Adornos', -110, 305, 1.0, 1.0);
					add(adornos);

					var extra:BGSprite = new BGSprite('StageHotfix/StageExtra2', 290, 715, 1.0, 1.0);
					add(extra);

					luz = new FlxSprite(-200, 0).loadGraphic(Paths.image('StageHotfix/idk'));
					luz.scrollFactor.set(1.0, 1.0);
					luz.alpha=0.2;
				}

			case 'Stage-Rami-Night': //Vs zRamirez - zRamirez Night Back Stage
				var stageBack:BGSprite = new BGSprite('StageHotfix/StageBack-Night', -200, 0, 1.0, 1.0);
				add(stageBack);

				var stageFront:BGSprite = new BGSprite('StageHotfix/StageFront', -208, 1031, 1.0, 1.0);
				add(stageFront);

				var mueble:BGSprite = new BGSprite('StageHotfix/StageMueble', 569, 607, 1.0, 1.0);
				mueble.setGraphicSize(Std.int(mueble.width * 1.1));
				mueble.updateHitbox();
				add(mueble);
				//This is for trash PCs, like zRamirez for example
				if(!ClientPrefs.lowQuality) {
					var adornos:BGSprite = new BGSprite('StageHotfix/Adornos', -110, 305, 1.0, 1.0);
					add(adornos);

					var extra:BGSprite = new BGSprite('StageHotfix/StageExtra2', 290, 715, 1.0, 1.0);
					add(extra);

					luz = new FlxSprite(-200, 0).loadGraphic(Paths.image('StageHotfix/idk'));
					luz.scrollFactor.set(1.0, 1.0);
					luz.alpha=0.2;
				}

			case 'Stage-Drk': //Vs zRamirez - DrkFon Evening Stage
				var stageBack:BGSprite = new BGSprite('Tree-Stage/sky', -390, -470, 1.0, 1.0);
				add(stageBack);

				var bush:BGSprite = new BGSprite('Tree-Stage/bush', -390, -470, 1.0, 1.0);
				add(bush);

				var stageFront:BGSprite = new BGSprite('Tree-Stage/tree', -390, -470, 1.0, 1.0);
				add(stageFront);

				//This is for trash PCs, like zRamirez for example
				if(!ClientPrefs.lowQuality) {
					ara = new BGSprite('Tree-Stage/ara-background', 1815, 470, 1.0, 1.0, ['Ara idle dance']);
					ara.setGraphicSize(Std.int(ara.width * 0.9));
					ara.updateHitbox();
					ara.antialiasing = ClientPrefs.globalAntialiasing;
					add(ara);

					dono = new BGSprite('Tree-Stage/donni-backstage', 250, 405, 1.0, 1.0, ['Donni idle dance']);
					dono.setGraphicSize(Std.int(dono.width * 0.9));
					dono.updateHitbox();
					dono.antialiasing = ClientPrefs.globalAntialiasing;
					add(dono);
				}

			case 'Stage-Rami-Changer': //Vs zRamirez - zRamirez Changer Stage (is used in Bad Battle Hotfix and soon in Bad Battle Fucked Remix)
				//New Stuff (This isn't visible by default)
				stageBack = new BGSprite('StageHotfix/StageBack', -200, 0, 1.0, 1.0);
				add(stageBack);
				stageBack.visible=false;

				stageFront = new BGSprite('StageHotfix/StageFront', -208, 1031, 1.0, 1.0);
				add(stageFront);
				stageFront.visible=false;

				mueble = new BGSprite('StageHotfix/StageMueble', 569, 607, 1.0, 1.0);
				mueble.setGraphicSize(Std.int(mueble.width * 1.1));
				mueble.updateHitbox();
				add(mueble);
				mueble.visible=false;
				//This is for trash PCs, like zRamirez for example
				if(!ClientPrefs.lowQuality) {
					adornos = new BGSprite('StageHotfix/Adornos', -110, 305, 1.0, 1.0);
					add(adornos);
					adornos.visible=false;

					extra = new BGSprite('StageHotfix/StageExtra2', 290, 715, 1.0, 1.0);
					add(extra);
					extra.visible=false;

					luzChanger = new FlxSprite(-200, 0).loadGraphic(Paths.image('StageHotfix/idk'));
					luzChanger.scrollFactor.set(1.0, 1.0);
					luzChanger.alpha=0.2;
					luzChanger.visible=false;
				}
				//Old Stuff (This is visible by default)
				stageBackOLD = new BGSprite('StageHotfix/StageBackOLD', -200, 0);
				add(stageBackOLD);
				stageBackOLD.visible=true;

				stageFrontOLD = new BGSprite('StageHotfix/StageFrontOLD', -200, 1050, 1.0, 1.0);
				add(stageFrontOLD);
				stageFrontOLD.visible=true;

				muebleOLD = new BGSprite('StageHotfix/StageMuebleOLD', 586, 699, 1.0, 1.0);
				muebleOLD.setGraphicSize(Std.int(muebleOLD.width * 1.0));
				muebleOLD.updateHitbox();
				add(muebleOLD);
				muebleOLD.visible=true;
				//This is for trash PCs, like zRamirez for example
				if(!ClientPrefs.lowQuality) {
					adornosOLD = new BGSprite('StageHotfix/AdornosOLD', -110, 300, 1.0, 1.0);
					add(adornosOLD);
					adornosOLD.visible=true;

					extraOLD = new BGSprite('StageHotfix/StageExtra2OLD', 265, 735, 1.0, 1.0);
					add(extraOLD);
					extraOLD.visible=true;
				}

			case 'Stage-Rami-Fire': //Vs zRamirez - zRamirez Stage Burning
				var fondo:FlxSprite = new FlxSprite(466, 147);
				fondo.frames = Paths.getSparrowAtlas('StageZFire/Fondo-Stage');
				fondo.animation.addByPrefix('idle', 'MIFONDOENLLAMAS0', 24, true);
				fondo.scrollFactor.set(1.0, 1.0);
				add(fondo);
				fondo.animation.play('idle', true);

				fire = new FlxSprite(-200, 900);
				fire.frames = Paths.getSparrowAtlas('StageZFire/Fire');
				fire.animation.addByPrefix('idle', 'Stage fuego0', 24, true);
				fire.scrollFactor.set(1.0, 1.0);
				fire.animation.play('idle', true);

				var stageBack:BGSprite = new BGSprite('StageZFire/StageBack', -200, 0, 1.0, 1.0);
				add(stageBack);

				var stageFront:BGSprite = new BGSprite('StageZFire/StageFront', -208, 1031, 1.0, 1.0);
				add(stageFront);

				var mueble:BGSprite = new BGSprite('StageZFire/Mueble', 569, 641, 1.0, 1.0);
				mueble.setGraphicSize(Std.int(mueble.width * 1.1));
				mueble.updateHitbox();
				add(mueble);
				//This is for trash PCs, like zRamirez for example
				if(!ClientPrefs.lowQuality) {
					var adornos:BGSprite = new BGSprite('StageZFire/StageExtra', -110, 305, 1.0, 1.0);
					add(adornos);

					var extra:BGSprite = new BGSprite('StageZFire/StageExtra2', 290, 715, 1.0, 1.0);
					add(extra);

					var grid:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('StageZFire/BLURE'));
					grid.scrollFactor.set(1.0, 1.0);
					grid.cameras = [camOther];
					grid.alpha=0.5;
					add(grid);
				}

		}
		
		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		tauntCounter = 0;

		//For the 'alarm' effect. Only added if flashling lights is allowed and low quality is off.
		if(ClientPrefs.flashing && !ClientPrefs.lowQuality){
			hazardAlarmLeft = new BGSprite('back-Gradient', -600, -480, 0.5, 0.5);
			hazardAlarmLeft.setGraphicSize(Std.int(hazardAlarmLeft.width * 1.1));
			hazardAlarmLeft.updateHitbox();
			hazardAlarmLeft.alpha=0;
			hazardAlarmLeft.color = FlxColor.RED;
			hazardAlarmLeft.cameras = [camOther];
			hazardAlarmLeft.x-=85;
			add(hazardAlarmLeft);

			hazardAlarmRight = new BGSprite('back-Gradient', -600, -480, 0.5, 0.5);
			hazardAlarmRight.setGraphicSize(Std.int(hazardAlarmRight.width * 1.1));
			hazardAlarmRight.updateHitbox();
			hazardAlarmRight.flipX = true;
			hazardAlarmRight.alpha=0;
			hazardAlarmRight.color = FlxColor.RED;
			hazardAlarmRight.cameras = [camOther];
			hazardAlarmRight.x-=85;
			add(hazardAlarmRight);
		}

		//Nerfed the blackOverlay from line 1400 to here cuz they were too op
		blackOverlayCamGame = new FlxSprite(0, 200).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackOverlayCamGame.screenCenter();
		blackOverlayCamGame.updateHitbox();
		blackOverlayCamGame.alpha = SONG.overlayCamGame_On ? 1 : 0;
		blackOverlayCamGame.cameras = [camGameOverlay];
		add(blackOverlayCamGame);

		blackOverlayCamHUD = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
		blackOverlayCamHUD.screenCenter();
		blackOverlayCamHUD.updateHitbox();
		blackOverlayCamHUD.alpha = SONG.overlayCamHUD_On ? 1 : 0;
		blackOverlayCamHUD.cameras = [camCountdown]; //Ironic, right?
		add(blackOverlayCamHUD);

		// Shitty layering but whatev it works LOL
		add(gfGroup); //Needed for blammed lights
		add(boyfriendGroup);
		add(dadGroup);

		switch(curStage)
		{
			case 'Stage-Rami', 'Stage-Rami-Sunset', 'Stage-Rami-Night':
				add(luz);

			case 'Stage-Rami-Changer':
				add(luzChanger);

			case 'Stage-Rami-Fire':
				add(fire);
		}

		forceDisableSustainLoop = false;

		if (Paths.formatToSongPath(SONG.song) == 'bad-battle-pico')
		{
			GameOverSubstate.characterName = 'pico-dead';
			forceDisableSustainLoop = true;
			skipCountdown = true;
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end

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

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		startLuasOnFolder('stages/' + curStage + '.lua');
		#end

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1)
		{
			switch (curStage)
			{
				case 'Stage-Rami', 'Stage-Rami-Sunset', 'Stage-Rami-Night':
					gfVersion = 'gf-ramirez';
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

		originalScroll = ClientPrefs.downScroll;

		if (gf != null /*&& !isGfIdleByBPM*/)
			gfIdleInt = recalculateIdleInt(SONG.bpm);
		bfIdleInt = recalculateIdleInt(SONG.bpm);
		dadIdleInt = recalculateIdleInt(SONG.bpm);

		dadIdleSpeedChanged = false;
		gfIdleSpeedChanged = false;
		bfIdleSpeedChanged = false;

		gfIdleisHalfBeat = false;
		bfIdleisHalfBeat = false;
		dadIdleisHalfBeat = false;

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
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

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled' && !visualsOnlyMode);
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("PhantomMuff Full Letters 1.1.5.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		timeTxt.antialiasing = ClientPrefs.globalAntialiasing;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();

		add(strumLineNotes);
		add(grpNoteSplashes);
		add(grpOpponentNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		grpOpponentNoteSplashes.add(splash);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);

		for (note in unspawnNotes) 
		{
    		if (note.isSustainNote && (ClientPrefs.disableSustainLoop || forceDisableSustainLoop))
			{
        		note.noAnimation = true;
   		 	}
		}

		opponentHoldCovers = new HoldCover(!visualsOnlyMode ? (ClientPrefs.holdSplashes && ClientPrefs.opponentStrums ? true : false) : false, false);
	    playerHoldCovers = new HoldCover(!visualsOnlyMode ? ClientPrefs.holdSplashes : false, true);
		add(opponentHoldCovers);
		add(playerHoldCovers);

		if (ClientPrefs.middleScroll)
			opponentHoldCovers.alpha = 0.35;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		camFollowReal = new FlxPoint();

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
		moveCameraSection();

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = (!ClientPrefs.hideHud && !visualsOnlyMode);
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'healthLerp', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = (!ClientPrefs.hideHud && !visualsOnlyMode);
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = (!ClientPrefs.hideHud && !visualsOnlyMode);
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = (!ClientPrefs.hideHud && !visualsOnlyMode);
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("PhantomMuff Full Letters 1.1.5.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.antialiasing = ClientPrefs.globalAntialiasing;
		scoreTxt.visible = (!ClientPrefs.hideHud && !visualsOnlyMode);
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "VS zRamírez", 32);
		botplayTxt.setFormat(Paths.font("PhantomMuff Full Letters 1.1.5.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.antialiasing = ClientPrefs.globalAntialiasing;
		botplayTxt.visible = (cpuControlled && !visualsOnlyMode);
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		playerHoldCovers.cameras = [camHUD];
		opponentHoldCovers.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpOpponentNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			startLuasOnFolder('custom_notetypes/' + notetype + '.lua');
		}
		for (event in eventPushedMap.keys())
		{
			startLuasOnFolder('events/' + event + '.lua');
			startLuasOnFolder('custom_events/' + event + '.lua');
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + Paths.formatToSongPath(SONG.song) + '/' ));// using push instead of insert because these should run after everything else
		#end

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
		if (!seenCutscene)
		{
			if (isStoryMode)
			{
				switch (daSong)
				{
					case 'bad-battle':
						startVideo(ClientPrefs.cutscenesSubtitles ? "Bad_Battle_Cutscene_Eng_Subtitles" : "Bad_Battle_Cutscene");

					case 'intervention':
						startVideo(ClientPrefs.cutscenesSubtitles ? "Intervention_Cutscene_Eng_Subtitles" : "Intervention_Cutscene");

					case 'friendship':
						startVideo(ClientPrefs.cutscenesSubtitles ? "Friendship_Cutscene_Eng_Subtitles" : "Friendship_Cutscene");

					default:
						startCountdown();
				}
				seenCutscene = true;
			}
			else
			{
				if (!isStoryMode)
				{
					switch (daSong)
					{
						case 'bad-battle':
							if (storyDifficulty == 2)
							{
								startVideo(ClientPrefs.cutscenesSubtitles ? "Bad_Battle_Fucked_Cutscene_Eng_Subtitles" : "Bad_Battle_Fucked_Cutscene");
							}
							else
							{
								startCountdown();
							}

						case 'override':
							startVideo(ClientPrefs.cutscenesSubtitles ? "Override_Cutscene_Eng_Subtitles" : "Override_Cutscene");
							
						default:
							startCountdown();
					}
					seenCutscene = true;
				}
				else 
				{
					startCountdown();
				}
			}
		}		
		else 
		{
			startCountdown();
		}
		RecalculateRating();

		if (isStoryMode && Paths.formatToSongPath(SONG.song) == "bad-battle" && !FlxG.save.data.enteredVisualsOptions)
		{
			checkSubtitlesOptionText = new Alphabet(0, FlxG.height + 300, 'You can enable English Subtitles for Cutscenes in Visuals Options', true);
			checkSubtitlesOptionText.setScale(0.4, 0.4);
			checkSubtitlesOptionText.screenCenter(X);
			checkSubtitlesOptionText.cameras = [camOther];

			checkSubtitlesOptionTextBG = new FlxSprite(0, FlxG.height + 285.8).makeGraphic(Std.int(checkSubtitlesOptionText.width + 60), Std.int(checkSubtitlesOptionText.height * 2), FlxColor.BLACK);
			checkSubtitlesOptionTextBG.alpha = 0.6;
			checkSubtitlesOptionTextBG.screenCenter(X);
			checkSubtitlesOptionTextBG.cameras = [camOther];

			//Used to find the final positions after tweens
			//trace("text y: " + checkSubtitlesOptionText);
			//trace("textBG y: " + checkSubtitlesOptionTextBG);

			add(checkSubtitlesOptionTextBG);
			add(checkSubtitlesOptionText);
		}

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		var leSong:String = Paths.formatToSongPath(SONG.song);
		switch (leSong)
		{
			case "bad-battle" | "bad-battle-hotfix" | "intervention" | "friendship" | "friendship-v2":
				PauseSubState.songName = 'ramirez-week-pause';
		}

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(ClientPrefs.getPauseMusic(), 'music');
		}
		
		precacheList.set('alphabet', 'image');
	
		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if (Paths.formatToSongPath(SONG.song) == 'tutorial')
			camZooming = false;

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		callOnLuas('onCreatePost', []);

		super.create();

		cacheCountdown();
		cachePopUpScore();
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
		Paths.clearUnusedMemory();
		
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.shaders) return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.getPreloadPath('shaders/')]; 

		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

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

	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			if(opponentVocals != null) opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		trace('Anim speed: ' + FlxAnimationController.globalSpeed);
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
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
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);
		if(Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
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
		#if (VIDEOS_ALLOWED && hxCodec)
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

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
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

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		introAssets.set('default', ['ready', 'set', 'go']);
		introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

		var introAlts:Array<String> = introAssets.get('default');
		if (isPixelStage) introAlts = introAssets.get('pixel');
		
		for (asset in introAlts)
			Paths.image(asset);
		
		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', [], false);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
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

			if (gf != null)
				gf.danceOnBeatsOnCountdown = gf.getIdleCountOnCountdown(SONG.bpm);
			boyfriend.danceOnBeatsOnCountdown = boyfriend.getIdleCountOnCountdown(SONG.bpm);
			dad.danceOnBeatsOnCountdown = dad.getIdleCountOnCountdown(SONG.bpm);

			var gfDanceOnBeatsTotal:Int = 0;
			gfDanceOnBeatsTotal = gf.danceOnBeatsOnCountdown * 2;

			var bfDanceOnBeatsTotal:Int = 0;
			bfDanceOnBeatsTotal = boyfriend.danceOnBeatsOnCountdown * 2;
			
			var dadDanceOnBeatsTotal:Int = 0;
			dadDanceOnBeatsTotal = dad.danceOnBeatsOnCountdown * 2;

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned && !gf.specialAnim && !gf.danceAfterAnim)
				{
					if (gf.danceIdle)
					{
						if (tmr.loopsLeft % 2 == 0)
							gf.playAnim('danceLeft' + gf.idleSuffix, true);
						else if (tmr.loopsLeft % 2 == 1)
							gf.playAnim('danceRight' + gf.idleSuffix, true);
					}
					else
					{
						if (tmr.loopsLeft % gf.danceOnBeatsOnCountdown == 0)
							gf.playAnim('idle' + gf.idleSuffix, true);
					}
				}
				if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned && !boyfriend.specialAnim && !boyfriend.danceAfterAnim)
				{
					if (boyfriend.danceIdle)
					{
						if (boyfriend.curCharacter.startsWith('gf'))
						{
							if (tmr.loopsLeft % 2 == 1)
								boyfriend.playAnim('danceLeft' + boyfriend.idleSuffix, true);
							else if (tmr.loopsLeft % 2 == 0)
								boyfriend.playAnim('danceRight' + boyfriend.idleSuffix, true);
						}
						else
						{
							if (tmr.loopsLeft % bfDanceOnBeatsTotal == boyfriend.danceOnBeatsOnCountdown)
								boyfriend.playAnim('danceLeft' + boyfriend.idleSuffix, true);
							else if (tmr.loopsLeft % bfDanceOnBeatsTotal == 0)
								boyfriend.playAnim('danceRight' + boyfriend.idleSuffix, true);
						}
					}
					else
					{
						if (tmr.loopsLeft % boyfriend.danceOnBeatsOnCountdown == 0)
							boyfriend.playAnim('idle' + boyfriend.idleSuffix, true);
					}
				}
				if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned && !dad.specialAnim && !dad.danceAfterAnim)
				{
					if (dad.danceIdle)
					{
						if (dad.curCharacter.startsWith('gf'))
						{
							if (tmr.loopsLeft % 2 == 0)
								dad.playAnim('danceLeft' + dad.idleSuffix, true);
							else if (tmr.loopsLeft % 2 == 1)
								dad.playAnim('danceRight' + dad.idleSuffix, true);
						}
						else
						{
							if (tmr.loopsLeft % dadDanceOnBeatsTotal == 0)
								dad.playAnim('danceLeft' + dad.idleSuffix, true);
							else if (tmr.loopsLeft % dadDanceOnBeatsTotal == dad.danceOnBeatsOnCountdown)
								dad.playAnim('danceRight' + dad.idleSuffix, true);
						}
					}
					else
					{
						if (tmr.loopsLeft % dad.danceOnBeatsOnCountdown == 0)
							dad.playAnim('idle' + dad.idleSuffix, true);
					}
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if (curStage == "Stage-Drk") {
					if (ara != null)
						ara.dance(true);

					if (dono != null)
						dono.dance(true);
				}

					switch (swagCounter)
					{
						case 0:
							FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						case 1:
							countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
							countdownReady.cameras = [camCountdown];
							countdownReady.scrollFactor.set();
							countdownReady.updateHitbox();

							if (PlayState.isPixelStage)
								countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

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
							countdownSet.cameras = [camCountdown];
							countdownSet.scrollFactor.set();

							if (PlayState.isPixelStage)
								countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

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
							countdownGo.cameras = [camCountdown];
							countdownGo.scrollFactor.set();

							if (PlayState.isPixelStage)
								countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

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

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = (visualsOnlyMode ? 0 : note.multAlpha);
						if(ClientPrefs.middleScroll && !note.mustPress) {
							note.alpha *= (visualsOnlyMode ? 0 : 0.35);
						}
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	function doCustomCountdown(img:String/*, sound:String*/)
	{
	    var spr = new FlxSprite().loadGraphic(Paths.image(img));
	    spr.scrollFactor.set();
	    spr.screenCenter();
	    spr.antialiasing = ClientPrefs.globalAntialiasing;
	    spr.cameras = [camCountdown];
	    spr.alpha = 1;
	    add(spr);

	    FlxTween.tween(spr, {alpha: 0}, Conductor.crochet / 1000, {
	        ease: FlxEase.cubeInOut,
	        onComplete: function(twn:FlxTween)
	        {
	            remove(spr);
	            spr.destroy();
	        }
	    });

	    //FlxG.sound.play(Paths.sound(sound), 0.6);
	}

	public function addBehindGF(obj:FlxObject)
		insert(members.indexOf(gfGroup), obj);
	public function addBehindBF(obj:FlxObject)
		insert(members.indexOf(boyfriendGroup), obj);
	public function addBehindDad(obj:FlxObject)
		insert(members.indexOf(dadGroup), obj);

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

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function updateScore(miss:Bool = false)
	{
		scoreTxt.text = 'Score: ' + songScore
		+ ' | Misses: ' + songMisses
		+ ' | Rating: ' + ratingName
		+ (ratingName != '?' ? ' (${Highscore.floorDecimal(ratingPercent * 100, 2)}%) - $ratingFC' : '');

		if(ClientPrefs.scoreZoom && !miss && !cpuControlled)
		{
			if(scoreTxtTween != null) {
				scoreTxtTween.cancel();
			}
			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween) {
					scoreTxtTween = null;
				}
			});
		}
		callOnLuas('onUpdateScore', [miss]);
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();

		if (Conductor.songPosition <= opponentVocals.length)
		{
			opponentVocals.time = time;
			opponentVocals.pitch = playbackRate;
		}
		opponentVocals.play();
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

	var authorInfoPrefix:String = "Song by: ";
	var authorInfo:String = "";
	var zRamirezAsMainComposer:String = "zRamírez & DrkFon376";
	var drkfonAsMainComposer:String = "DrkFon376 & zRamírez";
	var zRamirezAsSoleComposer:String = "zRamírez";
	var drkfonAsSoleComposer:String = "DrkFon376";

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, PlayState.SONG.props.instPrefix, PlayState.SONG.props.instSuffix), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = onSongComplete.bind();
		vocals.play();
		opponentVocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		final daSongName:String = Paths.formatToSongPath(SONG.song);
		switch (daSongName)
		{
			case "tutorial":
				authorInfo = "Kawai-Sprite";
			case "bad-battle" | "bad-battle-hotfix" | "bad-battle-classic":
				authorInfo = zRamirezAsMainComposer;
			case "intervention" | "intervention-classic":
				authorInfo = drkfonAsMainComposer;
			case "friendship" | "bad-battle-pico" | "last-smile":
				authorInfo = zRamirezAsSoleComposer;			
			case "friendship-v2":
				authorInfo = drkfonAsMainComposer;
			case "override":
				authorInfo = drkfonAsSoleComposer;
			default:
				authorInfo = zRamirezAsSoleComposer;
		}

		if (daSongName == 'bad-battle' && storyDifficulty == 2)
		{
			authorInfo = "zRamírez, DrkFon376 & ElPatoFNF";
			SongInfo.customSongTitle = "Bad Battle Fucked";
		}
		else if (daSongName == 'bad-battle-pico') SongInfo.customJukeBoxTagColor = "FD6922";

		songInfo = new SongInfo(-360, 0, SONG.song, authorInfoPrefix + authorInfo);
		songInfo.cameras = [camOther];
		add(songInfo);

		if (songInfo != null)
			songInfo.start();

		if (checkSubtitlesOptionText != null && checkSubtitlesOptionTextBG != null)
		{
			if (isStoryMode && daSongName == "bad-battle" && !FlxG.save.data.enteredVisualsOptions)
				startCheckSubtitlesOptionText();
		}

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) / playbackRate;
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1) / playbackRate;
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		SongInfo.customSongTitle = "";
		SongInfo.daAuthorInfo = "";
		SongInfo.customJukeBoxTagColor = "";
		SongInfo.disabled = false;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();

        try
        {
            if (SONG.needsVoices)
            {
                var playerVocals:openfl.media.Sound = cast Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile, PlayState.SONG.props.vocalPrefix, PlayState.SONG.props.vocalSuffix);
				var normalVocals:openfl.media.Sound = Paths.voices(songData.song, null, PlayState.SONG.props.vocalPrefix, PlayState.SONG.props.vocalSuffix);
				if (playerVocals != null && playerVocals.length > 0) vocals.loadEmbedded(playerVocals);
                else if (normalVocals != null && normalVocals.length > 0) vocals.loadEmbedded(normalVocals);
                
                var oppVocals:openfl.media.Sound = cast Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile, PlayState.SONG.props.vocalPrefix, PlayState.SONG.props.vocalSuffix);
                if(oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
            }
        }
        catch(e:haxe.Exception)
              trace(e.message + e.stack);

		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song, PlayState.SONG.props.instPrefix, PlayState.SONG.props.instSuffix)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		var file2:String = Paths.json(songName + '/cam-events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/cam-events')) || FileSystem.exists(file2)) {
		#else
		if (OpenFlAssets.exists(file2)) {
		#end
			var camEventsData:Array<Dynamic> = Song.loadFromJson('cam-events', songName).events;
			for (event in camEventsData) //An optional extra json to separately read Add Camera Zoom events or others if you want
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

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
				unspawnNotes.push(swagNote);

				var roundSus:Int = Math.round(susLength);
				if(roundSus > 0) {
					for (susNote in 0...roundSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
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
							if (daNoteData > 1) //Up and Right 
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress) swagNote.x += FlxG.width / 2; // general offset
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
						swagNote.x += FlxG.width / 2 + 25;
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnLuas('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = visualsOnlyMode ? 0 : 1;

			if (!visualsOnlyMode && player < 1)
				targetAlpha = !ClientPrefs.opponentStrums ? 0 : ClientPrefs.middleScroll ? 0.35 : 1;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else babyArrow.alpha = targetAlpha;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
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
				opponentVocals.pause();
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

	public var canResync:Bool = true;
	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong && canResync)
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

			for (tween in modchartTweens)
				tween.active = true;
			for (timer in modchartTimers)
				timer.active = true;
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
		opponentVocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();

		if (Conductor.songPosition <= opponentVocals.length)
		{
			opponentVocals.time = Conductor.songPosition;
			opponentVocals.pitch = playbackRate;
		}
		opponentVocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/
		callOnLuas('onUpdate', [elapsed]);
		healthLerp = FlxMath.lerp(health, healthLerp, Math.exp(-elapsed * 9 * playbackRate));

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
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

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', [], false);
			if(ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = FlxMath.lerp(healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset, iconP1.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.x = FlxMath.lerp(healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2, iconP2.x, Math.exp(-elapsed * 9 * playbackRate));

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			canResync = false;
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}
		
		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (Conductor.songPosition >= FlxG.sound.music.length){ //Because using "oncomplete" for music doesn't work when changing pitch? idfk
			onSongComplete(); //BRO WHAT THE FUCK, I SWEAR ON MY LIFE I HAD ALREADY PUT THIS LINE, anyways, here it is again lmao -Drkfon
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
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
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("secShit", curSection);
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
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned=true;
				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.danceOnce();
					//boyfriend.animation.curAnim.finish();
				}

				if (notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						var i:Int = 0;
						while(i < notes.length)
						{
							var daNote:Note = notes.members[i];
							if(daNote == null) continue;

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
								daNote.alpha = (visualsOnlyMode ? 0 : strumAlpha);

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

							if(!daNote.blockHit && daNote.mustPress && cpuControlled && daNote.canBeHit) {
								if(daNote.isSustainNote) {
									if(daNote.canBeHit) {
										goodNoteHit(daNote);
									}
								} else if(daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
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

								daNote.kill();
								notes.remove(daNote, true);
								daNote.destroy();
							}
							if(daNote.exists) i++;
						}
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
			playerHoldCovers.updateHold(elapsed, true);
   			opponentHoldCovers.updateHold(elapsed, true);
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
	}

	function openPauseMenu()
	{
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		// 1 / 1000 chance for Gitaroo Man easter egg
		/*if (FlxG.random.bool(0.1))
		{
			// gitaroo man easter egg
			cancelMusicFadeTween();
			MusicBeatState.switchState(new GitarooPause());
		}
		else {*/
		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		//}

		#if desktop
		DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		canResync = false;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;
				canResync = false;

				vocals.stop();
				opponentVocals.stop();
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

	function startCheckSubtitlesOptionText()
	{
		PlayState.instance.modchartTweens.set("checkSubtitlesOptionTextTween", FlxTween.tween(checkSubtitlesOptionText, {y: 650}, 2, {ease: FlxEase.quintInOut, startDelay: 0.8, onComplete: function(twn:FlxTween){
			PlayState.instance.modchartTweens.set("checkSubtitlesOptionTextTweenPart2", FlxTween.tween(checkSubtitlesOptionText, {y: FlxG.height + 300}, 2, {ease: FlxEase.quintInOut, startDelay: 2.5, onComplete: function(twn:FlxTween){ 
				checkSubtitlesOptionText.destroy(); 
			}}));
		}}));

		PlayState.instance.modchartTweens.set("checkSubtitlesOptionTextBGTween", FlxTween.tween(checkSubtitlesOptionTextBG, {y: 635.8}, 2, {ease: FlxEase.quintInOut, startDelay: 0.8, onComplete: function(twn:FlxTween){
			PlayState.instance.modchartTweens.set("checkSubtitlesOptionTextBGTweenPart2", FlxTween.tween(checkSubtitlesOptionTextBG, {y: FlxG.height + 285.8}, 2, {ease: FlxEase.quintInOut, startDelay: 2.5, onComplete: function(twn:FlxTween){ 
				checkSubtitlesOptionTextBG.destroy(); 
			}}));
		}}));
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 3;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
					case 'dad'| 'opponent' | '2':
						value = 2;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				switch (value)
				{
					case 0:
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = time;
					case 1:
						if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						} else if (gf != null) {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
	
					case 2:
						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					default:
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = time;

						if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						} else if (gf != null) {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
	

						dad.playAnim('hey', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
				}

			case 'Set GF Speed': //I removed it cuz it's basically now useless due to the new event I just created called 'Set Character Idle Speed'
				trace("ANNULLED, USE 'Set Character Idle Speed' INSTEAD"); //But now that I think about it I'm not going to remove it completely, I'll just remove the code from its operation
				FlxG.log.warn("WARNING: This does nothing now, use 'Set Character Idle Speed' instead");
				/*var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;*/

			case 'Set Character Idle Speed':
				var charType:Int = 0;
				var MIARREGLO:Array<String> = value1.split(',');

				switch(MIARREGLO[0].toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						charType = 0;
					case 'dad' | 'opponent':
						charType = 1;
					case 'gf' | 'girlfriend':
						charType = 2;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType))
							charType = 0;
				}

				var beatIntValue = Std.parseInt(value2.toLowerCase().trim());
				switch (charType)
				{
					case 0:
						bfIdleisHalfBeat = (value2.toLowerCase().trim() == '0.5');

						if (!bfIdleisHalfBeat)
						{
							if (beatIntValue > 0 && (beatIntValue & (beatIntValue - 1)) == 0) //If the value entered is not part of the power of 2 (such as 1, 2, 4, 8, 16, 32, etc.) the event is completely ignored
							{
								bfIdleInt = beatIntValue * 4;
								bfIdleSpeedChanged = true;
							}
						}
						else
						{
							bfIdleInt = 2;
							bfIdleSpeedChanged = true;
						}

						switch(MIARREGLO[1].toLowerCase().trim())
						{
							case 'true' | '1' | 'si':
								bfInvertIdleDirection = true;
							case 'false' | '0' | 'no' | '':
								bfInvertIdleDirection = false;
						}

					case 1:
						dadIdleisHalfBeat = (value2.toLowerCase().trim() == '0.5');

						if (!dadIdleisHalfBeat)
						{
							if (beatIntValue > 0 && (beatIntValue & (beatIntValue - 1)) == 0) //If the value entered is not part of the power of 2 (such as 1, 2, 4, 8, 16, 32, etc.) the event is completely ignored
							{
								dadIdleInt = beatIntValue * 4;
								dadIdleSpeedChanged = true;
							}
						}
						else
						{
							dadIdleInt = 2;
							dadIdleSpeedChanged = true;
						}

						switch(MIARREGLO[1].toLowerCase().trim())
						{
							case 'true' | '1' | 'si':
								dadInvertIdleDirection = true;
							case 'false' | '0' | 'no' | '':
								dadInvertIdleDirection = false;
						}

					case 2:
						gfIdleisHalfBeat = (value2.toLowerCase().trim() == '0.5');
						if (!gfIdleisHalfBeat)
						{
							if (beatIntValue > 0 && (beatIntValue & (beatIntValue - 1)) == 0) //If the value entered is not part of the power of 2 (such as 1, 2, 4, 8, 16, 32, etc.) the event is completely ignored
							{
								gfIdleInt = beatIntValue * 4;
								gfIdleSpeedChanged = true;
								//isGfIdleByBPM = false;
							}
						}
						else
						{
							gfIdleInt = 2;
							gfIdleSpeedChanged = true;
							//isGfIdleByBPM = false;
						}

						switch(MIARREGLO[1].toLowerCase().trim())
						{
							case 'true' | '1' | 'si':
								gfInvertIdleDirection = true;
							case 'false' | '0' | 'no' | '':
								gfInvertIdleDirection = false;
						}
				}

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && (songName == "intervention" ? FlxG.camera.zoom < 2 : FlxG.camera.zoom < 1.35)) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Change Stage':
				final value:String = value1.toLowerCase().trim();
				var newItems:Bool = false;
				var oldItems:Bool = false;
				switch (value) {
					case 'new' | 'nuevo' | 'nueva' | '0': newItems = true;
					case 'old' | 'viejo' | 'vieja' | '1': oldItems = true;
				}

				for (sprite in [stageBack, stageFront, mueble, stageBackOLD, stageFrontOLD, muebleOLD])
				{
					if (sprite == null) continue;
					final newSprite:Bool = (sprite == stageBack || sprite == stageFront || sprite == mueble);
					sprite.visible = newSprite ? newItems : oldItems;
				}
				if (!ClientPrefs.lowQuality)
				{
					for (sprite in [adornos, extra, luzChanger, adornosOLD, extraOLD])
					{
						if (sprite == null) continue;
						final newSprite:Bool = (sprite == adornos || sprite == extra || sprite == luzChanger);
						sprite.visible = newSprite ? newItems : oldItems;
					}
				}

			case 'Flash Camera':
				if(ClientPrefs.flashing)
				{
					var duration:Float = Std.parseFloat(value1.trim());
					var value2Array:Array<String> = value2.split(',');
					var color:String = value2Array[0].toUpperCase().trim();
					var cameraTarget:String = value2Array[1].trim();

					if (Math.isNaN(duration))
						duration = 1;
					
					if (color == "")
						color = 'FFFFFF';

					var colorNum:Int = Std.parseInt(color);
       				if (!color.startsWith('0x'))
						colorNum = Std.parseInt('0xFF' + color);

					//trace("Flashing the camera '" + cameraTarget + "' with the color " + colorNum + ", and a duration of " + duration + " second" + (duration == 1 ? "" : "s"));

					cameraFromString(cameraTarget).flash(colorNum, duration, null, true);
				}

			case 'Invert Scroll Direction':
				originalScroll = !originalScroll;
				var isDownscroll = originalScroll;

				healthBarBG.y = isDownscroll ? 0.11 * FlxG.height : 0.89 * FlxG.height;
				healthBar.y = healthBarBG.y + 4;
				iconP1.y = healthBar.y - 75;
    			iconP2.y = healthBar.y - 75;
				scoreTxt.y = healthBarBG.y + 36;
				timeTxt.y = isDownscroll ? FlxG.height - 44 : 19;
				timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
				timeBar.y = timeBarBG.y + 4;
				botplayTxt.y = isDownscroll ? timeBarBG.y - 78 : timeBarBG.y + 55;

				var strumY:Float = isDownscroll ? (FlxG.height - 150) : 50;

				for (i in 0...opponentStrums.length)
    			{
    			    var strum = opponentStrums.members[i];
     				strum.y = strumY;
        			strum.downScroll = isDownscroll;
    			}

				for (i in 0...playerStrums.length)
    			{
    			    var strum = playerStrums.members[i];
    			    strum.y = strumY;
    			    strum.downScroll = isDownscroll;
    			}

				for (note in notes)
    			{
    			    if (note.isSustainNote && note.prevNote != null)
    			    {
    			        note.flipY = isDownscroll;
    			    }
    			}
			
    			for (note in unspawnNotes)
    			{
    			    if (note.isSustainNote && note.prevNote != null)
    			    {
    			        note.flipY = isDownscroll;
    			    }
    			}

				callOnLuas('clearOriginalYPositions', []);

			case 'Move Camera When Singing':
				var value:Float = Std.parseFloat(value2);
				value1 = value1.toLowerCase().trim();
				if (value1.length > 0) moveCameraWhenSingingBool = (value1 == 'true' || value1 == '1');
				cameraOffsetWhenSingingValue = (moveCameraWhenSingingBool ? (Math.isNaN(value) ? 25 : Math.abs(value)) : 0);
				
			case 'Alarm Gradient':
				if(ClientPrefs.flashing && !ClientPrefs.lowQuality){
					//Value 1  = which side
					//Value 2 = alpha to fade to
					var targetAlpha:Float = Std.parseFloat(value2);
					if(Math.isNaN(targetAlpha)) targetAlpha = 0;

					if(value1.toLowerCase()=="left"){
						//hazardBGashley is gradient flipped
						var modchartTweenTag:String = 'hazAlarmLeft';
						instance.modchartTweens.set(modchartTweenTag, FlxTween.tween(hazardAlarmLeft, {alpha:targetAlpha}, 0.25, {
							ease: FlxEase.quartOut,
							onComplete: function(twn:FlxTween)
							{
								FlxTween.tween(hazardAlarmLeft, {alpha: 0}, 0.36, {ease: FlxEase.cubeOut});
								instance.modchartTweens.remove(modchartTweenTag);
							}
						}));
					}else if(value1.toLowerCase()=="right"){
						//hazardBGblank is gradient
						var modchartTweenTag:String = 'hazAlarmRight';
						instance.modchartTweens.set(modchartTweenTag, FlxTween.tween(hazardAlarmRight, {alpha:targetAlpha}, 0.25, {
							ease: FlxEase.quartOut,
							onComplete: function(twn:FlxTween)
							{
								FlxTween.tween(hazardAlarmRight, {alpha: 0}, 0.36, {ease: FlxEase.cubeOut});
								instance.modchartTweens.remove(modchartTweenTag);
							}
						}));
					}else{
						FlxG.log.warn('Value 1 for alarm has to either be "right" or "left"');
					}
				}

			case 'Bad Battle Countdown':
    			switch (value1.toLowerCase().trim())
    			{
    			    case '3' | 'three':
    			        doCustomCountdown('counter/three'/*, 'intro3'*/);
    			    case '2' | 'two':
    			        doCustomCountdown('counter/two'/*, 'intro2'*/);
    			    case '1' | 'one':
    			        doCustomCountdown('counter/one'/*, 'intro1'*/);
    			    case '0' | 'go':
    			        doCustomCountdown('counter/go'/*, 'introGo'*/);
    			}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);
					if(Math.isNaN(val1)) val1 = 0;
					if(Math.isNaN(val2)) val2 = 0;

					isCameraOnForcedPos = false;
					if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
						camFollow.x = val1;
						camFollow.y = val2;
						camFollowReal.x = val1;
						camFollowReal.y = val2;
						isCameraOnForcedPos = true;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Overlay Alpha Fade': //Cool fadeOut | fadeIn effect for camGame or camHUD
				var value1Array:Array<String> = value1.split(','); //Splitting value 1: the first value is the fade type which should be fadeOut or fadeIn, and the second value is the camera target which should be 'camGame' or 'camHUD'
				var value2Array:Array<String> = value2.split(','); //Splitting value 2: the first value is the time in which the fade should be completed, and the second value is the ease it should have, by default the ease is 'linear'
				var leValue:Bool = true;
				var isTargetCamGame:Bool = true;

				if (value1Array[0].toLowerCase().trim() == "fadeout" || value1Array[0] == "0")
					leValue = true;
				if (value1Array[0].toLowerCase().trim() == "fadein" || value1Array[0] == "1")
					leValue = false;

				var cameraTarget:String = value1Array[1].toLowerCase().trim();
				if (cameraTarget == 'camgame' || cameraTarget == "")
					isTargetCamGame = true;
				else if (cameraTarget == 'camhud')
					isTargetCamGame = false;
				else
					FlxG.log.warn('Camera target has to either be camGame or camHUD');

				var targetTime:Float = Std.parseFloat(value2Array[0].trim());
				if (Math.isNaN(targetTime) || targetTime <= 0)
					targetTime = 0.001;

				var targetOverlay = isTargetCamGame ? blackOverlayCamGame : blackOverlayCamHUD;
				var tweenKeyShit:String = "overlay" + (isTargetCamGame ? "CamGame" : "CamHUD") + "Fade" + (leValue ? "Out" : "In");

				if ((isTargetCamGame && blackOverlayCamGame != null) || (!isTargetCamGame && blackOverlayCamHUD != null))
					instance.modchartTweens.set(tweenKeyShit, FlxTween.tween(targetOverlay, {alpha: (leValue ? 0 : 1)}, targetTime / playbackRate, {ease: getFlxEaseByString(value2Array[1]), onComplete: function(twn:FlxTween) instance.modchartTweens.remove(tweenKeyShit)}));

			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if (gf != null && gf.curCharacter != value2)
						{
							if(!gfMap.exists(value2))
								addCharacterToList(value2, charType);

							var lastAlpha:Float = gf.alpha;
							gf.alpha = 0.00001;
							gf = gfMap.get(value2);
							gf.alpha = lastAlpha;
						}
						setOnLuas('gfName', gf.curCharacter);
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
					songSpeed = newValue;
				else
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete: function (twn:FlxTween) songSpeedTween = null});

			case 'Set Property':
				var killMe:Array<String> = value1.split('.');
				if(killMe.length > 1)
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length-1], value2);
				else
					FunkinLua.setVarInArray(this, value1, value2);
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	//Stolen from FunkinLua lol
	function getFlxEaseByString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	//Again stolen from FunkinLua lmao
	function cameraFromString(cam:String):FlxCamera {
		switch(cam.toLowerCase()) {
			case 'camgameoverlay' | 'camoverlay' | 'overlay':
				return camGameOverlay;
			case 'camhud' | 'hud':
				return camHUD;
			case 'camcountdown' | 'countdown':
				return camCountdown;
			case 'camother' | 'other':
				return camOther;
			default:
				return camGame;
		}
	}

	function moveCameraSection():Void {
		if(SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
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

			switch (curStage)
			{
				#if covers_build
				case 'crossroads':
					camFollow.x = boyfriend.getMidpoint().x - 200;
				#end
			}

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

	public function moveCameraWhenSinging(isDad:Bool, ?isGf:Bool = false)
	{
		if (isCameraOnForcedPos)
			camFollow.set(camFollowReal.x + cameraOffsetWhenSinging[0], camFollowReal.y + cameraOffsetWhenSinging[1]);
		else
		{
			if (isGf && gf != null && SONG.notes[curSection].gfSection)
			{
				camFollow.set(gf.getMidpoint().x + cameraOffsetWhenSinging[0], gf.getMidpoint().y + cameraOffsetWhenSinging[1]);
				camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
				camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			}
			else if(isDad)
			{
				camFollow.set(dad.getMidpoint().x + 150 + cameraOffsetWhenSinging[0], dad.getMidpoint().y - 100 + cameraOffsetWhenSinging[1]);
				camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
				camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			}
			else
			{
				camFollow.set(boyfriend.getMidpoint().x - 100 + cameraOffsetWhenSinging[0], boyfriend.getMidpoint().y - 100 + cameraOffsetWhenSinging[1]);
				camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
				camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
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

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		opponentVocals.volume = 0;
		vocals.pause();
		opponentVocals.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}

	//Stolen from Haz again lmaoo
	private var songCompletedAlready:Bool = false;
	//FUCK FUCK FUCK FUCK FUCK FUCK FUCK FUCK FUCK FUCK FUCK FUCK FUCK
	private function onSongComplete()
	{
		if (songCompletedAlready)
		{
			trace("song already completed lmao");
			return;
		}
		else
		{
			trace("onSongComplete");
			songCompletedAlready = true;
			finishSong(false);
		}
	}

	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		checkForAchievement([WeekData.getWeekFileName() + '_nomiss', 'bb_ara', 'zweek_beat', 'bb_fucked', 'dweek_beat', 'gopico_yeah', 'taunt_master', 'friendship_v2', 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie' #if BASE_GAME_FILES, 'debugger' #end]);
		#end
		if(callOnLuas('onEndSong', [], false) != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('zRamirezMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					canResync = false;
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

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

					canResync = false;
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
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if (FlxTransitionableState.skipNextTransIn) CustomFadeTransition.nextCamera = null;
				canResync = false;
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('zRamirezMenu'));
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

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function cachePopUpScore()
	{
		var pixelShitPart1:String = '';
		var pixelShitPart2:String = '';
		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		Paths.image(pixelShitPart1 + "sick" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "good" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "bad" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "shit" + pixelShitPart2);
		Paths.image(pixelShitPart1 + "combo" + pixelShitPart2);
		
		for (i in 0...10) {
			Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
		}
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;
		opponentVocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(note, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.increase();
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
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

		if (!cpuControlled && !ClientPrefs.disablePopUp)
		{
			rating.loadGraphic(Paths.image(pixelShitPart1 + daRating.image + pixelShitPart2));
			rating.cameras = [camHUD];
			rating.screenCenter();
			rating.x = coolText.x - 40;
			rating.y -= 60;
			rating.acceleration.y = 550 * playbackRate * playbackRate;
			rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
			rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
			rating.visible = (!ClientPrefs.hideHud && showRating && !visualsOnlyMode);
			rating.x += ClientPrefs.comboOffset[0];
			rating.y -= ClientPrefs.comboOffset[1];

			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
			comboSpr.cameras = [camHUD];
			comboSpr.screenCenter();
			comboSpr.x = coolText.x;
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.visible = (!ClientPrefs.hideHud && showCombo && !visualsOnlyMode);
			comboSpr.x += ClientPrefs.comboOffset[0];
			comboSpr.y -= ClientPrefs.comboOffset[1];
			comboSpr.y += 60;
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

			insert(members.indexOf(strumLineNotes), rating);
		
			if (!ClientPrefs.comboStacking)
			{
				if (lastRating != null) lastRating.kill();
				lastRating = rating;
			}

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
			var xThing:Float = 0;
			if (showCombo)
			{
				insert(members.indexOf(strumLineNotes), comboSpr);
			}
			if (!ClientPrefs.comboStacking)
			{
				if (lastCombo != null) lastCombo.kill();
				lastCombo = comboSpr;
			}
			if (lastScore != null)
			{
				while (lastScore.length > 0)
				{
					lastScore[0].kill();
					lastScore.remove(lastScore[0]);
				}
			}
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
				numScore.cameras = [camHUD];
				numScore.screenCenter();
				numScore.x = coolText.x + (43 * daLoop) - 90;
				numScore.y += 80;

				numScore.x += ClientPrefs.comboOffset[2];
				numScore.y -= ClientPrefs.comboOffset[3];
			
				if (!ClientPrefs.comboStacking)
					lastScore.push(numScore);

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

				numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
				numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
				numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
				numScore.visible = (!ClientPrefs.hideHud && !visualsOnlyMode);

				//if (combo >= 10 || combo == 0)
				if(showComboNum)
					insert(members.indexOf(strumLineNotes), numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002 / playbackRate
				});

				daLoop++;
				if(numScore.x > xThing) xThing = numScore.x;
			}
			comboSpr.x = xThing + 50;
			/*
				trace(combo);
				trace(seperatedScore);
			 */

			coolText.text = Std.string(seperatedScore);
			// add(coolText);

			FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
				startDelay: Conductor.crochet * 0.001 / playbackRate
			});

			FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					coolText.destroy();
					comboSpr.destroy();

					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
		}

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		if (combo >= heyComboInterval && combo % heyComboInterval == 0 && combo != lastHeyCombo && gf.animOffsets.exists('cheer') && !chartingMode && !cpuControlled && !usedPractice)
		{
    		if (gf != null)
        	gf.playAnim('cheer', true);
			gf.specialAnim = true;
    
    		lastHeyCombo = combo;
		}
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
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
			if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
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

			if (playerHoldCovers != null && playerHoldCovers.members[key].animation.curAnim != null && !playerHoldCovers.members[key].animation.curAnim.name.endsWith('p')) //De nada glow
				playerHoldCovers.despawnOnMiss(strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong, key);

		//trace('released: ' + controlArray);
		}
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

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) {
					goodNoteHit(daNote);
				}
			});

			if(FlxG.keys.anyJustPressed(tauntKey) && !parsedHoldArray.contains(true) && !boyfriend.animation.curAnim.name.startsWith('sing') && boyfriend.specialAnim == false){
				boyfriend.playAnim('hey', true);
				boyfriend.specialAnim = true;
				boyfriend.heyTimer = 0.59;
				FlxG.sound.play(Paths.sound('hey'), 0.75);
				tauntCounter++; //Maybe will use this later lol //It's time
				trace("taunts: " + tauntCounter);
			}

			/*if (parsedHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else*/ if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.danceOnce();
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if(parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if(parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
		{
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}
		return ret;
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		if (!boyfriend.stunned)
		{
			if (combo > 10 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
				trace('You really hurts GF :(');
			}
		}
		combo = 0;
		health -= daNote.missHealth * healthLoss;
		
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating(true);

		var altAnim:String = daNote.animSuffix;

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		if (SONG.notes[curSection] != null) {
			if (SONG.notes[curSection].altAnimBF)
				altAnim = '-alt';
		}

		if(char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss';
			char.playAnim(animToPlay + altAnim, true);
		}
		if (daNote != null)
		{
			playerHoldCovers.despawnOnMiss(strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong, daNote.noteData, daNote);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.ghostTapping) return; //fuck it

		playerHoldCovers.despawnOnMiss(strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong, direction);

		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if (combo > 10 && gf != null && gf.animOffsets.exists('sad') && !ClientPrefs.ghostTapping)
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
				trace('You really hurts GF :(');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
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

			var altAnim:String = '';

			if (SONG.notes[curSection] != null) {
				if (SONG.notes[curSection].altAnimBF)
					altAnim = '-alt';
			}

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss' + altAnim, true);
			}
			vocals.volume = 0;
		}
		callOnLuas('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note):Void
	{
		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
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
				
				if (SONG.notes[curSection] != null)
				{
					if (!SONG.notes[curSection].mustHitSection && moveCameraWhenSingingBool)
					{
						if(char.animation.curAnim.name.startsWith('singLEFT'))
						{
							cameraOffsetWhenSinging = [0 - cameraOffsetWhenSingingValue, 0];
							gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(true, true) : moveCameraWhenSinging(true);
						}
						else if(char.animation.curAnim.name.startsWith('singDOWN'))
						{
							cameraOffsetWhenSinging = [0, 0 + cameraOffsetWhenSingingValue];
							gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(true, true) : moveCameraWhenSinging(true);
						}
						else if(char.animation.curAnim.name.startsWith('singUP'))
						{
							cameraOffsetWhenSinging = [0, 0 - cameraOffsetWhenSingingValue];
							gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(true, true) : moveCameraWhenSinging(true);
						}
						else if(char.animation.curAnim.name.startsWith('singRIGHT'))
						{
							cameraOffsetWhenSinging = [0 + cameraOffsetWhenSingingValue, 0];
							gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(true, true) : moveCameraWhenSinging(true);
						}
						else if(char.animation.curAnim.name.startsWith('idle'))
						{
							cameraOffsetWhenSinging = [0, 0];
							gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(true, true) : moveCameraWhenSinging(true);
						}
					}
				}

				char.holdTimer = 0;
			}
		}
		if (note.isSustainNote && (ClientPrefs.disableSustainLoop || forceDisableSustainLoop)) {
    		if (note.gfNote || note.noteType == 'GF Sing') {
        		gf.holdTimer = 0;
    		} else {
        		dad.holdTimer = 0;
    		}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;
			opponentVocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)), time);
		note.hitByOpponent = true;
		opponentHoldCovers.spawnOnNoteHit(note, strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong);

		if (allowedHealthDrainByOpponent) {
			if (CoolUtil.difficulties[storyDifficulty] == 'Fucked')
			{
				if (health > 0.07)
					health -= (note.hitHealth-.003/(note.isSustainNote?1.5:1.6)) * healthGain;
			}
			else
			{
				if (health > 0.01 && health <= 0.66) {
					if (note.isSustainNote) {
						if (healthDrainOnOpponentSustains) {
							health -= 0.0075/1.5;
						} else {
							health -= 0.0075/8;
						}
					} else {
						health -= 0.0075;
					}
				} else if (health > 0.66 && health <= 1.4) {
					if (note.isSustainNote) {
						if (healthDrainOnOpponentSustains) {
							health -= 0.014/1.5;
						} else {
							health -= 0.014/8;
						}
					} else {
						health -= 0.014;
					}
				} else if (health > 1.4 && health <= 2) {
					if (note.isSustainNote) {
						if (healthDrainOnOpponentSustains) {
							health -= 0.023/1.5;
						} else {
							health -= 0.023/8;
						}
					} else {
						health -= 0.03;
					}
				}
			}
		}
		if (!note.isSustainNote)
			spawnNoteSplashOnOppNote(note);

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
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

			if (note.isSustainNote && (ClientPrefs.disableSustainLoop || forceDisableSustainLoop)) {
    			if (note.gfNote || note.noteType == 'GF Sing') {
       		 		gf.holdTimer = 0;
    			} else {
        			boyfriend.holdTimer = 0;
    			}
			}

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
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var altAnim:String = note.animSuffix;

				if (SONG.notes[curSection] != null)
				{
					if (SONG.notes[curSection].altAnimBF) {
						altAnim = '-alt';
					}
				}

				var char:Character = boyfriend;

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;

				//Old code
				/*if(note.gfNote)
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + altAnim, true);
						gf.holdTimer = 0;
					}
				}
				else
				{			
					boyfriend.playAnim(animToPlay + altAnim, true);

					if (SONG.notes[curSection] != null) //MINULL
					{
						if (SONG.notes[curSection].mustHitSection && moveCameraWhenSingingBool)
						{
							if(boyfriend.animation.curAnim.name.startsWith('singLEFT'))
							{
								cameraOffsetWhenSinging = [0 - cameraOffsetWhenSingingValue, 0];
								moveCameraWhenSinging(false);
							}
							else if(boyfriend.animation.curAnim.name.startsWith('singDOWN'))
							{
								cameraOffsetWhenSinging = [0, 0 + cameraOffsetWhenSingingValue];
								moveCameraWhenSinging(false);
							}
							else if(boyfriend.animation.curAnim.name.startsWith('singUP'))
							{
								cameraOffsetWhenSinging = [0, 0 - cameraOffsetWhenSingingValue];
								moveCameraWhenSinging(false);
							}
							else if(boyfriend.animation.curAnim.name.startsWith('singRIGHT'))
							{
								cameraOffsetWhenSinging = [0 + cameraOffsetWhenSingingValue, 0];
								moveCameraWhenSinging(false);
							}
							else if(boyfriend.animation.curAnim.name.startsWith('idle'))
							{
								cameraOffsetWhenSinging = [0, 0];
								moveCameraWhenSinging(false);
							}
						}
					}

					boyfriend.holdTimer = 0;
				}*/

				if(note.gfNote) {
					char = gf;
				}

				if(char != null)
				{
					char.playAnim(animToPlay, true);

					if (SONG.notes[curSection] != null)
					{
						if (SONG.notes[curSection].mustHitSection && moveCameraWhenSingingBool)
						{
							if(char.animation.curAnim.name.startsWith('singLEFT'))
							{
								cameraOffsetWhenSinging = [0 - cameraOffsetWhenSingingValue, 0];
								gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(false, true) : moveCameraWhenSinging(false);
							}
							else if(char.animation.curAnim.name.startsWith('singDOWN'))
							{
								cameraOffsetWhenSinging = [0, 0 + cameraOffsetWhenSingingValue];
								gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(false, true) : moveCameraWhenSinging(false);
							}
							else if(char.animation.curAnim.name.startsWith('singUP'))
							{
								cameraOffsetWhenSinging = [0, 0 - cameraOffsetWhenSingingValue];
								gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(false, true) : moveCameraWhenSinging(false);
							}
							else if(char.animation.curAnim.name.startsWith('singRIGHT'))
							{
								cameraOffsetWhenSinging = [0 + cameraOffsetWhenSingingValue, 0];
								gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(false, true) : moveCameraWhenSinging(false);
							}
							else if(char.animation.curAnim.name.startsWith('idle'))
							{
								cameraOffsetWhenSinging = [0, 0];
								gf != null && SONG.notes[curSection].gfSection ? moveCameraWhenSinging(false, true) : moveCameraWhenSinging(false);
							}
						}
					}

					char.holdTimer = 0;
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
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)), time);
			} else {
				var spr = playerStrums.members[note.noteData];
				if(spr != null)
				{
					spr.playAnim('confirm', true);
				}
			}
			note.wasGoodHit = true;
			playerHoldCovers.spawnOnNoteHit(note, strumLineNotes != null && strumLineNotes.members.length > 0 && !startingSong);
			vocals.volume = 1;
			opponentVocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null && !visualsOnlyMode) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplashOnOppNote(note:Note) {
		if(ClientPrefs.noteSplashes && ClientPrefs.opponentStrums && note != null && !visualsOnlyMode) {
			var strum:StrumNote = opponentStrums.members[note.noteData];
			if(strum != null) {
				spawnOppNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashShit/' + ClientPrefs.splashSkin;
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;
		if (data > -1 && data < ClientPrefs.arrowHSV.length)
		{
			hue = ClientPrefs.arrowHSV[data][0] / 360;
			sat = ClientPrefs.arrowHSV[data][1] / 100;
			brt = ClientPrefs.arrowHSV[data][2] / 100;
			if(note != null) {
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	public function spawnOppNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashShit/' + ClientPrefs.splashSkin;
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = 0;
		var sat:Float = 0;
		var brt:Float = 0;
		if (data > -1 && data < ClientPrefs.arrowHSV.length)
		{
			hue = ClientPrefs.arrowHSV[data][0] / 360;
			sat = ClientPrefs.arrowHSV[data][1] / 100;
			brt = ClientPrefs.arrowHSV[data][2] / 100;
			if(note != null) {
				skin = note.noteSplashTexture;
				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpOpponentNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		splash.alpha = (ClientPrefs.middleScroll ? (visualsOnlyMode ? 0 : 0.35 * ClientPrefs.splashAlpha) : 1 * ClientPrefs.splashAlpha);
		grpOpponentNoteSplashes.add(splash);
	}

	override function destroy() {
		for (lua in luaArray) {
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];

		#if hscript
		if(FunkinLua.hscript != null) FunkinLua.hscript = null;
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;

	var gfIdleSpeedInt:Int = 0; //Ported from QT Extreme 2.5 + added new variables for bf and dad
	var bfIdleSpeedInt:Int = 0;
	var dadIdleSpeedInt:Int = 0;

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate))
			|| (SONG.needsVoices && Math.abs(opponentVocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		//if (!isGfIdleByBPM) //Shit that I was testing and I finally discarded lol
			//gfIdleInt = recalculateIdleInt(SONG.bpm);

		gfIdleSpeedInt = gfIdleInt * 2;
		bfIdleSpeedInt = bfIdleInt * 2;
		dadIdleSpeedInt = dadIdleInt * 2;
		
		if (gf != null && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned && !gf.specialAnim && !gf.danceAfterAnim)
		{
			if (gf.danceIdle)
			{
				if (!gfIdleSpeedChanged)
				{
					if (curStep % 8 == 0) //Bpm doesn't directly affect gf's idle speed when she has 'danceLeft' and 'danceRight' animations
						gf.playAnim((gfInvertIdleDirection ? 'danceRight' : 'danceLeft') + gf.idleSuffix, true);
					else if (curStep % 8 == 4)
						gf.playAnim((gfInvertIdleDirection ? 'danceLeft' : 'danceRight') + gf.idleSuffix, true);
				}
				else
				{
					if (curStep % gfIdleSpeedInt == 0)
						gf.playAnim((gfInvertIdleDirection ? 'danceRight' : 'danceLeft') + gf.idleSuffix, true);
					else if (curStep % gfIdleSpeedInt == gfIdleInt)
						gf.playAnim((gfInvertIdleDirection ? 'danceLeft' : 'danceRight') + gf.idleSuffix, true);
				}
			}
			else
			{
				if (curStep % (gfIdleisHalfBeat ? 2 : gfIdleInt) == 0)
					gf.playAnim('idle' + gf.idleSuffix, true);
			}
		}
		if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned && !boyfriend.specialAnim && !boyfriend.danceAfterAnim)
		{
			if (boyfriend.danceIdle)
			{
				if (boyfriend.curCharacter.startsWith('gf') && !bfIdleSpeedChanged) //gf as bf? lmao
				{
					if (curStep % 8 == 4)
						boyfriend.playAnim((bfInvertIdleDirection ? 'danceRight' : 'danceLeft') + boyfriend.idleSuffix, true);
					else if (curStep % 8 == 0)
						boyfriend.playAnim((bfInvertIdleDirection ? 'danceLeft' : 'danceRight') + boyfriend.idleSuffix, true);
				}
				else
				{
					if (curStep % bfIdleSpeedInt == bfIdleInt)
						boyfriend.playAnim((bfInvertIdleDirection ? 'danceRight' : 'danceLeft') + boyfriend.idleSuffix, true);
					else if (curStep % bfIdleSpeedInt == 0)
						boyfriend.playAnim((bfInvertIdleDirection ? 'danceLeft' : 'danceRight') + boyfriend.idleSuffix, true);
				}
			}
			else
			{
				if (curStep % (bfIdleisHalfBeat ? 2 : bfIdleInt) == 0)
					boyfriend.playAnim('idle' + boyfriend.idleSuffix, true);
			}
		}
		if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned && !dad.specialAnim && !dad.danceAfterAnim)
		{
			if (dad.danceIdle)
			{
				if (dad.curCharacter.startsWith('gf') && !dadIdleSpeedChanged)
				{
					if (curStep % 8 == 0)
						dad.playAnim((dadInvertIdleDirection ? 'danceRight' : 'danceLeft') + dad.idleSuffix, true);
					else if (curStep % 8 == 4)
						dad.playAnim((dadInvertIdleDirection ? 'danceLeft' : 'danceRight') + dad.idleSuffix, true);
				}
				else
				{
					if (curStep % dadIdleSpeedInt == 0)
						dad.playAnim((dadInvertIdleDirection ? 'danceRight' : 'danceLeft') + dad.idleSuffix, true);
					else if (curStep % dadIdleSpeedInt == dadIdleInt)
						dad.playAnim((dadInvertIdleDirection ? 'danceLeft' : 'danceRight') + dad.idleSuffix, true);
				}
			}
			else
			{
				if (curStep % (dadIdleisHalfBeat ? 2 : dadIdleInt) == 0)
					dad.playAnim('idle' + dad.idleSuffix, true);
			}
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	public function recalculateIdleInt(bpm:Float):Int
	{
		var base:Int = 100;
		var power:Int = 1;
	
		while (base * power < bpm)
			power *= 2;
	
		return power * 4;
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		switch (curStage)
		{
			case "Stage-Drk":
				if (ara != null)
					ara.dance(true);

				if (dono != null)
					dono.dance(true);
		}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	override function sectionHit()
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				recalculateIdleInt(Conductor.bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('altAnimBF', SONG.notes[curSection].altAnimBF);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}

	#if LUA_ALLOWED
	public function startLuasOnFolder(luaFile:String)
	{
		for (script in luaArray)
		{
			if(script.scriptName == luaFile) return false;
		}

		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(luaToLoad))
		{
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		else
		{
			luaToLoad = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
				return true;
			}
		}
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		{
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		#end
		return false;
	}
	#end

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			var myValue = script.call(event, args);
			if(myValue == FunkinLua.Function_StopLua && !ignoreStops)
				break;
			
			if(myValue != null && myValue != FunkinLua.Function_Continue) {
				returnVal = myValue;
			}
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (script in luaArray)
			script.set(variable, arg);
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
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);
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
			if (sicks > 0) ratingFC = "PFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				
				/*if (achievementName.contains(WeekData.getWeekFileName()) && achievementName.endsWith('nomiss')) // any FC achievements, name should be "weekFileName_nomiss", e.g: "weekd_nomiss"; --Wtf, this is a reference to drkfon week?!?!?!?1?
				{
					if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'Harder'
						&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						unlock = true;
				}*/
				switch(achievementName)
				{
					case 'zweek_beat':
						if(WeekData.getWeekFileName().toLowerCase() == 'weekz' && isStoryMode && storyPlaylist.length <= 1 && !usedPractice && !chartingMode) {
							unlock = true;
						}
					case 'bb_fucked':
						if(songName == 'bad-battle' && !usedPractice && storyDifficulty==2 && !chartingMode) {
							unlock = true;
						}
					case 'bb_ara':
						if(Paths.formatToSongPath(SONG.song) == 'bad-battle-ara' && !usedPractice) {
							unlock = true;
						}
					case 'dweek_beat':
						if(songName == 'override' && !usedPractice && !chartingMode) {
							unlock = true;
						}
					case 'gopico_yeah':
						if(songName == 'bad-battle-pico' && !usedPractice && !chartingMode) {
							unlock = true;
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode && !chartingMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice && !chartingMode) {
							unlock = true;
						}
					case 'taunt_master':
						if(!usedPractice && tauntCounter >= 100 && songMisses < 10 && !chartingMode) {
							unlock = true;
						}
					case 'friendship_v2':
						if(Paths.formatToSongPath(SONG.song) == 'friendship-v2' && !usedPractice && !chartingMode) {
							unlock = true;
						}
					case 'toastie':
						if(ClientPrefs.framerate <= 60 && !ClientPrefs.shaders && ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !chartingMode) {
							unlock = true;
						}
					/*case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}*/
				}

				if(unlock) {
					Achievements.unlock(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end
}
//hey buddy, a lot of the code used for this mod comes from the QT mod, so we give a special thanks to Hazard and NightShade who were the original creators of the QT mod from which we took some lines of code. -zRamírez
