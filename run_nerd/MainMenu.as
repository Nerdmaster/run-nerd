package run_nerd {
  import flash.display.MovieClip;
  import flash.display.Sprite;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.text.*;
  import flash.filters.BevelFilter;
  import flash.utils.Dictionary;
  import flash.filters.BitmapFilterQuality;
  import run_nerd.MenuButton;

  // Semi-generic menu class, should be somewhat easy to retool
  public class MainMenu extends MovieClip {
    private var _buttons:Array;
    private var _button_events:Dictionary;
    private var _stage;
    private var _button_offset:int;
    private var _fade:Sprite, _frame:Sprite, _background:Sprite;
    private const WIDTH = 572;
    private const HEIGHT = 560;
    private const FRAME_OFFSET = 100;
    private const FRAME_BORDER = 10;
    private const OFFSET_INCREMENT = 40;
    private const BGCOLOR = 0x663300;

    private static var format:TextFormat = new TextFormat();
    format.color = 0xFFFFFF;
    format.size  = 24;
    format.font  = "Icicle Country 2";
    format.align = "left";

    // Basic constructor to set everything up nicely
    public function MainMenu(stage) {
      _stage = stage;
      _buttons = new Array();
      _button_events = new Dictionary();

      // Darken non-menu area
      _fade = new Sprite;
      _fade.graphics.beginFill(0x000000);
      _fade.graphics.drawRect(0, 0, WIDTH, HEIGHT);
      _fade.alpha = 0.60;
      addChild(_fade);

      // Frame it
      var bevel_frame:BevelFilter = new BevelFilter();
      bevel_frame.blurX = FRAME_BORDER;
      bevel_frame.blurY = FRAME_BORDER;
      bevel_frame.quality = BitmapFilterQuality.HIGH;

      var off:int = FRAME_OFFSET;
      var off2:int = off * 2;
      _frame = new Sprite;
      _frame.graphics.lineStyle();
      _frame.graphics.beginFill(BGCOLOR);
      _frame.graphics.drawRoundRect(off, off, WIDTH - off2, HEIGHT - off2, 10);
      _frame.filters = new Array(bevel_frame);
      addChild(_frame);

      // Add the actual background - 10 pixels in
      var bevel_back:BevelFilter = new BevelFilter();
      bevel_back.blurX = FRAME_BORDER;
      bevel_back.blurY = FRAME_BORDER;
      bevel_back.quality = BitmapFilterQuality.HIGH;
      bevel_back.angle = 225;

      off = FRAME_OFFSET + FRAME_BORDER;
      off2 = off * 2;
      _background = new Sprite;
      _background.graphics.lineStyle();
      _background.graphics.beginFill(BGCOLOR);
      _background.graphics.drawRect(off, off, WIDTH - off2, HEIGHT - off2);
      _background.filters = new Array(bevel_back);
      addChild(_background);

      _button_offset = 50;

      alpha = 0;
    }

    // Fade in - set max alpha and listen for frames
    public function fade_in() {
      _stage.addChild(this);
      _buttons.forEach(function(b) {
        b.enabled = true;
        b.addEventListener(MouseEvent.CLICK, _button_events[b]);
      });
      removeEventListener(Event.ENTER_FRAME, fade_out_frame);
      addEventListener(Event.ENTER_FRAME, fade_in_frame);
    }

    // Fade out - set min alpha and listen for frames
    public function fade_out() {
      _buttons.forEach(function(b) {
        b.enabled = false;
        b.removeEventListener(MouseEvent.CLICK, _button_events[b]);
      });
      removeEventListener(Event.ENTER_FRAME, fade_in_frame);
      addEventListener(Event.ENTER_FRAME, fade_out_frame);
    }

    // Animate alpha - stop listening when we're at the appropriate alpha level
    public function fade_in_frame(e:Event) {
      if (1 == alpha) {
        removeEventListener(Event.ENTER_FRAME, fade_in_frame);
        return;
      }

      alpha = Math.min(1, alpha + 0.075);
    }

    public function fade_out_frame(e:Event) {
      if (0 == alpha) {
        removeEventListener(Event.ENTER_FRAME, fade_out_frame);
        _stage.removeChild(this);
        return;
      }

      alpha = Math.max(0, alpha - 0.075);
    }

    // Add a button as a child of this with the given text
    public function add_button(txt:String, func) {
      var btn_text = new TextField();
      btn_text.width = width;
      btn_text.defaultTextFormat = format;
      btn_text.embedFonts = true;
      btn_text.mouseEnabled = false;
      btn_text.x = 70 + FRAME_OFFSET;
      btn_text.y = _button_offset + FRAME_OFFSET;
      btn_text.text = txt
      addChild(btn_text);

      var btn = new MenuButton();
      btn.x = 20 + FRAME_OFFSET;
      btn.y = _button_offset + FRAME_OFFSET;
      _buttons.push(btn);
      _button_events[btn] = func;
      addChild(btn);

      _button_offset += OFFSET_INCREMENT;
    }
  }
}
