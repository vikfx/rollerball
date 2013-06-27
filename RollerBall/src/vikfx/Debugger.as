/** Debugger
 *  package : vikfx
 *  version away 3D : 4.1.0
 *  @version : 1.0
 *  @author : VikFx
 **/ 

package vikfx 
{
	import away3d.containers.Scene3D;
	import away3d.debug.Trident;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	
	public class Debugger extends Sprite
	{
		private var _area :TextField;				//zone de texte
		private var _trident :Trident;				//trident
		private var _messages :Array;				//liste des messages à afficher
		
		private const _TXTCOLOR :uint = 0x000000;	//couleur du texte
		
		
		public function Debugger() 
		{
			initMsg();
			initArea();
		}
		
		///////////////////////////////////////////// INIT ////////////////////////////////////////////////////
		//initialiser l'environnement du debugger
		private function initArea() :void {
			_area = new TextField();
			_area.width = 450;
			_area.textColor = _TXTCOLOR;
			addChild(_area);
		}
		
		//creer le tableau des messages du debugger
		private function initMsg() :void {
			_messages = new Array();
		}
		
		///////////////////////////////////////////// ACTIONS /////////////////////////////////////////////////
		//ajouter un nouveau message str à la liste, renvoi l'index du message
		public function addMsg(str :String) :int {
			_messages.push(str);
			
			return _messages.length - 1;
		}
		
		//modifier un message à l'index ix
		public function modifyMsg(str :String, ix :int) :void {
			if(ix < _messages.length) _messages[ix] = str;
		}
		
		//effacer le message à l'index ix
		public function clearMsg(ix :int) :void {
			if(ix < _messages.length) _messages[ix] = String;
		}
		
		//effacer tous les messages
		public function clearAll() :void {
			_messages = [];
		}
		
		//ajouter le trident à la scene scene
		public function addTrident(scene :Scene3D) :void {
			if (_trident == null) {
				_trident = new Trident(100, false);
				scene.addChild(_trident);
			}
		}
		
		///////////////////////////////////////////// EVENTS HANDLERS /////////////////////////////////////////
		//update du debugger
		public function updateMsg(evt :Event = null) :void {
			_area.text = "";
			
			for each(var msg :String in _messages) {
				_area.appendText(msg + '\n');
			}
		}
	}

}