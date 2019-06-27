package run_nerd {
  import flash.text.*;
  import flash.display.MovieClip;
  import flash.display.Stage;
  import flash.events.Event;
  import flash.events.MouseEvent;

  // TODO: build an animation to "fly" this in (move down, grow bigger until 75% size, then move up a bit as we hit 100%)
  public class BonusInfo extends MovieClip {
    private static var text_format:TextFormat = new TextFormat();
    text_format.color = 0xFFCC00;
    text_format.size  = 18;
    text_format.font  = "Icicle Country 2";
    text_format.align = "center";

    public var on_animation_complete;
    private var _dtxt_info:TextField;
    private var _close_button:CloseButton;

    // Basic constructor to set everything up nicely
    public function BonusInfo() {
      _dtxt_info = new TextField();
      _dtxt_info.x = 93.5;
      _dtxt_info.y = 190.8;
      _dtxt_info.width = 385;
      _dtxt_info.height = 150;
      _dtxt_info.defaultTextFormat = text_format;
      _dtxt_info.embedFonts = true;
      _dtxt_info.mouseEnabled = false;
      _dtxt_info.wordWrap = true;
      addChild(_dtxt_info);

      _close_button = new CloseButton();
      _close_button.x = 442;
      _close_button.y = 353.8;
      _close_button.addEventListener(MouseEvent.CLICK, clean_up);
      addChild(_close_button);
    }

    public function get bonus_text()            {return _dtxt_info.htmlText;}
    public function set bonus_text(val:String)  {_dtxt_info.htmlText = val;}

    // Just shows the tip/info to the user
    public function begin(stage:Stage) {
      stage.addChild(this);
      this.x = 0;
      this.y = 0;
      _close_button.visible = true;
    }

    public function clean_up(e:Event) {
      _close_button.visible = false;
      this.parent.removeChild(this);
      if (null != on_animation_complete) { on_animation_complete(); }
    }
  }
}
