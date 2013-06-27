/** ControlCamera
 *  sert à manipuler la camera autour d'une cible
 *  package : vikfx
 *  version away 3D : 4.1.0
 *  @version : 2.1
 *  @author : VikFx
 **/ 

 
 
package vikfx 
{
	import away3d.cameras.Camera3D;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Object3D;
	import flash.display.Stage;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	
	public class ControlCamera extends ObjectContainer3D
	{
		
		private var _camera :Camera3D;				//camera
		private var _stg : Stage;					//stage
		
		private var _cSphe :Vector3D;				//coordonnées spherique de la cam sous forme rayon, angleX, angleY en degrés
		
		private var _oldX :Number; 					//position sourisX au depart du mouvement
		private var _oldY :Number; 					//position sourisY au depart du mouvement
		private var _newX :Number; 					//position sourisX actuel mouvement
		private var _newY :Number; 					//position sourisY actuel mouvement
		private var _mouseDown :Boolean;			//clic gauche est enfoncé
		//private var _ctrlKeyDown :Boolean;			//touche de controle de la cam enfoncé
		
		private var _cCamType :Object;				//type de cam en cours
		//private var _onMove :Boolean;				//controlCamera en mouvement
		private var _target :ObjectContainer3D;		//cible de la camera
		
		private var _incRotX :Number;				//incrementation de la rotation X par frame
		private var _incRotY :Number;				//incrementation de la rotation Y par frame
		private var _incZoom :Number;				//incrementtation du zoom par frame
		//private var _incMov :Number;					//incrementation du deplacement
		
		
		//OPTIONS
		private var _zoom :Boolean;					//autoriser le zoom
		private var _movable :Boolean;				//autoriser le deplacement et la rotation du controller
		private var _follow :Boolean;				//se deplacer automatiquement avec la cible
		//private var _yfollow :Boolean;				//tourner en même temps que la cible
		private var _smooth :Boolean;				//deplacement smoothés de la cam
		private var _lockTarget :Boolean;			//regarder la cible automatiquement
		private var _manual :Boolean;				//autoriser le controle manuel de la cam
		private var _zLimits :Object;				//zoom min et max
		private var _rLimits :Object;				//limites de rotation verticale du controller
		private var _rotSpeed :Number;				//vitesse de defilement maximum
		//private var _mSpeed :Number;					//vitesse de deplacement maximum
		private var _zSpeed :Number;				//vitesse de zoom maximum
		private var _perfectSphe :Vector3D;			//orientation et zoom idéal du controller par rapport à la cible en coordonnées polaires
		private var _perfectPos :Vector3D;			//positionnement ideal du controller par rapport à la cible en position ralative
		private var _focus :Vector3D;				//point de focus en relatif
		private var _brake :Number;					//puissance de freinage
		
		//private var _ctrlKey :String;					//touche clavier pour controler la camera
		private var _cameraTypesList :Array;		//liste des type de camera
		
		private const _SENSIBILITY :Number = 100;	//sensibilité de la cam
		
		
		public var msg :String;/////////DEBUG
		
		public function ControlCamera(stg :Stage) {
			_stg = stg;
			
			initCam();
			initParams();
			initEvents();
		}
		
		///////////////////////////////////////////// INIT ////////////////////////////////////////////////////
		//creer l'environnement de la cam
		private function initCam() :void {
			//creer la camera
			_camera = new Camera3D();
			addChild(_camera);
			
			//positionner la camera dans le controller
			_camera.position = new Vector3D(0, 0, -1000);
			_camera.lookAt(new Vector3D());
			
			_cSphe = new Vector3D(1000, 0, 0);
		}
		
		//init les params
		private function initParams() :void {
			var cType :Object;	//object de formatage de camtype
			
			//creer la liste des types de cam
			_cameraTypesList = new Array();
			
			//creer un type de camera standard
			cType = { };
			cType.name = 'standard';
			cType.manual = true;
			cType.rotSpeed = 500;
			cType.smooth = true;
			cType.perfectSphe =  _cSphe.clone();
			cType.perfectPos = new Vector3D();
			cType.focus = new Vector3D();
			cType.rLimits = { min : 0, max : 90 };
			cType.movable = true;
			cType.zoom = true;
			cType.zSpeed = 5000;
			cType.zLimits = { min : 250, max : 3000 };
			cType.lockTarget = true;
			cType.brake = 0.05;
			
			_cameraTypesList.push(cType);
			setCamType('standard');
			
			//initialiser la position de la souris
			_oldX = 0;
			_oldY = 0;
			
			_incRotX = 0;
			_incRotY = 0;
			_incZoom = 0; 
		}
		
		//init Events
		private function initEvents(value :Boolean = true) :void {
			if (value) {
				_stg.addEventListener(MouseEvent.MOUSE_DOWN, startMove);
				_stg.addEventListener(MouseEvent.MOUSE_UP, stopMove);
				_stg.addEventListener(MouseEvent.MOUSE_WHEEL, startZoom);
			} else {
				_stg.removeEventListener(MouseEvent.MOUSE_DOWN, startMove);
				_stg.removeEventListener(MouseEvent.MOUSE_UP, stopMove);
				_stg.removeEventListener(MouseEvent.MOUSE_WHEEL, startZoom);
			}
		}
		
		///////////////////////////////////////////// ACTIONS /////////////////////////////////////////////////
		///// TRANSFORM
		//zoomer sur le pivot
		public function zoomTo(r :Number) :void {
			_camera.z = -r;
			_cSphe.x = r;
		}
		
		//zoomer manuellement
		private function manualZoom() :void {
			var nZ :Number;	//nouveau zoom
			
			if (_manual && _zoom) {
				//incrementation
				if (Math.abs(_incZoom) >= _brake * 30 && _smooth) _incZoom -= (_incZoom / Math.abs(_incZoom)) * _brake * 50;
				else _incZoom = 0;
				
				//zoom
				nZ = _cSphe.x + _incZoom;
				
				if (nZ < _zLimits.min) nZ = _zLimits.min;
				if (nZ > _zLimits.max) nZ = _zLimits.max;
				
				//appliquer la rotation
				if (_incZoom != 0 && _movable) {
					zoomTo(nZ);
				}
			}
		}
		
		//orienter autour du pivot
		public function rotTo(rx :Number, ry :Number) :void {
			//redefinir dans les limites -360, 360°
			rx = rx % 360;
			ry = ry % 360;
			
			if (_movable) {
				//limiter la rotationX
				if (rx < _rLimits.min) rx = _rLimits.min;		
				if (rx > _rLimits.max) rx = _rLimits.max;
				
				//appliquer les transformations
				rotateTo(rx, ry, 0);
				_cSphe.y = rx
				_cSphe.z = ry;
			}
		}
		
		//tourner autour du pivot manuellement
		private function manualRotate() :void {
			var dx :Number;		//distance oldX/newX
			var dy :Number;		//distance oldY/newY
			var nRX :Number;	//nouvelle rotationX du controller
			var nRY :Number;	//nouvelle rotationY du controller
			
			if (_manual) {
				//distance old / new
				_newX = _stg.mouseX;
				_newY = _stg.mouseY;
				dx = _oldX - _newX;
				dy = _oldY - _newY;
				
				
				//incrementation
				if (_mouseDown) {
					_incRotX = (Math.abs(dy) < _rotSpeed) ? dy / _SENSIBILITY : (_rotSpeed * dy / Math.abs(dy)) / _SENSIBILITY;
					_incRotY = (Math.abs(dx) < _rotSpeed) ? dx / _SENSIBILITY : (_rotSpeed * dx / Math.abs(dx)) / _SENSIBILITY;
				} else {
					if (Math.abs(_incRotX) >= _brake && _smooth) _incRotX -= (_incRotX / Math.abs(_incRotX)) * _brake;
					else _incRotX = 0;
					if (Math.abs(_incRotY) >= _brake && _smooth) _incRotY -= (_incRotY / Math.abs(_incRotY)) * _brake;
					else _incRotY = 0;
				}
				
				//rotation
				nRX = rotationX + _incRotX;
				nRY = rotationY + _incRotY;
				
				//appliquer la rotation
				if (_incRotX != 0 || _incRotY != 0 && _movable) {
					rotTo(nRX, nRY);
				}
			}
			
		}
		
		//se deplacer avec la cible
		private function followTarget() :void {
			if (_follow && _target != null && _movable)
				moveTo(_target.scenePosition.x, _target.scenePosition.y, _target.scenePosition.z);
		}
		
		//tourner avec la cible
		private function yawWithTarget() :void {
			
		}
		
		//regarder la position en globale
		private function focusOn(dest :Vector3D = null) :void {
			if (dest != null) {
				_focus = dest;
			}
			
			if (_target != null && _lockTarget) {
				_focus = _target.scenePosition;
			}
			
			if (_focus != null) {
				_focus = globalToLocal(_focus);
				
				_camera.lookAt(_focus);
			} else {
				_focus = new Vector3D();
			}
		}
		
		//faire un travelling de la camera
		public function travelTo(pos :Vector3D = null, sphe :Vector3D = null, anim :Boolean = true) :void {
			if (_movable) {
				if (anim) {
					
				}else {
					//position
					moveTo(pos.x, pos.y, pos.z);
					
					//zoom
					zoomTo(sphe.x);
					
					//rotation
					rotTo(sphe.y, sphe.z);
				}
			} else {
				trace('movable = false');
			}
		}
		
		//se replacer idealement par rapport à la cible
		public function moveToPerfect(anim :Boolean = false) :void {
			var idPos :Vector3D;
			
			if (_target != null) {
				//definir la position ideale
				idPos = _target.scenePosition.add(_perfectPos);
				
				//se replacer idealement
				travelTo(idPos, _perfectSphe, anim);
			}
		}
		
		//transformation des coordonnées global => local
		private function globalToLocal(globalPos :Vector3D) :Vector3D {
			return inverseSceneTransform.transformVector(globalPos);
		}
		
		
		////////// SET / GET //////////
		///// OPTIONS
		//attribuer une valeur value à une option opt
		public function setOption(opt :String, value :Object) :void {
			
		}
		
		//renvoyer la valeur de l'option opt
		public function getOption(opt :String) :Object {
			return this['_' + opt];
		}
		
		//bloquer/debloquer le controle manuel de la camera
		public function set manual(value :Boolean) :void {
			_manual = value;
			
			initEvents(_manual)
		}
		
		//bloquer/debloquer les deplacement de camera(mais regarde toujours vers la cible)
		public function set movable(value :Boolean) :void {
			_movable = value;
		}
		
		
		///// TARGET
		//changer de cible
		public function set target(obj :ObjectContainer3D) :void {
			var idPos :Vector3D;	//position ideale du controller en absolu
			
			_target = obj;
			
			//se deplacer jusqu'a la position ideale
			if (_follow && _target != null) {
				idPos = _target.scenePosition.add(_perfectPos);
				travelTo(idPos, _perfectSphe);
			}
			
		}
		
		//renvoyer la cible
		public function get target() : ObjectContainer3D{
			return _target;
		}
		
		//definir la position ideale de la cam en coordonnées polaires
		public function set perfectSphe(value :Vector3D) :void {
			_perfectSphe = value;
		}
		
		//bloquer/debloquer le verrouillage de la cible
		public function set lockTarget(value : Boolean) :void {
			_lockTarget = value;
		}
		
		//bloquer/debloquer le deplacement avec la cible
		public function set follow(value : Boolean) :void {
			var idPos :Vector3D;	//position ideale du controller en global
			_follow = value;
			
			//definir la position ideale
			idPos = _target.scenePosition.add(_perfectPos);
			
			//se deplacer jusqu'a la position ideale
			if (_follow && _target != null) travelTo(idPos, _perfectSphe);
		}
		
		//renvoyer le deplacement avec la cible
		public function get follow() :Boolean {
			return _follow;
		}
		
		
		///// CAM TYPE
		//creer un nouveau type de camera avec un nom id et une valeur {options} et appliquer à la cam(.opt)
		public function addCamType(id :String, options :Object, apply :Boolean = false) :void {
			var overwrite :Boolean;		//si la camera de nom id existe déjà
			var stdCam :Object;			//camera par defaut
			
			//ajouter le nom
			options.name = id;
			
			//ajouter les options manquantes
			stdCam = _cameraTypesList[0];
			for (var opt :* in stdCam) {
				if (!options.hasOwnProperty(opt)) options[opt] = stdCam[opt];
			}
			
			//tester si un type de camera porte le meme nom
			for (var i : int = 0; i < _cameraTypesList.length; i++) {
				var obj :Object = _cameraTypesList[i];
				if (obj.name == id) {
					trace ("Nom de cam déjà existant. La camera précedente va etre ecrasée");
					overwrite = true;
					break;
				} else {
					overwrite = false;
				}
			}
			
			//ajouter la camera à la liste
			if (overwrite) {
				_cameraTypesList[i] = options;
			} else {
				_cameraTypesList.push(options);
			}
			
			//affecter le nouveau type de cam
			if (apply) {
				setCamType(id);
			}
		}
		
		//appliquer le type de camera de nom id
		public function setCamType(id :String) :void {
			//recuperer les options du type de cam
			for each(var ctype : Object in _cameraTypesList) {
				if (ctype.name == id) {
					_cCamType = ctype;
					break;
				}
			}
			
			//appliquer les options
			for (var opt :* in _cCamType) {
				if(opt != 'name') this['_' + opt] = _cCamType[opt];
			}
		}
		
		//renvoyer le type de camera
		public function getCamType() :Object {
			return _cCamType;
		}
		
		
		///// CAMERA
		//renvoyer la camera
		public function get camera() :Camera3D {
			return _camera;
		}
		
		//renvoyer la position de la camera en local
		public function get camPosLocal() :Vector3D {
			return _camera.position;
		}
		
		//renvoyer la position de la camera en global
		public function get camPosGlobal() :Vector3D {
			return _camera.scenePosition;
		}
		
		
		///// COORDONNEES POLAIRES 
		//appliquer des nouvelles coordonnées polaires sous la forme r, ax, ay
		public function set cSphe(value :Vector3D) :void {
			//zoom
			zoomTo(value.x);
			
			//rotation
			rotTo(value.y, value.z);
		}
		
		//renvoyer les coordonnées polaires du controller sous la forme r , ax, ay
		public function get cSphe() :Vector3D {
			return _cSphe;
		}
		
		
		///////////////////////////////////////////// EVENTS HANDLERS /////////////////////////////////////////
		//update de la camera
		public function updateCam(evt :Event = null) :void {
			//tourner autour de la cible
			manualRotate();
			
			//zoomer
			manualZoom();
			
			//suivre les deplacements de la cible
			followTarget();
			
			//regarder la cible
			focusOn();
			
			msg = 'position : X :' + Math.round(position.x) + ', Y :' + Math.round(position.y) + ', Z :' + Math.round(position.z) + '\n focus : X :' + Math.round(_focus.x) + ', Y :' + Math.round(_focus.y) + ', Z :' + Math.round(_focus.z);
			
			if (_target != null)
				msg +=  '\n target : X :' + Math.round(_target.position.x) + ', Y :' + Math.round(_target.position.y) + ', Z :' + Math.round(_target.position.z);
			else
				msg += '\n target = ' + _target;
		}
		
		//events souris
		//commencer la rotation
		private function startMove(evt : MouseEvent) :void {
			var stg :Stage = evt.currentTarget as Stage;
			_oldX = stg.mouseX;
			_oldY = stg.mouseY;
			
			_mouseDown = true;
		}
		
		//arreter la rotation
		private function stopMove(evt : MouseEvent) :void {
			_mouseDown = false;
		}
		
		//commencer à zoomer
		private function startZoom(evt : MouseEvent) :void {
			var multiplier :int = - Math.abs(evt.delta) / evt.delta;
			
			_incZoom = multiplier * _zSpeed / _SENSIBILITY;
		}
	}

}