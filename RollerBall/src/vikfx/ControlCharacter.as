/** ControlCharacter
 *  creer un character et sa physique
 *  definir les actions du character
 *  package : vikfx
 *  version away 3D : 4.1.0
 *  @version : 2.0
 *  @author : VikFx
 **/ 

package vikfx 
{
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.Object3D;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.SphereGeometry;
	import away3d.textures.BitmapTexture;
	import away3d.textures.Texture2DBase;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	import jiglib.physics.RigidBody;
	import jiglib.plugin.away3d4.Away3D4Mesh;
	import jiglib.plugin.away3d4.Away3D4Physics;
	import away3d.utils.Cast;
	
	
	
	public class ControlCharacter extends ObjectContainer3D
	{
		private var _physics :Away3D4Physics;		//moteur de physique
		
		private var _characterXml :XML;				//xml du character
		private var _numOfCharacter :uint;			//nombre de character
		
		private var _radius :Number;				//rayon du character en cours
		private var _cCharId :uint;					//index du character en cours
		
		public var movable :Boolean;				//le character est déplacable (default = true)
		private var _freeze :Boolean;				//le character est freezé
		
		private var _system :ObjectContainer3D;		//systeme dans lequel les forces doivent s'appliquer
		private var _reference :ObjectContainer3D;	//referentiel du systeme
		private var _forceMultiplier :Number;		//unité de force
		private var _keys :Object;					//touches enfoncées
		private var _onMove :Boolean;				//le character est en mouvement
		private var _maxspeed :Number;				//vitesse max du character
		
		private var _oldPos :Vector3D;				//ancienne position du character
		private var _startPos :Vector3D;			//point de départ
		
		private var _rigidbody :RigidBody;			//rigidBody du character
		private var _materials :Array;				//liste des materials déjà créés
		private var _mesh :Mesh;					//mesh du character
		
		
		public function ControlCharacter(physics :Away3D4Physics, characterXml :XML, force :Number) 
		{
			_physics = physics;
			_characterXml = characterXml;
			_forceMultiplier = force;
			
			movable = true;
			
			//definir le nombre de character
			_numOfCharacter = _characterXml.chtype.length();
			
			initEnvmt();
		}
		
		///////////////////////////////////////////// INIT ////////////////////////////////////////////////////
		//creer l'environnement du character
		private function initEnvmt() :void {
			//init le tableau des keys
			initKeys();
			
			//definir le point de départ par défaut
			_startPos = new Vector3D();
		}
		
		//init les touches claviers
		private function initKeys() :void {
			_keys = new Object();
			_keys = {up :0, down :0, left :0, right :0, jump :0}
		}
		
		//init les evenements
		public function initEvents(stage :Stage) :void {
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		}
		
		///////////////////////////////////////////// ACTIONS /////////////////////////////////////////////////
		//charger un nouveau type de character
		public function loadCharacter(chId :int) :void {
			if (chId < _numOfCharacter) {
				//definir l'index du character
				_cCharId = chId;
				
				//definir la taille
				_radius = Number(_characterXml.chtype[chId].radius);
				
				//definir la vitesse max
				_maxspeed = Number(_characterXml.chtype[chId].maxspeed);
				
				//creer le rigidbody
				if (_rigidbody != null) {
					_mesh.parent.removeChild(_mesh);
					_physics.removeBody(_rigidbody);
				}
				
				_rigidbody = _physics.createSphere(null, _radius / 2);
				_rigidbody.mass = Number(_characterXml.chtype[chId].mass);
				_rigidbody.friction = Number(_characterXml.chtype[chId].friction);
				
				//ajouter le rigidbody au moteur de physique
				_physics.addBody(_rigidbody);
				
				//definir le mesh
				_mesh = Away3D4Mesh(_rigidbody.skin).mesh;
				_oldPos = _mesh.position;
				
				//appliquer le material
				applyMaterial();
				
				//lancer l'evenement
				dispatchEvent(new Event("CHARACTER_COMPLETE"));
			} else {
				trace('error loadind character-' + chId);
			}
			
		}
		
		///// MATERIAL
		//appliquer le material au character
		private function applyMaterial() :void {
			var mat :MaterialBase;	//material a appliquer
			var loader :Loader;	//loader de l'image
			
			//creer la liste des materials
			if (_materials == null)
				_materials = new Array(_numOfCharacter);
			
			if (_materials[_cCharId] != null)
				_mesh.material = _materials[_cCharId] as MaterialBase;
			else {
				loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadMaterial);
				loader.load(new URLRequest(_characterXml.chtype[_cCharId].material));
			}
		}
		
		//charger le material
		private function loadMaterial(evt :Event) :void {
			var loader : Loader;			//loader de l'image
			var bmd : BitmapData;			//bitmapdata
			var material :TextureMaterial;	//material
			
			//recuperer le loader
			loader = LoaderInfo(evt.target).loader;
			
			//creer le bitmapdata
			bmd = new BitmapData(loader.width, loader.height, true, 0xffffff);
			bmd.draw(loader);
			
			//creer le material
			material = new TextureMaterial(Cast.bitmapTexture(bmd));
			
			//ajouter le material à la liste des materials
			_materials[_cCharId] = material;
			
			//appliquer le material
			_mesh.material = _materials[_cCharId] as MaterialBase;
		}
		
		///// POSITION
		//placer le character aux coordonnées x, y, z
		public function place(pos :Vector3D) :void {
			//this.position = pos;
			_rigidbody.moveTo(pos);
		}
		
		//placer le character à la position colonne, ligne du plateau plateau => renvoie la position du character
		public function placeOnPlateau(plateau :Plateau3D, col :uint = 0, line :uint = 0) :Vector3D {
			var pos :Vector3D;	//position du character
			
			//recuperer la position de la tile
			pos = plateau.getTilePos(col, line);
			
			//ajouter le rayon à la position
			pos.y += _radius / 2;
			
			//placer le character
			place(pos);
			
			//renvoyer la position
			return pos;
		}
		
		///// FORCES
		//appliquer une force dans la direction sens sur le character
		private function push() :void {
			var pos :Vector3D;		//position de la force
			var force :Vector3D;	//force à appliquer
			
			//definir la force.
			force = getForce();
			
			//trace('force :' + force);
			//trace('keys', _keys.up , _keys.down, _keys.left, _keys.right);
			
			//definir la position
			pos = _mesh.position.add(new Vector3D(0, _radius / 2, 0));
			
			//appliquer la force
			_rigidbody.addWorldForce(force, pos);
			
			//redefinir l'ancienne position du character
			_oldPos = _mesh.position;
		}
		
		//creer la force
		private function getForce() :Vector3D{
			var currentSpeed :Vector3D;		//vitesse du character
			var force :Vector3D;			//force absolue
			
			//definir la vitesse de deplacement
			currentSpeed = _mesh.position.subtract(_oldPos);
			currentSpeed = systemTransform(currentSpeed);
			
			//initialiser la force
			force = new Vector3D(0, 0, 0);
			
			//definir la force vers l'avant (X)
			if(currentSpeed.x > -_maxspeed) {
				force.x -= _keys.left;
			}
			if(currentSpeed.x < _maxspeed) {
				force.x += _keys.right;
			}
			
			//definir la force vers le haut (Y)
			//force.y = _keys.space * _jump;
			
			//definir la force sur le côté (Z)
			if(currentSpeed.z < _maxspeed) {
				force.z += _keys.up;
			}
			if(currentSpeed.z > -_maxspeed) {
				force.z -= _keys.down;
			}
			
			//demultiplier la force
			force.scaleBy(_forceMultiplier);
			
			//transformer la force dans le system
			force = systemTransform(force);
			
			//renvoyer la force
			return force;
		}
		
		//transformer un vecteur en fonction du system
		private function systemTransform(pos :Vector3D) :Vector3D {
			var transform :Matrix3D;		//matrix de transformation
			
			//creer le referentiel
			if (_reference == null)
				_reference = new ObjectContainer3D();
			
			if(_system.rotationZ < 180) {
				_reference.rotationY = _system.rotationY;
			} else {
				_reference.rotationY = 180 - _system.rotationY;
			}
			_reference.position = _system.position;
			
			//transformer le vecteur
			if (_system != null) {
				transform = _reference.sceneTransform;
				pos = transform.deltaTransformVector(pos);
			}
			
			//renvoyer le vecteur
			return pos;
		}
		
		//annuler les forces sur le character
		
		//replacer le character au point de départ
		public function restore() :void {
			trace('restore character at: '+ _startPos);
			place(_startPos);
		}
		
		//actions speciales du character
		//sauter
		//attaquer
		
		//bloquer/debloquer le deplacement du character
		
		///// SET / GET /////
		//retourne la liste des materilas déjà créés
		public function get materials() :Array {
			return _materials;
		}
		
		//retourne le material du mesh en cours
		public function get material() :MaterialBase {
			return _mesh.material;
		}
		
		//renvoyer le rigidbody du character
		public function get rigidbody() :RigidBody {
			return _rigidbody;
		}
		
		//renvoyer le mesh du character
		public function get mesh() :Mesh {
			return _mesh;
		}
		
		//definir le systeme de reference le mesh = local, null = global, camera = dans le sens de la cam
		public function set system(do3d :ObjectContainer3D) :void {
			_system = do3d;
		}
		
		public function get system() :ObjectContainer3D {
			return _system;
		}
		
		//renvoyer si le character est en mouvement
		public function get onMove() :Boolean {
			return _onMove;
		}
		
		//definir point de départ
		public function set startPos(value :Vector3D) :void {
			_startPos = value;
		}
		
		//renvoyer le point de départ
		public function get startPos() :Vector3D {
			return _startPos;
		}
		
		//freezer le character
		public function set freeze(value :Boolean) :void {
			_freeze = value;
			
			//freezer
			if (value) {
				if(_rigidbody)
					_rigidbody.internalSetImmovable();
			}
			//defreezer
			else {
				if(_rigidbody)
					_rigidbody.internalRestoreImmovable();
			}
		}
		
		//renvoyer le freeze
		public function get freeze() :Boolean {
			return _freeze;
		}
		
		///////////////////////////////////////////// EVENT /////////////////////////////////////////////////
		//update
		public function update(evt :Event = null) :void {
			if (movable && _rigidbody != null && !_freeze)
				push();
			
			if(_rigidbody != null)
				var distance :Number = Vector3D.distance(_oldPos, _mesh.position);
			
			_onMove = (_rigidbody != null && _oldPos != null && distance > .05) ? true : false;
		}
		
		//keybords
		//appui
		private function keyDownHandler(evt :KeyboardEvent) :void {
			var k :uint = evt.keyCode;
			
			switch(k) {
				case Keyboard.UP:
					_keys.up = 1;
					break;
				case Keyboard.DOWN:
					_keys.down = 1;
					break;
				case Keyboard.LEFT:
					_keys.left = 1;
					break;
				case Keyboard.RIGHT:
					_keys.right = 1;
					break;
				case Keyboard.SPACE:
					_keys.space = 1;
					break;
				default :
					break;
			}
		}
		
		//relachement
		private function keyUpHandler(evt :KeyboardEvent) :void {
			var k :uint = evt.keyCode;
			switch(k) {
				case Keyboard.UP:
					_keys.up = 0;
					break;
				case Keyboard.DOWN:
					_keys.down = 0;
					break;
				case Keyboard.LEFT:
					_keys.left = 0;
					break;
				case Keyboard.RIGHT:
					_keys.right = 0;
					break;
				case Keyboard.SPACE:
					_keys.jump = 0;
					break;
				/*case Keyboard.NUMPAD_0:
					restore();
					break;*/
				default :
					break;
			}
		}
	}

}