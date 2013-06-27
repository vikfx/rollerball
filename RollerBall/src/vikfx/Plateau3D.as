/** Plateau
 *  creer un plateau de jeu
 *  package : vikfx
 *  version away 3D : 4.1.0
 *  @version : 2.0
 *  @author : VikFx
 **/ 

package vikfx 
{
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.entities.Mesh;
	import away3d.materials.ColorMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.CubeGeometry;
	
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.xml.XMLNode;
	
	import jiglib.physics.RigidBody;
	import jiglib.plugin.away3d4.Away3D4Mesh;
	import jiglib.plugin.away3d4.Away3D4Physics;
	
	
	
	
	public class Plateau3D extends ObjectContainer3D
	{
		
		private var _tileSize :Number;						//taille de la tile de reference
		private var _physics :Away3D4Physics;				//moteur de physique
		
		private var _materials :Array;						//liste de tous les materials déjà créés
		private var _geometriesRef :Vector.<Geometry>;		//geometries de reference de la tile et des triggers
		
		private var _lvlsXml :XML;							//XML de tous les levels
		private var _numOfLevels :uint;						//nombre de levels
		
		private var _cLvlID	:uint;							//id du level en cours
		private var _cLvlNode :XML;							//noeud XML du level en cours
		
		private var _cLvlLines :int;						//nombre de lignes du level en cours
		private var _cLvlCols :int;							//nombre de colonnes du level en cours
		private var _cLvlFloorH	:Number;					//hauteur de chaque etage du level en cours
		private var _cLvlMaxFloorBridge :int;				//nombre d'etages max pour creer un pont du level en cours
		
		private var _cLvlGFloor :Array;						//grille des etages du level en cours
		private var _cLvlGTriggers :Array;					//grille des triggers du level en cours
		
		private var _cLvlStart :Vector3D;					//tile de depart du level en cours
		private var _cLvlEnd :Vector3D;						//tile d'arrivée du level en cours
		
		private var _cLvlTriggers :Array;					//liste des triggers (autres que '0')du level en cours => {rigidbody, pos{col, line}, name, action} (pour une boucle plus rapide)
		private var _cLvlMeshes :Array;						//liste des tiles du level en cours = mesh
		private var _cLvlRbodies :Array;					//liste des rigidBody du level en cours
		private var _cLvlMaterials :Array;					//materials du level en cours
		
		private var _character :RigidBody;					//rigidBody de l'acteur
		private var _currentTriggerCollision :RigidBody;	//trigger en contact avec le character
		
		public function Plateau3D(physics :Away3D4Physics, levelsXML :XML, tileSize :Number = 20, geometries :Array = null) 
		{
			
			_physics = physics;
			_lvlsXml = levelsXML;
			_tileSize = tileSize;
			
			//definir le nombre de levels
			_numOfLevels = _lvlsXml.level.length()
			
			//initialiser l'environnement
			initEnvmt();
			
			//initialiser les géometries
			initGeometries(geometries);
		}
		
		///////////////////////////////////////////// INIT ////////////////////////////////////////////////////
		//initialiser l'environnement du plateau
		private function initEnvmt() :void {
		}
		
		//creer les references
		private function initGeometries(geom :Array) :void {
			var tileG :Geometry;	//geometry de la tile
			
			//initialiser le tableau des geometries
			_geometriesRef = new Vector.<Geometry>();
			
			//creer la tile de base
			tileG = new CubeGeometry(_tileSize, _tileSize / 10, _tileSize);
			_geometriesRef.push(tileG);
			
			//loader les geometries des triggers
			if (geom != null) {
				
			}
		}
		
		//creer les triggers de base
		private function initTriggers(trig :Array) :void {
			
		}
		
		///////////////////////////////////////////// ACTIONS /////////////////////////////////////////////////
		///// CHARGEMENT DU LEVEL
		//charger un level
		public function loadLevel(lvlId :uint) :void {
			if (lvlId < _numOfLevels) {
				//id du level
				_cLvlID = lvlId;
				
				//noeud du level
				_cLvlNode = _lvlsXml.level[lvlId];
				
				//grille des etages
				_cLvlGFloor = parseGrid(_cLvlNode.gfloors);
				
				//grille des triggers
				_cLvlGTriggers = parseGrid(_cLvlNode.gtriggers);
				
				//dimmensions du level
				_cLvlLines = _cLvlGFloor.length;
				_cLvlCols = _cLvlGFloor[0].length;
				
				_cLvlFloorH = _cLvlNode.floorh;
				_cLvlMaxFloorBridge = _cLvlNode.maxfloorbridge;
				
				//charger les materials
				loadMaterials();
				
				//creer les elements du plateau
				loadTiles();
				
				//lancer l'evenement
				dispatchEvent(new Event("LEVEL_COMPLETE"));
			} else {
				trace('error loadind lvl-' + lvlId);
			}
			
		}
		
		//creer une grille depuis un noeud XML
		private function parseGrid(elem :XMLList) :Array {
			var grid :Array;		//grille
			var cols :Array;		//colonnes sous forme de tableau
			
			grid = new Array();
			
			for each(var line :XML in elem.l) {
				cols = new Array();
				//trace('line :' + line);
				for each(var col :XML in line.c) {
					//trace('col :' + col);
					cols.push(col);
				}
				grid.push(cols);
			}
			//trace('grid :' + grid);
			return grid;
		}
		
		//charger les materials du level en cours
		private function loadMaterials() :void {
			//creer la liste de tous les materials
			if (_materials == null) {
				_materials = new Array(_numOfLevels);
			}
			
			//creer les materials du level
			if (_materials[_cLvlID] == null) {
				_cLvlMaterials = new Array();;
				
				for each(var material :XML in _cLvlNode.materials.mat) {
					var cm :ColorMaterial = new ColorMaterial(Number(material));
					_cLvlMaterials.push(cm);
				}
				
				//ajouter les materials à la liste des materials déjà créés
				_materials[_cLvlID] = _cLvlMaterials;
			}
		}
		
		//creer les tiles du level en cours
		private function loadTiles() :void {
			var fval :int;			//etage
			var tval :String;		//nom du trigger
			var mesh :Mesh;			//tile
			var rigid :RigidBody; 	//rigidBody
			var trig : Object;		//trigger
			var geomat :Object		//geometrie et material
			
			//effacer l'ancien plateau
			erase();
			
			//reinitialiser la liste des tiles
			_cLvlMeshes = new Array();
			
			//reinitialiser la liste des rigidbodies
			_cLvlRbodies = new Array();
			
			//reinitialiser la liste des triggers
			_cLvlTriggers = new Array();
			
			//creer les tiles
			for (var l :int = 0; l < _cLvlLines; l++) {
				for (var c :int = 0; c < _cLvlCols; c++ ) {
					fval = _cLvlGFloor[l][c];
					tval = _cLvlGTriggers[l][c];
					
					//si l'etage est à 0 
					if (fval != 0) {
						
						//tile = loadTrigger(tval);
						geomat = loadGeomAndMaterial(tval);
						
						//ajouter le rigidbody
						rigid = addRigid(c, l, geomat.material);
						_cLvlRbodies.push(rigid);
						
						//charger le mesh
						mesh = Away3D4Mesh(rigid.skin).mesh;
						
						//ajouter la tile à la liste
						_cLvlMeshes.push(mesh);
						
						//ajouter le trigger à la liste
						if (tval != '0') {
							trig = addTriggerAt(c, l);
							if(trig.action != null)
								_cLvlTriggers.push(trig);
						}
						
					} else {
						_cLvlMeshes.push(null);
						_cLvlRbodies.push(null);
					}
				}
			}
		}
		
		//ajouter une geometrie et un material de type trig
		private function loadGeomAndMaterial(trig :String = '0') :Object {
			var geometry :Geometry;				//geometry
			var material :MaterialBase;			//material
			
			switch(trig) {
				case 'start' :
					geometry = _geometriesRef[0];
					material = _cLvlMaterials[1];
					break;
				case 'end' :
					geometry = _geometriesRef[0];
					material = _cLvlMaterials[2];
					break;
				default :
					geometry = _geometriesRef[0];
					material = _cLvlMaterials[0];
					break;
			}
			
			//return new Mesh(geometry, material);
			return { geometry : geometry, material : material };
		}
		
		//calcul trigo pour transformTile
		private function trigonomize(href :int, hsister :int) :Object {
			var tfm :Object = { };
			tfm.delta = href - hsister;
			tfm.angleARAD = Math.atan((_cLvlFloorH * tfm.delta) / _tileSize);
			tfm.angleBRAD =  Math.PI / 2 - tfm.angleARAD;
			
			tfm.angle = tfm.angleARAD / Math.PI * 180;
			tfm.scale = (1 + 0.015 / Math.tan(tfm.angleARAD)) / Math.cos(tfm.angleARAD);
			tfm.offset = (_tileSize / 2) * Math.tan(tfm.angleARAD);
			
			//trace('trigo :arad' + tfm.angleARAD + ', brad :' + tfm.angleBRAD + ', a :' + tfm.angle + ', s :' + tfm.scale + ', o :' + tfm.offset);
			
			return tfm;
		}
		
		//creer le rigidbody de la tile
		private function addRigid(col :int, line :int, material :MaterialBase) :RigidBody {
			var angle :Number;			//angle
			var sisters :Object;		//tiles voisines
			//var delta :Number;			
			var transform :Object;		//valeurs de transformation
			var trigo :Object;			//trigonometrie
			var rigid :RigidBody;		//rigidbody a creer
			
			//definir les tiles à proximité
			sisters = getSisters(col, line);
			
			//trace("tile at :" + col + ", " + line);
			
			transform = { };
			
			//orientation de la tile
			switch (true) {
				//LEFT
				case sisters.reference - sisters.left <=  _cLvlMaxFloorBridge && sisters.left != 0 && sisters.reference > sisters.left :
					trigo = trigonomize(sisters.reference, sisters.left);
					transform.rX = 0;
					transform.rZ = trigo.angle;
					transform.w = trigo.scale;
					transform.d = 1;
					transform.h = trigo.offset;
					//trace("LEFT");
					break;
				//RIGHT
				case sisters.reference - sisters.right <=  _cLvlMaxFloorBridge && sisters.right != 0 && sisters.reference > sisters.right :
					trigo = trigonomize(sisters.reference, sisters.right);
					transform.rX = 0;
					transform.rZ = - trigo.angle;
					transform.w = trigo.scale;
					transform.d = 1;
					transform.h = trigo.offset;
					//trace("RIGHT");
					break;
				//FRONT
				case sisters.reference - sisters.front <=  _cLvlMaxFloorBridge && sisters.front != 0 && sisters.reference > sisters.front :
					trigo = trigonomize(sisters.reference, sisters.front);
					transform.rX = trigo.angle;
					transform.rZ = 0;
					transform.w = 1;
					transform.d = trigo.scale;
					transform.h = trigo.offset;
					//trace("TOP");
					break;
				//BACK
				case sisters.reference - sisters.back <=  _cLvlMaxFloorBridge && sisters.back != 0 && sisters.reference > sisters.back :
					trigo = trigonomize(sisters.reference, sisters.back);
					transform.rX = - trigo.angle;
					transform.rZ = 0;
					transform.w = 1;
					transform.d = trigo.scale;
					transform.h = trigo.offset;
					//trace("BOTTOM");
					break;
				default :
					transform.rX = 0;
					transform.rZ = 0;
					transform.w = 1;
					transform.d = 1;
					transform.h = 0;
					//trace("DEFAULT");
					break;
			}
			
			//creer le rigidbody
			rigid = _physics.createCube(material, _tileSize * transform.w, _tileSize / 10, _tileSize * transform.d);
			rigid.movable = false;
			
			//ajouter le rigid body au moteur
			_physics.addBody(rigid);
			
			//position
			rigid.x = col * _tileSize;
			rigid.y = _cLvlFloorH * (sisters.reference) - transform.h;
			rigid.z = line * _tileSize;
			
			//rotation
			rigid.rotationX = transform.rX;
			rigid.rotationZ = transform.rZ;
			
			return rigid;
		}
		
		//ajouter un trigger à une position dans la grille
		private function addTriggerAt(col :int, line :int) :Object {
			var trig :RigidBody;			//rigidbody
			var tile :RigidBody;			//rigidbody de la tile associée
			var pos : Object;				//position {col, line}
			var name :String;				//nom dans le tableau
			var action :Function;			//action quand l'acteur entre en collision avec le rigidbody
			//var material :TextureMaterial;	//material transparent
			
			name = _cLvlGTriggers[line][col];
			pos = { col : col, line : line };
			tile = getRigidAt(col, line);
			
			//ajouter l'action
			switch(name) {
				case 'start' :
					action = null;
					break;
				case 'end' :
					action = dispatchWin;
					break;
				default :
					action = null;
					break;
			}
			
			//ajouter le trigger
			if (action != null) {
				trig = _physics.createCube(null, _tileSize / 5, _tileSize / 10, _tileSize / 5);
				trig.movable = false;
				_physics.addBody(trig);
				trig.x = tile.x;
				trig.y = tile.y + 1;
				trig.z = tile.z;
			}
			
			//return new Mesh(geometry, material);
			return { rigidbody : trig, pos : pos, name : name, action :action };
		}
		
		//effacer le plateau
		private function erase() :void {
			var mesh :Mesh;			//mesh
			var rigid :RigidBody;	//rigidbody
			var trigger :Object;	//trigger
			
			
			//effacer les meshes
			for each(mesh in _cLvlMeshes) {
				if (mesh != null)
					mesh.parent.removeChild(mesh);
			}
			
			//effacer les rigidbodys
			for each(rigid in _cLvlRbodies) {
				if(rigid != null)
					_physics.removeBody(rigid);
			}
			
			//effacer les triggers
			for each(trigger in _cLvlTriggers) {
				rigid = trigger.rigidbody;
				mesh = Away3D4Mesh(rigid.skin).mesh;
				mesh.parent.removeChild(mesh);
				_physics.removeBody(rigid);
			}
			
			
			//effacer les tableaux
			_cLvlMeshes = null;
			_cLvlRbodies = null;
			_cLvlTriggers = null;
		}
		
		
		////////// ACTIONS //////////
		//tester les collision avec les triggers
		private function testCollision() :void {
			var rigid :RigidBody;		//rigidbody du trigger testé
			var action :Function;		//action du trigger testé
			var curTrig :RigidBody;		//trigger en collision
			
			//definir le collider en collision
			for each(var trigger :Object in _cLvlTriggers) {
				rigid = trigger.rigidbody as RigidBody;
				action = trigger.action as Function;
				
				if (rigid.hitTestObject3D(_character)) {
					curTrig = rigid;
					break;
				} else {
					curTrig = null;
				}
			}
			
			//tester si la collision a bien lieu et si c'est la première collision
			if (curTrig != null){
				if(curTrig != _currentTriggerCollision) {
					//definir le collider
					_currentTriggerCollision = curTrig;
					
					//lancer l'action si elle existe
					if (action != null) {
						action();
					}
				}
			} else {
				_currentTriggerCollision = curTrig;
			}
		}
		
		//tester l'altitude du character => renvoyer l'evenement END_GAME_LOOSE
		private function testCharacterPos() :void {
			if (_character.y < this.y - 30) {
				dispatchEvent(new Event("END_GAME_LOOSE"));
			}
		}
		
		///// LISTE DES ACTIONS
		//renvoyer un evenement END_GAME_WIN
		private function dispatchWin() :void {
			dispatchEvent(new Event("END_GAME_WIN"));
		}
		
		
		////////// SET / GET //////////
		//renvoyer le mesh à la position col, line
		private function getMeshAt(col :int, line :int) :Mesh {
			if (col >= 0 && col < _cLvlCols && line >= 0 && line < _cLvlLines && _cLvlMeshes != null) {
				var id :int = line * _cLvlCols + col;
				return _cLvlMeshes[id];
			} else {
				return null;
			}
		}
		
		//renvoyer le rigidbody à la position col, line
		private function getRigidAt(col :int, line :int) :RigidBody {
			if (col >= 0 && col < _cLvlCols && line >= 0 && line < _cLvlLines && _cLvlRbodies != null) {
				var id :int = line * _cLvlCols + col;
				return _cLvlRbodies[id];
			} else {
				return null;
			}
		}
		
		//renvoyer l'etage de la tile et de ses voisines
		private function getSisters(col :int, line :int) :Object {
			var obj :Object = { };
			obj.front = getFloorAt(col, line + 1);
			obj.back = getFloorAt(col, line - 1);
			obj.left = getFloorAt(col - 1, line);
			obj.right = getFloorAt(col + 1, line);
			obj.reference = getFloorAt(col, line);
			
			return obj;
		}
		
		//renvoyer l'etage à la position col, line
		private function getFloorAt(col :int, line :int) :int {
			if (col >= 0 && col < _cLvlCols && line >= 0 && line < _cLvlLines) {
				return _cLvlGFloor[line][col];
			} else {
				return NaN;
			}
		}
		
		//renvoyer la liste des tiles
		
		//renvoyer la liste des triggers
		public function get currentLvlTriggers() :Array {
			return _cLvlTriggers;
		}
		
		//renvoyer la liste des triggers de nom trig
		public function findTriggers(trig :String = "") :Array {
			var trig_arr :Array = new Array();
			
			for (var l :int = 0; l < _cLvlLines; l++) {
				for (var c :int = 0; c < _cLvlCols; c++) {
					if (_cLvlGTriggers[l][c] == trig) {
						trig_arr.push( { col : c, line : l } );
					}
				}
			}
			
			return trig_arr;
		}
		
		//renvoyer la grille des etages
		
		//renvoyer la grille des triggers
		
		//renvoyer la position de la tile de depart
		
		//renvoyer la liste des materials (non rangés)
		public function get materials() : Array {
			/*var mat :Array = new Array();
			for each(var lvlMat :Vector.<MaterialBase> in _materials) {
				for each(var material :MaterialBase in lvlMat) {
					mat.push(material);
				}
				
			}
			return mat;*/
			
			return _materials;
		}
		
		//renvoyer la liste des materials du level
		public function get currentLvlMaterials() :Array {
			return _materials[_cLvlID];
		}
		
		//convertir une col/line en position absolue
		public function getTilePos(col :int, line :int) :Vector3D {
			var tile :Mesh = getMeshAt(col, line);	//tile
			return tile.scenePosition;
		}
		
		//retourne la taille de la tile
		public function get tileSize() :Number {
			return _tileSize;
		}
		
		//renvoyer la position absolue de la tile de depart
		public function getStartPos() :Vector3D {
			var pos :Object = findTriggers('start')[0];
			return getTilePos(pos.col, pos.line);
		}
		
		//renvoyer la position absolue de la tile d'arrivée
		public function getEndPos() :Vector3D {
			var pos :Object = findTriggers('end')[0];
			return getTilePos(pos.col, pos.line);
		}
		
		//definir l' acteur
		public function set character(value :RigidBody) :void {
			_character =  value;
		}
		
		//renvoyer l'acteur
		public function get character() :RigidBody {
			return _character;
		}
		
		///////////////////////////////////////////// EVENTS HANDLERS /////////////////////////////////////////
		//update
		public function update(evt :Event = null) :void {
			//tester les collisions de l'acteur
			if (_cLvlTriggers != null && _character != null) {
				testCollision();
				testCharacterPos();
			}
		}
	}

}