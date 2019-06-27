package run_nerd {
  import flash.display.SimpleButton;
  import flash.text.*;
  import flash.display.MovieClip;
  import flash.events.Event;
  import flash.utils.Timer;
  import flash.events.TimerEvent;
  import flash.events.MouseEvent;

  import generic_code.NumberHelper;
  import run_nerd.Stats;

  public class EndGame extends MovieClip {
    // Font data that all letters will need to use
    private static var letter_format:TextFormat = new TextFormat();
    letter_format.color = 0x000000;
    letter_format.size  = 18;
    letter_format.font  = "Icicle Country 2";
    letter_format.align = "left";

    public var on_close;                // Run this when user clicks the close button
    private var _stage;
    private var _initialized:Boolean;

    // Various pieces the game class needs to set up
    public var stats:Stats;
    public var level_name:String;

    // Display objects
    private var tf_level_text:TextField;
    private var tf_best_word:TextField;
    private var tf_longest_word:TextField;
    private var tf_distance_run:TextField;
    private var tf_final_score:TextField;
    private var tf_words_submitted:TextField;
    private var tf_tiles_used:TextField;
    private var _close_button:CloseButton;

    public function set stage(s) {_stage = s;}

    public function EndGame() {
      _initialized = false;
    }

    public function init() {
      if (null == stats || null == _stage || null == on_close || null == level_name) {
        trace("ERROR!  Missing a required value: stats, stage, on_close, or level_name");
        return;
      }

      if (_initialized) {
        return;
      }

      _initialized = true;
      alpha = 0;

      // Create text fields
      tf_level_text           = make_text_field(165);
      tf_level_text.multiline = true;
      tf_level_text.wordWrap  = true;
      tf_level_text.textColor = 0x006600;
      tf_level_text.width     = 292;
      tf_level_text.height    = 25;
      tf_level_text.text      = "You got to " + level_name + " before the bully finally beat you within an inch of your life!";
      tf_level_text.x         = 140;
      tf_level_text.height    = 100;

      var ypos = 261;
      tf_best_word            = make_text_field(ypos);
      tf_best_word.text       = stats.highest_scoring_word + ' (' +
                                NumberHelper.comma_format(stats.highest_scoring_word_value) + ')';

      ypos += 25;
      tf_longest_word         = make_text_field(ypos);
      tf_longest_word.text    = stats.longest_word;

      ypos += 25;
      tf_distance_run         = make_text_field(ypos);
      tf_distance_run.text    = NumberHelper.comma_format(stats.distance_run) + " meters";

      ypos += 25;
      tf_words_submitted      = make_text_field(ypos);
      tf_words_submitted.text = NumberHelper.comma_format(stats.words_submitted);

      ypos += 25;
      tf_tiles_used           = make_text_field(ypos);
      tf_tiles_used.text      = NumberHelper.comma_format(stats.tiles_used);

      tf_final_score          = make_text_field(398);
      tf_final_score.text     = NumberHelper.comma_format(stats.high_score);

      // Create close button
      _close_button = new CloseButton();
      _close_button.x = 393;
      _close_button.y = 456;
      this.addChild(_close_button);
    }

    // Start the fade-in process
    public function fade_in() {
      init();
      _stage.addChild(this);
      removeEventListener(Event.ENTER_FRAME, fade_out_frame);
      addEventListener(Event.ENTER_FRAME, fade_in_frame);
    }

    private function make_text_field(y_pos:int) {
      var tf = new TextField();
      tf.width = 200;
      tf.height = 25;
      tf.defaultTextFormat = letter_format;
      tf.embedFonts = true;
      tf.x = 233;
      tf.y = y_pos;
      this.addChild(tf);
      return tf;
    }

    // Fade out - set min alpha and listen for frames
    public function fade_out() {
      removeEventListener(Event.ENTER_FRAME, fade_in_frame);
      addEventListener(Event.ENTER_FRAME, fade_out_frame);
    }

    // Animate alpha - stop listening when we're at the appropriate alpha level
    public function fade_in_frame(e:Event) {
      if (1 == alpha) {
        _close_button.addEventListener(MouseEvent.CLICK, on_close_clicked);
        removeEventListener(Event.ENTER_FRAME, fade_in_frame);
        return;
      }

      alpha = Math.min(1, alpha + 0.075);
    }

    public function fade_out_frame(e:Event) {
      if (0 == alpha) {
        removeEventListener(Event.ENTER_FRAME, fade_out_frame);
        _stage.removeChild(this);
        on_close();
        return;
      }

      alpha = Math.max(0, alpha - 0.075);
    }

    // Remove listener and start the fade animation
    private function on_close_clicked(e) {
      _close_button.removeEventListener(MouseEvent.CLICK, on_close_clicked);
      fade_out();
    }
  }
}

