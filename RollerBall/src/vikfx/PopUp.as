package vikfx 
{
	import com.greensock.TweenMax;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	/**
	 * ...
	 * @author ...
	 */
	public class PopUp extends Sprite
	{
		private var _msgTxtFld :TextField;		//champ où afficher le message
		private var _nextBtn :Sprite;			//bouton suivant
		private var _prevBtn :Sprite;			//bouton précédent
		private var _reloadBtn :Sprite;			//bouton recharger
		private var _background :Sprite;		//background de la popup
		private var _tween :TweenMax;			//tween d'apparition/disparition
		private var _config :XML;				//xml de config
		private const _WIDTH :Number = 650;		//largeur de la popup
		private const _HEIGHT :Number = 150;	//hauteur de la popup
		
		public function PopUp(config :XML) 
		{
			_config = config;
			init();
		}
		
		///////////////////////////////////////////// INIT ////////////////////////////////////////////////////
		//init la popup
		private function init() :void {
			var bkgColor :uint;				//couloeur du background
			var txtColor :uint;				//couleur du texte
			var btnColor :uint;				//couleur du fond des boutons
			var nextTxt :TextField;			//champ texte du bouton suivant
			var prevTxt :TextField;			//champ texte du bouton precedent
			var reloadTxt :TextField;		//champ texte du bouton recharger
			var bmBkg :Bitmap;				//bitmap du background
			var bmNext :Bitmap;				//bitmap du bouton suivant
			var bmPrev :Bitmap;				//bitmap du bouton precedent
			var bmReload :Bitmap;			//bitmap du bouton reload
			var bmd :BitmapData;			//bitmapdata pour les bitmaps
			
			//definir les couleurs
			bkgColor = _config.background;
			txtColor = _config.txtcolor;
			btnColor = _config.buttons;
			
			//creer le background
			bmd = new BitmapData(_WIDTH, _HEIGHT, false, bkgColor);
			bmBkg = new Bitmap(bmd);
			
			_background = new Sprite();
			_background.addChild(bmBkg);
			
			//creer le textfield du message
			_msgTxtFld = new TextField();
			_msgTxtFld.width = _WIDTH - 20;
			//_msgTxtFld.wordWrap = true;
			_msgTxtFld.autoSize = 'center';
			_msgTxtFld.selectable = false;
			_msgTxtFld.defaultTextFormat = new TextFormat(null, 25, txtColor);
			
			
			//creer le bitmapdata des boutons
			bmd = new BitmapData(50, 20, false, btnColor);
			
			//suivant
			bmNext = new Bitmap(bmd);
			
			nextTxt = new TextField();
			nextTxt.selectable = false;
			nextTxt.text = 'suivant';
			
			_nextBtn = new Sprite();
			_nextBtn.addChild(bmNext);
			_nextBtn.addChild(nextTxt);
			
			//suivant
			bmPrev = new Bitmap(bmd);
			
			prevTxt = new TextField();
			prevTxt.selectable = false;
			prevTxt.text = 'précédent';
			
			_prevBtn = new Sprite();
			_prevBtn.addChild(bmPrev);
			_prevBtn.addChild(prevTxt);
			
			//suivant
			bmReload = new Bitmap(bmd);
			
			reloadTxt = new TextField();
			reloadTxt.selectable = false;
			reloadTxt.text = 'recharger';
			
			_reloadBtn = new Sprite();
			_reloadBtn.addChild(bmReload);
			_reloadBtn.addChild(reloadTxt);
			
			//ajouter et placer les elements sur la popup
			//background
			_background.x = -_background.width / 2;
			_background.y = -_background.height / 2;
			addChild(_background);
			
			_msgTxtFld.x = _background.width / 2;
			_msgTxtFld.y = 20;
			_background.addChild(_msgTxtFld)
			
			_nextBtn.x = _WIDTH / 2 + 75;
			_nextBtn.y = 100;
			_background.addChild(_nextBtn);
			
			_prevBtn.x = _WIDTH / 2 - 125;
			_prevBtn.y = 100;
			_background.addChild(_prevBtn);
			
			_reloadBtn.x = _WIDTH / 2 - 25;
			_reloadBtn.y = 100;
			_background.addChild(_reloadBtn);
			
			//ajouter l'interactivité des boutons
			_nextBtn.addEventListener(MouseEvent.CLICK, nextAction);
			_prevBtn.addEventListener(MouseEvent.CLICK, prevAction);
			_reloadBtn.addEventListener(MouseEvent.CLICK, reloadAction);
		}
		
		///////////////////////////////////////////// ACTIONS ////////////////////////////////////////////////////
		//afficher la popup
		public function show() :void {
			visible = true;
		}
		
		//masquer la popup
		public function hide() :void {
			visible = false;
		}
		
		//afficher le message
		public function applyMsg(msg :String) :void {
			var message :String;		//texte du message
			
			switch(msg) {
				case 'win' :
					message = _config.messages.win;
					break;
				case 'loose':
					message = _config.messages.loose;
					break;
				default :
					message = msg;
					break;
			}
			
			_msgTxtFld.text = message;
			
		}
		
		///////////////////////////////////////////// EVENTS HANDLERS ////////////////////////////////////////////////////
		//action suivant
		private function nextAction(evt :MouseEvent) :void {
			dispatchEvent(new Event("NEXT"));
		}
		
		//action précédent
		private function prevAction(evt :MouseEvent) :void {
			dispatchEvent(new Event("PREVIOUS"));
		}
		
		//action recharger
		private function reloadAction(evt :MouseEvent) :void {
			dispatchEvent(new Event("RELOAD"));
		}
		
	}

}