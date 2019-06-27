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

  public class EndLevel extends MovieClip {
    // The function we need to call when we've finished all our pretty
    // animating.
    public var on_finish_animation;

    // Various pieces the game class needs to set up
    public var bonus_value:     Number;
    public var lead_value:      Number;
    public var old_score_value: Number;
    public var level_name:      String;
    public var stats:           Stats;

    // Internal variables for storing animation state
    private var _timer: Timer;
    private var _score_counter: Number;
    private var _frame_num: int;
    private var _score_increment: Number;

    // Constructor - just set up the attach event so we can hide what we need
    // to when we're attached.
    public function EndLevel() {
      addEventListener(Event.ADDED_TO_STAGE, prepare_for_animation);
      addEventListener(Event.REMOVED_FROM_STAGE, removed_from_stage);
      _frame_num = 0;
    }

    // Gets hit on the ADDED_TO_STAGE event and preps the objects for animation
    // Namely, the score labels all get hidden.
    private function prepare_for_animation(e) {
      level_text.visible      = false;
      lead.visible            = false;
      bonus.visible           = false;
      final_score.visible     = false;
      close_button.visible    = false;
      dt_best_word.visible    = false;
      dt_longest_word.visible = false;

      _frame_num = 0;
      addEventListener(Event.ENTER_FRAME, on_enter_frame);
    }

    private function removed_from_stage(e) {
      removeEventListener(Event.ENTER_FRAME, on_enter_frame);
    }

    // This is no longer needed, but it doesn't hurt to keep the skeleton for future use
    private function on_enter_frame(e:Event) {
    }

    // Begins the process of animating, yay!
    public function begin_score_animations() {
      // Build up all score objects/text to reflect initial values
      _score_counter          = 0;
      lead.visible            = true;
      bonus.visible           = true;
      final_score.visible     = true;
      level_text.visible      = true;
      dt_best_word.visible    = true;
      dt_longest_word.visible = true;

      // Comma-fy all numbers!
      final_score.text      = NumberHelper.comma_format(old_score_value);
      lead.text             = lead_value.toString() + " m";
      level_text.text       = "You've completed:\n\"" + level_name + "\"!";
      dt_best_word.text     = stats.highest_scoring_word + ' (' + NumberHelper.comma_format(stats.highest_scoring_word_value) + ')';
      dt_longest_word.text  = stats.longest_word;

      // Set up base values for the bonus modifier
      bonus.alpha = 0;
      bonus.text = '0';
      bonus.visible = true;

      _score_increment = bonus_value / 40.0;

      // Set up new timer
      _timer = new Timer(50, 0);
      _timer.addEventListener(TimerEvent.TIMER, timer_fade_in_bonus);
      _timer.start();
    }

    // Next animation just fades in bonus, then moves on to
    // counting up the final score for the level
    private function timer_fade_in_bonus(e) {
      bonus.alpha += 0.05;

      if (bonus.alpha >= 1) {
        // end the timer
        _timer.stop();

        // set up the counter for final score and bonus
        _score_counter = 0;

        // next animation
        _timer = new Timer(50, 0);
        _timer.addEventListener(TimerEvent.TIMER, timer_update_final);
        _timer.start();
      }
    }

    // Update final score, then go to wait_for_user.  We're done, baby!
    private function timer_update_final(e) {
      // Again, comma-fy the scores!
      _score_counter = _score_counter + _score_increment;
      final_score.text = NumberHelper.comma_format(Math.ceil(old_score_value + _score_counter));
      bonus.text = NumberHelper.comma_format(Math.ceil(_score_counter));

      // If we've reached our goal, we're done
      if (_score_counter >= bonus_value) {
        final_score.text = NumberHelper.comma_format(old_score_value + bonus_value);
        bonus.text = NumberHelper.comma_format(bonus_value);
        wait_for_user();
      }
    }

    // Final step in the animation - we wait for the user to click "Close"
    private function wait_for_user() {
      close_button.visible = true;
      close_button.addEventListener(MouseEvent.CLICK, clean_up);
    }

    // Stop our timer and run the final event, on_finish_animation, set up by
    // the caller of begin_score_animations.
    private function clean_up(e) {
      close_button.removeEventListener(MouseEvent.CLICK, clean_up);
      _timer.stop();
      _timer = null;
      on_finish_animation();
    }
  }
}
