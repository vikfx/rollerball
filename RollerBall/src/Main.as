/** Main
 *  jeu : rollerBall
 *  amener la boule jusqu'a la sortie sans tomber
 *  version away 3D : 4.1.0
 *  @version : 1.0
 *  @author : VikFx
 **/ 

package 
{
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.lights.DirectionalLight;
	import away3d.lights.LightBase;
	import away3d.lights.PointLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.materials.MaterialBase;
	import jiglib.physics.RigidBody;
	import jiglib.plugin.away3d4.Away3D4Physics;
	import vikfx.ControlCharacter;
	import vikfx.PopUp;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Vector3D;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	
	import vikfx.ControlCamera;
	import vikfx.Debugger;
	import vikfx.Plateau3D;
	
	
	[Frame(factoryClass="Preloader")]
	public class Main extends Sprite 
	{
		
		//flashvars	:Object											//variables transmises par le swfObject
		// =>configxml 
		
		///// DEBUGGER
		private var _debug :Debugger							//debugger
		
		///// SCENE3D
		private var _view3D :View3D;							//view3D
		private var _scene3D :Scene3D;							//scene3D
		private var _ctrlCam :ControlCamera;					//controller de camera
		private var _ligths :Array; 							//liste des lampes
		private var _ltPkr :StaticLightPicker;					//picker des lumieres
		
		///// POST_EFFECTS
		//shadows
		
		///// PHYSIC
		private var _physics :Away3D4Physics;					//moteur de physique
		private var _groundH :Number;							//le niveau du sol que le character ne doit pas franchir
		private var _gravity :Number;							//gravité de la scene
		private var _force :Number;								//unité de force
		
		///// MATERIALS
		private var _materials :Vector.<MaterialBase>;			//liste de tous les materials
		
		///// OBJECTS3D
		private var _object3Ds :Vector.<ObjectContainer3D>;		//liste des objets 3D
		private var _plateau :Plateau3D;						//plateau
		private var _character :ControlCharacter;				//character
		private var _ground :RigidBody;							//sol
		//skyBox		//skybox
		
		
		///// OBJECTS2D
		//interface		//interface
		//menu			//menu
		private var _popup :PopUp;								//popup
		
		///// GAME
		private var _levelID :int;								//id du level en cours
		private var _charID :int;								//id du character
		private var _inGame :Boolean;							//si le jeu est lancé
		//score			//score du perso
		private var _chReady :Boolean;							//character prêt
		private var _lvlReady : Boolean;						//level prêt
		
		///// DATA
		private var _config :XML								//XML des configs
		private var _levels :XML								//XML des levels
		
		public function Main():void 
		{
			if (stage) preInit();
			else addEventListener(Event.ADDED_TO_STAGE, preInit);
		}
		
		//ajouter au stage
		private function preInit(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, preInit);
			
			//init du jeu
			//initConfig('xml/config.xml');
			var configxml:String = root.loaderInfo.parameters.configxml;
			initConfig(configxml);
		}
		///////////////////////////////////////////// DEBUG ////////////////////////////////////////////////////
		//initialiser le debugger
		private function initDebugger() :void {
			_debug = new Debugger();
		}
		
		
		///////////////////////////////////////////// INIT ////////////////////////////////////////////////////
		///// DATAS
		// config
		private function initConfig(xmlPath :String) :void {
			var loader :URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, loadConfig);
			loader.load(new URLRequest(xmlPath));
		}
		
		//levels
		private function initLevelsConfig(xmlPath :String) :void {
			var loader :URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, loadLevelsConfig);
			loader.load(new URLRequest(xmlPath));
		}
		
		//lancer les inits dans l'ordre
		private function initEnvmt() :void {
			//debug
			initDebugger();
			
			//scene
			initScene();
			
			//physics
			initPhysics();
			
			//materials
			initMaterials();
			
			//objects3D
			initObjects3D();
			
			//objects2D
			initObjects2D();
			
			//events
			initEvents();
			
			//ajouter le trident à la scene 3D et le debug au main
			_debug.addTrident(_scene3D);
			addChild(_debug);
			
			//lancer le level
			_levelID = -1;
			_charID = -1;
			
			//loadGame(0, 0);
		}
		
		///// SCENE 3D
		private function initScene() :void {
			
			//creer la scene
			_scene3D = new Scene3D();
			
			//creer la camera
			_ctrlCam = new ControlCamera(stage);
			_scene3D.addChild(_ctrlCam);
			
			//creer un nouveau type de cam
			var cType :Object = { };
			cType.rotSpeed = 400;
			cType.zSpeed = 3000;
			cType.brake = 0.2;
			cType.perfectSphe = new Vector3D(120, 28, 49); 
			cType.zLimits = { min : 100, max : 400 };
			
			_ctrlCam.addCamType('proche', cType, true);
			
			//replacer la cam
			_ctrlCam.cSphe = cType.perfectSphe;
			
			//ajouter les valeurs de la cam au debugger
			_debug.addMsg("CamSpheX");
			_debug.addMsg("CamSpheY");
			_debug.addMsg("CamSpheR");
			_debug.addMsg("RotSpeed");
			
			//creer la view
			_view3D = new View3D(_scene3D, _ctrlCam.camera);
			_view3D.backgroundColor = 0xDDDDDD;
			_view3D.antiAlias = 4;
			addChild(_view3D);
			
			//creer l'eclairage
			_ligths = new Array();
			var directL :DirectionalLight = new DirectionalLight();
			_ligths.push(directL);
			_scene3D.addChild(directL);
			directL.x = 50;
			directL.y = 300;
			directL.z = -100;
			directL.direction = new Vector3D(1, -1, 1);
			
			_ltPkr = new StaticLightPicker(_ligths);
			
			//creer les effets
		}
		
		/////PHYSICS
		private function initPhysics() :void {
			//initialiser le moteur de physique
			_physics = new Away3D4Physics(_view3D, 10);
			
			//initialiser les constantes de la physique
			_gravity = Number(_config.game.physic.gravity);
			_groundH = Number(_config.game.physic.ground);
			_force = Number(_config.game.physic.force);
			
			_physics.engine.setGravity(new Vector3D(0, -_gravity, 0));
		}
		
		///// MATERIALS
		private function initMaterials() :void {
			//creer la liste de tous les materials
			_materials = new Vector.<MaterialBase>();
			
			//creer les materials de l'environnement
			
			
			//creer les materials du plateau
			
			
			//creer les materials du character
		}
		
		///// OBJETS 3D
		private function initObjects3D() :void {
			//creer la liste de tous les objets 3D
			_object3Ds = new Vector.<ObjectContainer3D>;
			
			//creer l'environnement
			
			//creer le character
			_character = new ControlCharacter(_physics, XML(_config.game.character), _force);
			//_scene3D.addChild(_character);
			_character.addEventListener("CHARACTER_COMPLETE", chComplete);
			
			//creer la base du plateau
			_plateau = new Plateau3D(_physics, _levels, _config.game.plateau.tilesize);
			//_scene3D.addChild(_plateau);
			_plateau.addEventListener("LEVEL_COMPLETE", lvlComplete);
			_plateau.addEventListener("END_GAME_WIN", youWin);
			_plateau.addEventListener("END_GAME_LOOSE", youLoose);
			
			//creer le sol
			//_ground = _physics.createGround(null, 2000, 2000);
			//_physics.addBody(_ground);
		}
		
		///// OBJETS 2D
		private function initObjects2D() :void {
			//creer les menus
			
			//creer l'interface in game
			
			//creer la popup
			_popup = new PopUp(XML(_config.popup));
			_popup.x = stage.stageWidth / 2;
			_popup.y = stage.stageHeight / 2;
			
			_popup.addEventListener("NEXT", goToNextLvl);
			_popup.addEventListener("PREVIOUS", goToPrevLvl);
			_popup.addEventListener("RELOAD", reloadLvl);
			
			_popup.applyMsg("Déplacez vous avec les flèches. Arrivez jusqu'à la case bleu. \n Cliquez sur recharger pour commencer");
			
			stage.addChild(_popup);
		}
		
		///// EVENTS
		private function initEvents() :void {
			trace('init events');
			//initialiser les events update
			addEventListener(Event.ENTER_FRAME, update);
			
			//initialiser les events characters
			_character.initEvents(stage);
			
			//autres evenements clavier
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
			
			//initialiser les events souris
		}
		
		
		///////////////////////////////////////////// ACTIONS ////////////////////////////////////////////////
		//rentrer dans le jeu
		private function launchGame() :void {
			_inGame = true;
			
			//defreezer le character
			_character.freeze = false;
			
			//placer le character à sa position de départ
			var pos :Object = _plateau.findTriggers('start')[0];
			var chpos :Vector3D = _character.placeOnPlateau(_plateau, pos.col, pos.line);
			_character.startPos = chpos;
			
			trace("play the game! lvl :" + _levelID + ", char :" + _charID);
		}
		
		//charger le jeu
		private function loadGame(lvl :int = -1, char :int = -1) :void {
			_inGame = false;
			
			//limiter lvl dans la limite des levels
			if (lvl >= _levels.level.length())
				lvl = _levels.level.length() - 1;
			
			//limiter char dans la limiter des characters	
			if (char >= _config.game.character.chtype.length())
				char = _config.game.character.chtype.length() - 1;
				
			//reinitialiser les valeurs des objets chargés
			if (lvl > -1 && lvl != _levelID) {
				_lvlReady = false;
			}
			
			
			if (char > -1 && char != _charID) {
				_chReady = false;
			}
			
			//recharger les éléments
			if (lvl > -1 && lvl != _levelID) {
				loadLevel(lvl);
			}
			
			if (char > -1 && char != _charID) {
				loadCharacter(char);
			}
			
			
			//si les elements sont déjà chargés
			if ((lvl <= -1 || lvl == _levelID) && (char <= -1 || char == _charID)) {
				if (_levelID < 0 || _charID < 0)
					loadGame(0, 0);
				else
					launchGame();
			}
			
		}
		
		//charger un character
		private function loadCharacter(chId :int) :void {
			_charID = chId;
			
			_character.loadCharacter(chId);
		}
		
		//charger un level
		private function loadLevel(lvlId :int) :void {
			_levelID = lvlId;
			
			_plateau.loadLevel(lvlId);
		}
		
		
		//////////////////////////////////////////// EVENTS HANDLERS /////////////////////////////////////////
		///// UPDATE
		private function update(evt : Event) :void {
			//update du debugger
			_debug.modifyMsg("CAMSPHE X:" + _ctrlCam.cSphe.y, 0);
			_debug.modifyMsg("CAMSPHE Y:" + _ctrlCam.cSphe.z, 1);
			_debug.modifyMsg("CAMSPHE R:" + _ctrlCam.cSphe.x, 2);
			_debug.modifyMsg(_ctrlCam.msg, 3);
			
			_debug.updateMsg();
			
			//update de la cam
			_ctrlCam.updateCam();
			
			//update du character
			_character.update();
			
			//update du plateau
			_plateau.update();
			
			//update du moteur de physique
			_physics.step();
			
			//update du rendu
			_view3D.render();
		}
		
		
		///// XML
		//loader le xml des configs
		private function loadConfig(evt :Event) :void {
			_config = new XML(evt.target.data);
			
			initLevelsConfig(_config.game.plateau.levels);
		}
		
		//loader le xml des levels
		private function loadLevelsConfig(evt :Event) :void {
			_levels = new XML(evt.target.data);
			
			initEnvmt();
		}
		
		
		///// LEVEL
		//level chargé
		private function lvlComplete(evt :Event) :void {
			trace("level complete");
			
			//ajouter l'eclairage sur les materials
			for each(var material :MaterialBase in _plateau.currentLvlMaterials) {
				material.lightPicker = _ltPkr;
			}
			
			//definir le plateau comme prêt
			_lvlReady = true;
			
			//lancer le jeu
			if (_lvlReady && _chReady && !_inGame) {
				_plateau.character = _character.rigidbody;
				launchGame();
			}
		}
		
		///// CHARACTER
		//character chargé
		private function chComplete(evt :Event) :void {
			trace("character complete");
			
			//ajouter l'eclairage sur le material
			_character.material.lightPicker = _ltPkr;
			
			//definir le character comme prêt
			_chReady = true;
			
			//cible de la cam
			_ctrlCam.target = _character.mesh;
			_ctrlCam.follow = true;
			_ctrlCam.movable = true;
			
			//definir le system
			_character.system = _ctrlCam;
			
			//lancer le jeu
			if (_lvlReady && _chReady && !_inGame) {
				_plateau.character = _character.rigidbody;
				launchGame();
			}
			
			
		}
		
		///// EVENTS CLAVIER
		//keydown
		private function keyDownHandler(evt : KeyboardEvent) :void {
			var key :uint = evt.keyCode;
			
			switch(key) {
				default :
					break;
			}
		}
		
		//keyup
		private function keyUpHandler(evt : KeyboardEvent) :void {
			var key :uint = evt.keyCode;
			
			switch(key) {
				case Keyboard.NUMPAD_0 :
					_character.restore();
					break;
				default :
					break;
			}
		}
		
		//autres interactions clavier
		
		
		///// EVENTS SOURIS
		//events menu
		
		//events interface
		
		//events game
		//gagné
		private function youWin(evt :Event) :void {
			//afficher la popup et son message
			_popup.applyMsg("win");
			_popup.show();
			
			//sortir du jeu
			_inGame = false;
			
			//freezer le character
			_character.freeze = true;
		}
		
		//perdu
		private function youLoose(evt :Event) :void {
			if (_inGame) {
				//afficher la popup et son message
				_popup.applyMsg("loose");
				_popup.show();
				
				//sortir du jeu
				_inGame = false;
				
				//replacer le character et freezer le character
				_character.restore();
				_character.freeze = true;
			}
		}
		
		//events popup
		//charger le level suivant
		private function goToNextLvl(evt :Event) :void {
			var lvl :int = _levelID + 1;
			
			loadGame(lvl);
			
			_popup.hide();
		}
		
		//charger le level précédent
		private function goToPrevLvl(evt :Event) :void {
			var lvl :int = _levelID - 1;
			
			loadGame(lvl);
			
			_popup.hide();
		}
		
		//recharger le level en cours
		private function reloadLvl(evt :Event) :void {
			loadGame();
			
			_popup.hide();
		}
	}

}